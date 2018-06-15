require 'json'
require 'solidus_payu_gateway/payu_client'

module Spree
  class PayuController < Spree::StoreController
    skip_before_action :verify_authenticity_token, only: :notify, raise: false
    protect_from_forgery except: [:notify, :continue]

    def gateway
      payu_client = SolidusPayuGateway::PayuClient.new(current_order.payments.valid.last)
      redirect_to payu_client.redirect_url
    end

    def notify
      puts "notify handler"
      puts "user agent: #{request.user_agent}"
    end
  end
end
