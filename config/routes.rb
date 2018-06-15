Spree::Core::Engine.routes.draw do
  get "/payu/gateway", to: "payu#gateway", as: :payu_gateway
  put "/payu/notify", to: "payu#notify", as: :payu_notify
end
