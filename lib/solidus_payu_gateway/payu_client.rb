require 'net/http'

module SolidusPayuGateway
  class PayuClient
    include Spree::Core::Engine.routes.url_helpers

    def initialize(payment)
      @payment = payment
    end

    def redirect_url
      payu_redirect_url(payu_credentials)
    end

    private

    def payu_credentials
      # TODO: raise an exception if credentials are not available
      payment_method = @payment.payment_method
      url = URI.parse(payment_method.payu_auth_url)
      res = Net::HTTP.post_form(url,
        'grant_type' => 'client_credentials',
        'client_id' => payment_method.preferences[:client_id],
        'client_secret' => payment_method.preferences[:client_secret])
      JSON.parse(res.body)
    end

    def payu_redirect_url(credentials)
      url = URI.parse(@payment.payment_method.payu_order_url)
      req = Net::HTTP::Post.new(url,
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{credentials['access_token']}")
      req["Content-Type"] = "application/json"
      http = Net::HTTP.new(url.hostname, url.port)
      http.use_ssl = true
      # http.set_debug_output($stdout)
      data = build_redirect_params
      req.body = data.to_json
      res = http.request(req)

      puts "params: #{data}"

      redirect_url = res["location"]

      if !redirect_url
        raise StandardError, "Invalid redirect: #{res.inspect} body:#{res.body}"
      end

      redirect_url
    end

    def build_redirect_params
      order = @payment.order
      bill_address = order.bill_address

      params = {
        # mandatory parameters
        # "notifyUrl" => payu_notify_url(host: order.store.url),
        "continueUrl" => order_url(host: order.store.url, id: order.number),
        "customerIp" => order.last_ip_address,
        "merchantPosId" => "#{@payment.payment_method.preferences[:pos_id]}",
        "description" => order.store.name,
        "currencyCode" => @payment.payment_method.preferences[:test_mode] ? "PLN" : order.store.default_currency,
        "totalAmount" => order.amount.to_i.to_s,
        "extOrderId" => "AVL-#{order.number}:#{Time.now.to_i}",
        "buyer" => {
          "email" => order.email,
          "phone" => bill_address.phone,
          "firstName" => bill_address.firstname,
          "lastName" => bill_address.lastname,
          "language" => I18n.locale.to_s
        },
        "products" => @payment.order.line_items.map { |item| {
          "name" => item.product.name,
          "unitPrice" => item.price.to_i.to_s,
          "quantity" => item.quantity
        } },
        "payMethods" => {
          "payMethod" => {
            "type" => "PBL",
            "value" => "c"
          }
        }
      }

      params.keep_if { |_, value| value.present? }
    end
  end
end
