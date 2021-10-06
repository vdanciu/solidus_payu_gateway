Spree::Core::Engine.routes.draw do
  get "/payu/gateway", to: "payu#gateway", as: :payu_gateway
  post "/payu/notify", to: "payu#notify", as: :payu_notify
  get "/payu/notify", to: "payu#notify"
  get "/payu/continue/:id", to: "payu#continue", as: :payu_continue
  post "/payu/continue/:id", to: "payu#continue"
end
