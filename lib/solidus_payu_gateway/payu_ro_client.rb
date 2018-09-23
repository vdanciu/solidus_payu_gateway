require 'net/http'
require 'openssl'

module SolidusPayuGateway
  class PayuRoClient
    include Spree::Core::Engine.routes.url_helpers
    IDN_URL = "https://secure.payu.ro/order/idn.php"

    def initialize(payment)
      @payment = payment
    end

    def payu_order_form
      params = add_signature(get_params, order_hash_keys, secret)
      form = to_form_html(params)
      Rails.logger.info(form)
      form
    end

    def back_request_legit?(request, ctrl)
      hash_string = request.original_url.gsub(/(\?ctrl=.*)/, '')
      hash_string = hash_string.length.to_s + hash_string
      computed_ctrl = compute_hmac(secret, hash_string)
      ctrl == computed_ctrl
    end

    def notify_request_legit?(params)
      hash_params_key = 'HASH'
      received_hash = params[hash_params_key]
      hash_string = compute_hash_string(params, params.except(hash_params_key).keys)
      received_hash == compute_hmac(secret, hash_string)
    end

    def notify_response_date
      Time.now.strftime("%Y%m%d%H%M%S")
    end

    def capture
      payload = {
        'MERCHANT' => merchant_id,
        'ORDER_REF' => @payment.response_code,
        'ORDER_AMOUNT' => @payment.amount.to_s,
        'ORDER_CURRENCY' => @payment.currency,
        'IDN_DATE' => Time.now.strftime("%Y-%m-%d %H:%M:%S")
      }
      payload = add_signature(payload, capture_hash_keys, secret)
      Net::HTTP.post_form(URI.parse(IDN_URL), payload)
    end

    private

    def compute_hash_string(params, hash_keys)
      hash_keys.map do |key|
        if params[key].is_a?(Array)
          params[key].map { |item| "#{item.bytesize}#{item}" }.join
        elsif params[key]
          "#{params[key].bytesize}#{params[key]}"
        else
          ''
        end
      end.join
    end

    def compute_hmac(secret, message)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest::MD5.new, secret, message)
    end

    def add_signature(params, hash_keys, secret)
      params['ORDER_HASH'] = compute_hmac(secret, compute_hash_string(params, hash_keys))
      params
    end

    def to_form_html(params)
      '<form action="https://secure.payu.ro/order/lu.php" method="post" name="payu_form">' + "\n" +
        params.reduce('') do |form, (key, value)|
          if value.is_a? Array
            form + value.map { |item| "<input type=\"hidden\" name=\"#{key}\" id=\"h#{key}\" value=\"#{CGI.escapeHTML(item)}\"/>\n" }.join
          else
            value = '' if value.nil?
            form + "<input type=\"hidden\" name=\"#{key}\" id=\"#{key}\" value=\"#{CGI.escapeHTML(value)}\"/>\n"
          end
        end +
        '<input type="submit" value="PAYU LiveUpdate"/></form>' + "\n"
    end

    def order_hash_keys
      [
        'MERCHANT',
        'ORDER_REF',
        'ORDER_DATE',
        'ORDER_PNAME[]',
        'ORDER_PCODE[]',
        'ORDER_PINFO[]',
        'ORDER_PRICE[]',
        'ORDER_QTY[]',
        'ORDER_VAT[]',
        'ORDER_SHIPPING',
        'PRICES_CURRENCY',
        'DISCOUNT',
        'PAY_METHOD',
        'ORDER_PRICE_TYPE[]',
        'TESTORDER'
      ]
    end

    def capture_hash_keys
      [
        'MERCHANT',
        'ORDER_REF',
        'ORDER_AMOUNT',
        'ORDER_CURRENCY',
        'IDN_DATE'
      ]
    end

    def get_params
      order = @payment.order
      bill_address = order.bill_address
      {
        'MERCHANT' => merchant_id,
        'ORDER_REF' => order.number,
        'ORDER_DATE' => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
        'ORDER_PNAME[]' => order.line_items.map { |item| item.product.name },
        'ORDER_PCODE[]' => order.line_items.map { |item| item.product.sku },
        'ORDER_PINFO[]' => order.line_items.map { |item| item.product.name },
        'ORDER_PRICE[]' => order.line_items.map { |item| item.price.to_s },
        'ORDER_QTY[]' => order.line_items.map { |item| item.quantity.to_s },
        'ORDER_VAT[]' => order.line_items.map { |item| line_item_vat_rate(item) },
        'ORDER_PRICE_TYPE[]' => order.line_items.map { 'GROSS' },
        'PRICES_CURRENCY' => order.store.default_currency || 'RON',
        'PAY_METHOD' => 'CCVISAMC',
        'BILL_FNAME' => bill_address.firstname || '',
        'BILL_LNAME' => bill_address.lastname || '',
        'BILL_EMAIL' => order.email,
        'BILL_PHONE' => bill_address.phone,
        'BILL_COUNTRYCODE' => bill_address.country_iso,
        'BILL_COMPANY' => bill_address.company,
        'BILL_FISCALCODE' => '',
        'BILL_REGNUMBER' => '',
        'DISCOUNT' => '0',
        'TESTORDER' => 'TRUE',
        'LANGUAGE' => I18n.locale.to_s.upcase,
        "BACK_REF" => payu_continue_url(host: order.store.url, id: order.number),
        "TIMEOUT_URL" => checkout_url(host: order.store.url)
      }
    end

    def line_item_vat_rate(line_item)
      # returns the percentage vat rate as string (for 19% returns 19)
      tax_adjustments = line_item.adjustments.select { |a| a.tax? && a.source.tax_category.name.start_with?('TVA') }
      if tax_adjustments.empty?
        '0'
      else
        (tax_adjustments[0].source.amount * 100).to_i.to_s
      end
    end

    def merchant_id
      @payment.payment_method.preferences.fetch(:merchant_id)
    end

    def secret
      @payment.payment_method.preferences.fetch(:merchant_secret)
    end
  end
end
