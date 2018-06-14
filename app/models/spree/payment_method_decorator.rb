module SolidusPayuGateway
  module PaymentMethodDecorator
    def redirect_url(_payment)
      nil
    end
  end
end

Spree::PaymentMethod.include SolidusPayuGateway::PaymentMethodDecorator
