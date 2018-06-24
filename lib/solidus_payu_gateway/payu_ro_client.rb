require 'net/http'
require 'openssl'

module SolidusPayuGateway
  class PayuRoClient
    include Spree::Core::Engine.routes.url_helpers

    def initialize(payment)
      @payment = payment
    end

    def payu_order_form
      params = add_signature(get_params, @payment.payment_method.preferences[:merchant_secret])
      to_form_html(params)
    end

    private

    def compute_hash_string(params)
      hash_keys.map do |key|
        if params[key].is_a?(Array)
          params[key].map { |item| "#{item.length}#{item}" }.join
        elsif params[key]
          "#{params[key].length}#{params[key]}"
        else
          ''
        end
      end.join
    end

    def add_signature(params, secret)
      params['ORDER_HASH'] = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::MD5.new, secret, compute_hash_string(params))
      params
    end

    def to_form_html(params)
      '<form action="https://secure.payu.ro/order/lu.php" method="post" name="payu_form">' + "\n" +
        params.reduce('') do |form, (key, value)|
          if value.is_a? Array
            form + value.map { |item| "<input type=\"hidden\" name=\"#{key}\" id=\"#{key}\" value=\"#{item}\"/>\n" }.join
          else
            form + "<input type=\"hidden\" name=\"#{key}\" id=\"#{key}\" value=\"#{value}\"/>\n"
          end
        end +
        '<input type="submit" value="PAYU LiveUpdate"/></form>' + "\n"
    end

    def hash_keys
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

    def get_params
      # TODO: replace VAT hardcoded value with the real one
      payment_method = @payment.payment_method
      order = @payment.order
      bill_address = order.bill_address
      {
        'MERCHANT' => payment_method.preferences[:merchant_id],
        'ORDER_REF' => order.number,
        'ORDER_DATE' => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
        'ORDER_PNAME[]' => order.line_items.map { |item| item.product.name },
        'ORDER_PCODE[]' => order.line_items.map { |item| item.product.sku },
        'ORDER_PINFO[]' => order.line_items.map { |item| item.product.name },
        'ORDER_PRICE[]' => order.line_items.map { |item| item.price.to_s },
        'ORDER_QTY[]' => order.line_items.map { |item| item.quantity.to_s },
        'ORDER_VAT[]' => order.line_items.map { '19' },
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
        "BACK_REF" => payu_continue_url(host: order.store.url, id: order.number)
      }
    end
  end
end
