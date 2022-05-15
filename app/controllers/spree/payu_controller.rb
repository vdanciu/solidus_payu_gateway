require 'json'
require 'solidus_payu_gateway/payu_ro_client'

module Spree
  class PayuController < Spree::StoreController
    skip_before_action :verify_authenticity_token, only: [:notify, :continue], raise: false

    def gateway
      log_order_essentials current_order, "gateway"
      payu_client = SolidusPayuGateway::PayuRoClient.new(order_payment(current_order), request)
      @payu_order_form = payu_client.payu_order_form
    end

    def continue
      log_order_essentials params[:id], "continue"
      
      order = Spree::Order.find_by(number: params[:id])
      if order
        payment = order_payment(order)
        payu_client = SolidusPayuGateway::PayuRoClient.new(payment, request)
        if payu_client.test_mode
          # IPN might not have run
          payment.complete! unless payment.completed?
          complete_order payment.order    
        end
        if payu_client.test_mode ||  payu_client.back_request_legit?(request, params[:ctrl])
          confirmation_page = spree.order_path(order)
          log_info(params[:id], "Redirecting to #{confirmation_page}")
          redirect_to confirmation_page
          return
        end
        log_info(order.number, "Back request not legit #{params[:ctrl]}")
      else
        log_info(params[:id], "Order not found for #{params[:id]}")
      end
      log_info(params[:id], "Redirecting to #{spree.root_url}")
      redirect_to spree.root_url
    end

    def notify
      status = params['ORDERSTATUS']
      log_info(params['REFNOEXT'], "notify, ORDERSTATUS: #{status}")
      order_id = params['REFNOEXT']
      raise StandardError, "no REFNOEXT received" unless order_id
      payment = order_payment Spree::Order.find_by!(number: order_id)
      payu_client = SolidusPayuGateway::PayuRoClient.new(payment, request)
      original_params = params.except(:action, :controller)
      unless payu_client.test_mode || payu_client.notify_request_legit?(original_params)
        raise StandardError, "invalid hash on #{original_params}"
      end
  
      if status == "COMPLETE"
        payment.update!(
          response_code: params['REFNO'],
          amount: params['IPN_TOTALGENERAL']
        )
        payu_client.capture
        payment.complete! unless payment.completed?
        complete_order payment.order
      end
      render plain: notify_response(order_id, payu_client)
    end

    private

    def notify_response(order_number, payu_client)
      response_date = payu_client.notify_response_date
      response_hash = payu_client.notify_response_hash(params, response_date)
      response_text = "<EPAYMENT>#{response_date}|#{response_hash}</EPAYMENT>".tap do |text|
        log_info(order_number, "notify response: #{text}")
      end
    end

    def order_payment(order)
      order.payments.valid.last
    end

    def complete_order(order)
      order.complete! if order.can_complete?
    end

    def log_order_essentials(order_number, where)
      log_info(
        order_number, 
        %(log essentials: #{where}
          currency: #{current_pricing_options.currency}
          guest_token: #{cookies.signed[:guest_token]}
          store_id: #{current_store.id}
          user_id: #{try_spree_current_user.try(:id)}
        )
      )
    end

    def log_info(order, text)
      Rails.logger.info("\t-<>- \e[37;41m[PAYU-#{order}] #{text}\e[0m")
    end
  end
end
