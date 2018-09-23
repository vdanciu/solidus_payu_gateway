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

    def actions
      %w(capture void credit)
    end

    def capture(_amount_in_cents, transaction_id, _gateway_options = {})
      Rails.logger.info("capture in PaymentMethod with #{_amount_in_cents}, #{transaction_id}, #{_gateway_options}")
      response(
        true,
        Spree.t("payu.successful_action", action: "capture", id: transaction_id)
      )
    end

    def void(transaction_id, _gateway_options = {})
      response(
        false,
        Spree.t("payu.unsuccessful_action", action: "void", id: transaction_id)
      )
    end

    def credit(_amount_in_cents, transaction_id, _gateway_options = {})
      response(
        false,
        Spree.t("payu.unsuccessful_action", action: "credit", id: transaction_id)
      )
    end

    def redirect_url(_payment)
      "/payu/gateway"
    end

    private

    def response(success, message)
      ActiveMerchant::Billing::Response.new(success, message, {}, {})
    end
  end
end
