module SolidusPayuGateway
  class Configuration < Spree::Preferences::Configuration
    attr_writer :test_order_url
    def test_order_url
      @test_order_url ||= "https://secure.snd.payu.com/api/v2_1/orders"
    end

    attr_writer :live_order_url
    def live_order_url
      @live_order_url ||= "https://secure.payu.com/api/v2_1/orders"
    end
    attr_writer :test_auth_url
    def test_auth_url
      @test_auth_url ||= "https://secure.snd.payu.com/pl/standard/user/oauth/authorize"
    end

    attr_writer :live_auth_url
    def live_auth_url
      @live_auth_url ||= "https://secure.payu.com/pl/standard/user/oauth/authorize"
    end
  end
end
