require "spec_helper"

describe SolidusPayuGateway::PayuClient do
  let(:payment_method) { create(:payu_payment_method, preference_source: "payu_credentials") }
  let(:payment) { create(:payu_payment, payment_method: payment_method) }
  subject { described_class.new(payment) }

  describe "#new" do
    it "requires the payment parameter" do
      expect { described_class.new }.to raise_error(ArgumentError)
      expect { subject }.to_not raise_error
    end
  end
end
