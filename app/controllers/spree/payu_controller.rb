require 'json'
require 'solidus_payu_gateway/payu_ro_client'

module Spree
  class PayuController < Spree::StoreController
    skip_before_action :verify_authenticity_token, only: [:notify, :continue], raise: false

    def gateway
      log_order_essentials
      payu_client = SolidusPayuGateway::PayuRoClient.new(order_payment(current_order), request)
      @payu_order_form = payu_client.payu_order_form
    end

    def continue
      log_order_essentials
      if params[:id] != current_order.number
        raise StandardError, "redirected to wrong order"
      end
      payment = order_payment current_order
      payu_client = SolidusPayuGateway::PayuRoClient.new(payment, request)
      if payu_client.back_request_legit?(request, params[:ctrl])
        complete_order
        flash['order_completed'] = true
        redirect_to spree.order_path(current_order)
      else
        Rails.logger.error("Back request not legit #{params[:ctrl]}")
        head :bad_request
      end
    end

    def notify
      order_id = params['REFNOEXT']
      Rails.logger.info("PayU called notify for #{order_id}")
      raise StandardError, "no REFNOEXT received" unless order_id
      payment = order_payment Spree::Order.find_by!(number: order_id)
      payu_client = SolidusPayuGateway::PayuRoClient.new(payment, request)
      original_params = params.except(:action, :controller)
      raise StandardError, "invalid hash on #{original_params}" unless payu_client.notify_request_legit?(original_params)

      # status = params['ORDERSTATUS']
      payment.update!(
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

    def log_order_essentials
      log_info("currency: #{current_pricing_options.currency}")
      log_info("guest_token: #{cookies.signed[:guest_token]}")
      log_info("store_id: #{current_store.id}")
      log_info("user_id: #{try_spree_current_user.try(:id)}")
    end

    def log_info(text)
      Rails.logger.info("\t-<>-\e[34m#{text}\e[0m")
    end
  end
end
