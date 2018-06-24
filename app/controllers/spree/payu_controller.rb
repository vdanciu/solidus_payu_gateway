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
      order_id = params[:id]
      redirect_to spree.order_path(current_order)
    end

    def notify
      puts "notify handler"
      puts "user agent: #{request.user_agent}"
      head :ok
    end
  end
end
