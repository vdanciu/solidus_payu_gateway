require 'json'
require 'solidus_payu_gateway/payu_ro_client'

module Spree
  class PayuController < Spree::StoreController
    skip_before_action :verify_authenticity_token, only: :notify, raise: false

    def gateway
      payu_client = SolidusPayuGateway::PayuRoClient.new(current_order.payments.valid.last)
      @payu_order_form = payu_client.payu_order_form
    end

    def continue
      if params[:id] != current_order.number
        raise StandardError, "redirected to wrong order"
      end
      payment = current_order.payments.valid.last
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
      puts "notify handler"
      puts "user agent: #{request.user_agent}"
      head :ok
    end

    private

    def complete_order(payment)
      payment.complete!
      current_order.complete! if current_order.can_complete?
    end
  end
end
