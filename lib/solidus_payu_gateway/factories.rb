FactoryBot.define do
  factory :payu_payment_method, class: Spree::PaymentMethod::Payu do
    name "PayU"
  end

  factory :payu_payment, class: Spree::Payment do
    association(:payment_method, factory: :payu_payment_method)
    order
  end
end
