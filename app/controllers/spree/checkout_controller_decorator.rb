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

    def transition_forward
      if @order.can_complete?
        @order.complete unless payment_redirect_required?
        false
      else
        @order.next
      end
    end


    def send_to_next_state
      if @order.state == "confirm"
        if payment_redirect_required?
          redirect_to get_order_payment.redirect_url
          true
        end
      else
        super
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


    def payment_redirect_required?
      get_order_payment.tap { |payment| return payment.try(:redirect_url)}
    end

    def get_order_payment
      @order.payments.valid.last
    end

  end
end

Spree::CheckoutController.prepend SolidusPayuGateway::CheckoutControllerDecorator
