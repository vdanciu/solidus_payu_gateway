module Spree
  module PaymentMethodDecorator
    def redirect_url(_payment)
      nil
    end
  end
end

Spree::PaymentMethod.include Spree::PaymentMethodDecorator
