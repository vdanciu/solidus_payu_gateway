require "spec_helper"

describe Spree::PaymentMethod::Payu, type: :model do
  let(:payment_method) { create(:payu_payment_method, preference_source: "payu_credentials") }
  let(:payment) { create(:payu_payment, payment_method: payment_method) }

  it "has a valid factory" do
    expect(build(:payu_payment_method)).to be_valid
  end

  it "has a valid payment factory " do
    expect(build(:payu_payment)).to be_valid
  end

  describe "#redirect_url" do
    before do
      allow_any_instance_of(Spree::Order).to receive_messages(total: 110)
    end

    context "When in test mode" do
      it "returns the test URL with params" do
        expect(
          payment_method.redirect_url(payment)
        ).to start_with("/payu/gateway")
      end
    end
  end
end
