module Spree
  module PaymentDecorator
    def redirect_url
      payment_method.redirect_url(self)
    end
  end
end

Spree::Payment.include Spree::PaymentDecorator
