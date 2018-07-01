require 'json'
require 'solidus_payu_gateway/payu_ro_client'

module Spree
  class PayuController < Spree::StoreController
    skip_before_action :verify_authenticity_token, only: :notify, raise: false

    def gateway
      payu_client = SolidusPayuGateway::PayuRoClient.new(order_payment current_order)
      @payu_order_form = payu_client.payu_order_form
    end

    def continue
      if params[:id] != current_order.number
        raise StandardError, "redirected to wrong order"
      end
      payment = order_payment current_order
      payu_client = SolidusPayuGateway::PayuRoClient.new(payment)
      if payu_client.back_request_legit?(request, params[:ctrl])
        complete_order(payment)
        flash['order_completed'] = true
        redirect_to spree.order_path(current_order)
      else
        head :bad_request
      end
    end

    def notify
      order_id = params['REFNOEXT']
      raise StandardError, "no REFNOEXT received" if !order_id
      order = Spree::Order.find_by!(number: order_id)
      payment = order_payment order

      status = params['ORDERSTATUS']

      payment.update_attributes!(
        response_code: params['REFNO'],
        amount: params['IPN_TOTALGENERAL']
      )
      payu_client = SolidusPayuGateway::PayuRoClient.new(payment)
      payu_client.capture

      puts "notify handler"
      puts "user agent: #{request.user_agent} params=#{params}"
      head :ok
    end

    private

    def order_payment(order)
      order.payments.valid.last
    end

    def complete_order(payment)
      # payment.complete!
      current_order.complete! if current_order.can_complete?
    end
  end
end
