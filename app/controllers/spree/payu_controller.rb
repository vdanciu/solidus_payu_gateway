require 'json'
require 'solidus_payu_gateway/payu_ro_client'

module Spree
  class PayuController < Spree::StoreController
    skip_before_action :verify_authenticity_token, only: :notify, raise: false

    def gateway
      payu_client = SolidusPayuGateway::PayuRoClient.new(order_payment(current_order))
      @payu_order_form = payu_client.payu_order_form
    end

    def continue
      if params[:id] != current_order.number
        raise StandardError, "redirected to wrong order"
      end
      payment = order_payment current_order
      payu_client = SolidusPayuGateway::PayuRoClient.new(payment)
      if payu_client.back_request_legit?(request, params[:ctrl])
        complete_order
        flash['order_completed'] = true
        redirect_to spree.order_path(current_order)
      else
        head :bad_request
      end
    end

    def notify
      order_id = params['REFNOEXT']
      Rails.logger.info("PayU called notify for #{order_id}")
      raise StandardError, "no REFNOEXT received" unless order_id
      payment = order_payment Spree::Order.find_by!(number: order_id)
      payu_client = SolidusPayuGateway::PayuRoClient.new(payment)
      original_params = params.except(:action, :controller)
      raise StandardError, "invalid hash on #{original_params}" unless payu_client.notify_request_legit?(original_params)

      # status = params['ORDERSTATUS']
      payment.update_attributes!(
        response_code: params['REFNO'],
        amount: params['IPN_TOTALGENERAL']
      )
      payu_client.capture
      payment.complete! unless payment.completed?

      response_date = payu_client.notify_response_date
      response_hash = payu_client.notify_response_hash(params, response_date)
      response_text = "<EPAYMENT>#{response_date}|#{response_hash}</EPAYMENT>"
      Rails.logger.info("response: #{response_text}")
      render plain: response_text
    end

    private

    def order_payment(order)
      order.payments.valid.last
    end

    def complete_order
      current_order.complete! if current_order.can_complete?
    end
  end
end
