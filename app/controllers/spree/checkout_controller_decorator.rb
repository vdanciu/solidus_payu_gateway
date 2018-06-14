module SolidusPayuGateway
  module CheckoutControllerDecorator
    def update
      if update_order

        assign_temp_address
        return if follow_payment_redirect

        unless transition_forward
          redirect_on_failure
          return
        end

        if @order.completed?
          finalize_order
        else
          send_to_next_state
        end

      else
        render :edit
      end
    end

    private

    def follow_payment_redirect
      return unless params[:state] == "confirm"

      payment = @order.payments.valid.last
      if payment.try(:redirect_url)
        redirect_to payment.redirect_url
        true
      end
    end
  end
end

Spree::CheckoutController.prepend SolidusPayuGateway::CheckoutControllerDecorator
