require 'json'
require 'solidus_payu_gateway/payu_ro_client'

module Spree
  class PayuController < Spree::StoreController
    skip_before_action :verify_authenticity_token, only: [:notify, :continue], raise: false

    def gateway
      log_order_essentials
      payu_client = SolidusPayuGateway::PayuRoClient.new(order_payment(current_order), request)
      @payu_order_form = payu_client.payu_order_form
    end

    def continue
      log_order_essentials
      
      order = Spree::Order.find_by(number: params[:id])
      if order
        payment = order_payment(order)
        payu_client = SolidusPayuGateway::PayuRoClient.new(payment, request)
        if payu_client.test_mode
          # IPN does might not have run
          payment.complete! unless payment.completed?
          complete_order payment.order    
        end
        if payu_client.test_mode ||  payu_client.back_request_legit?(request, params[:ctrl])
          redirect_to spree.order_path(order)
          return
        end
        Rails.logger.error("Back request not legit #{params[:ctrl]}")
      else
        Rails.logger.error("Order not found for #{params[:id]}")
      end
      redirect_to spree.root_path
    end

    def notify
      order_id = params['REFNOEXT']
      Rails.logger.info("PayU called notify for #{order_id}")
      raise StandardError, "no REFNOEXT received" unless order_id
      payment = order_payment Spree::Order.find_by!(number: order_id)
      payu_client = SolidusPayuGateway::PayuRoClient.new(payment, request)
      original_params = params.except(:action, :controller)
      unless payu_client.test_mode || payu_client.notify_request_legit?(original_params)
        raise StandardError, "invalid hash on #{original_params}"
      end

      status = params['ORDERSTATUS']
      log_info("ORDERSTATUS: #{status}")
      payment.update!(
        response_code: params['REFNO'],
        amount: params['IPN_TOTALGENERAL']
      )
      payu_client.capture
      payment.complete! unless payment.completed?
      complete_order payment.order

      render plain: notify_response(payu_client)
    end

    private

    def notify_response(payu_client)
      response_date = payu_client.notify_response_date
      response_hash = payu_client.notify_response_hash(params, response_date)
      response_text = "<EPAYMENT>#{response_date}|#{response_hash}</EPAYMENT>".tap do |text|
        Rails.logger.info("response: #{text}")
      end
    end

    def order_payment(order)
      order.payments.valid.last
    end

    def complete_order(order)
      order.complete! if order.can_complete?
    end

    def log_order_essentials
      log_info("currency: #{current_pricing_options.currency}")
      log_info("guest_token: #{cookies.signed[:guest_token]}")
      log_info("store_id: #{current_store.id}")
      log_info("user_id: #{try_spree_current_user.try(:id)}")
    end

    def log_info(text)
      Rails.logger.info("\t-<>- \e[37;41m#{text}\e[0m")
    end
  end
end
