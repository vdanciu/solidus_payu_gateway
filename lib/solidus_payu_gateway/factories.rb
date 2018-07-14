FactoryBot.define do
  factory :payu_payment_method, class: Spree::PaymentMethod::PayuRo do
    name "PayuRO"
  end

  factory :payu_payment, class: Spree::Payment do
    association(:payment_method, factory: :payu_payment_method)
    order
  end
end
