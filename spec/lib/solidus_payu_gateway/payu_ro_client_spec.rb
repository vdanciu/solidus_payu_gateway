require "spec_helper"

describe SolidusPayuGateway::PayuRoClient do
  let(:line_item1) { create :line_item, price: 50 }
  let(:line_item2) { create :line_item, price: 60 }
  let(:payment_method) { create(:payu_payment_method, preference_source: "payu_credentials") }
  let(:payment) { create(:payu_payment, payment_method: payment_method) }
  let(:secret) { "1231234567890123" }
  let(:base_params) {
    {
      "MERCHANT" => "PAYUDEMO",
      "ORDER_REF" => "789456123",
      "ORDER_DATE" => "2016-04-10 17:30:56",
      "ORDER_PNAME[]" => ["CD Player", "Mobile Phone", "Laptop"],
      "ORDER_PCODE[]" => ["SKU_04891", "SKU_07409", "SKU_04965"],
      "ORDER_PINFO[]" => ["Extended Warranty - 5 Years", "Dual SIM", '17" Display'],
      "ORDER_PRICE[]" => ["82.3", "1945.75", "5230"],
      "ORDER_PRICE_TYPE[]" => ["GROSS", "GROSS", "GROSS"],
      "ORDER_QTY[]" => ["1", "1", "1"],
      "ORDER_VAT[]" => ["19", "19", "19"],
      "PRICES_CURRENCY" => "RON",
      "ORDER_SHIPPING" => "",
      "DISCOUNT" => "55",
      "LANGUAGE" => "RO",
      "PAY_METHOD" => "CCVISAMC",
      "TESTORDER" => "TRUE",
      "BILL_FNAME" => "Average",
      "BILL_LNAME" => "Joes",
      "BILL_COMPANY" => "SC COMPANY SRL",
      "BILL_FISCALCODE" => "J40/1234",
      "BILL_REGNUMBER" => "RO1234",
      "BILL_EMAIL" => "average.joes@email.com",
      "BILL_PHONE" => "0700000000",
      "BILL_COUNTRYCODE" => "RO"
    }
  }
  let(:correct_hash_string) { '8PAYUDEMO9789456123192016-04-10 17:30:569CD Player12Mobile Phone6Laptop9SKU_048919SKU_074099SKU_0496527Extended Warranty - 5 Years8Dual SIM1117" Display482.371945.754523011111121921921903RON2558CCVISAMC5GROSS5GROSS5GROSS4TRUE' }
  let(:correct_signature) { "1f2393078b4d365083927e41fea507d9" }

  subject { described_class.new(payment) }

  describe "#new" do
    it "requires the payment parameter" do
      expect { described_class.new }.to raise_error(ArgumentError)
      expect { subject }.to_not raise_error
    end
  end

  describe "#compute_hash_string" do
    it "works" do
      expect(subject.send(:compute_hash_string, base_params)).to eql(correct_hash_string)
    end
  end

  describe "#add_signature" do
    it "works" do
      expect(subject.send(:add_signature, base_params, secret)['ORDER_HASH']).to eql(correct_signature)
    end
  end

  describe ".redirect_ro_url" do
    before do
      allow_any_instance_of(Spree::Order).to receive_messages(
        line_items: [line_item1, line_item2],
        total: 110,
        number: "R123456789",
        email: "user@example.com"
      )
      allow_any_instance_of(Spree::Address).to receive_messages(
        lastname: "Boyd"
      )
    end

    it "will return a redirect url" do
      expect(subject.payu_order_form).to include('form action', 'Boyd')
    end
  end
end
