module Spree
  class PaymentMethod::PayuRo < Spree::PaymentMethod
    preference :merchant_id, :string
    preference :merchant_secret, :string

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
  end
end
