module Spree
  class PaymentMethod::Payu < Spree::PaymentMethod
    preference :pos_id, :string
    preference :client_id, :string
    preference :client_secret, :string

    def payment_source_class
      nil
    end

    def source_required?
      false
    end

    def auto_capture
      false
    end

    def redirect_url(_payment)
      "/payu/gateway"
    end

    def payu_order_url
      if preferred_test_mode
        SolidusPayuGateway::Config.test_order_url
      else
        SolidusPayuGateway::Config.live_order_url
      end
    end

    def payu_auth_url
      if preferred_test_mode
        SolidusPayuGateway::Config.test_auth_url
      else
        SolidusPayuGateway::Config.live_auth_url
      end
    end
  end
end
