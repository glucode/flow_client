# frozen_string_literal: true
include FlowClient

RSpec.describe FlowClient::CadenceType do
  context "String" do
    let(:value) { CadenceType.String("String value") }

    it { expect(value.type).to eq("String") }
    it { expect(value.value).to eq("String value") }
  end

  context "Optional" do
    describe "non-nil value" do
      let(:value) { CadenceType.Optional("String value") }
      let(:json) do
        {
          type: "Optional",
          value: [
            { type: "String", value: "One" },
            { type: "String", value: "Two" },
          ]
        }.to_json
      end

      it { expect(value.type).to eq("Optional") }
      it { expect(value.value).to eq("String value") }
    end

    describe "nil value" do
      let(:value) { CadenceType.Optional() }
      let(:json) do
        {
          type: "Optional",
          value: nil
        }.to_json
      end

      it { expect(value.type).to eq("Optional") }
      it { expect(value.value).to eq(nil) }
    end


  end

  context "Array" do
    let(:array) {
      CadenceType.Array(
        [
          CadenceType.String("One"),
          CadenceType.String("Two")
        ]
      )
    }

    it "converts to json" do
      json = {
        type: "Array",
        value: [
          { type: "String", value: "One" },
          { type: "String", value: "Two" },
        ]
      }

      expect(array.deep_to_h.to_json).to eq(json.to_json)
    end

    it { expect(array.type).to eq("Array") }
    it { expect(array.value).to be_an_instance_of(Array) }
    it { expect(array.value.count).to eq(2) }
    it { expect(array.value.count).to eq(2) }
  end

  context "Composite" do
    let(:value) do
      CadenceType.CompositeValue(
        "0x3.GreatContract.GreatNFT",
        [CadenceType.Field("fname", "fvalue")]
      )
    end

    let(:composite) do
      CadenceType.Composite(
        :resource,
        value
      )
    end

    it { expect(composite.type).to eq("Resource") }
    it { expect(composite.value.id).to eq("0x3.GreatContract.GreatNFT") }
    it { expect(composite.value.fields).to be_an_instance_of(Array) }
    it { expect(composite.value.fields).to eq([CadenceType.Field("fname", "fvalue")]) }
  end
end