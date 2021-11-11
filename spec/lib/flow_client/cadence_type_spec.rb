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
            { type: "String", value: "Two" }
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
    let(:array) do
      CadenceType.Array(
        [
          CadenceType.String("One"),
          CadenceType.String("Two")
        ]
      )
    end

    it "converts to json" do
      json = {
        type: "Array",
        value: [
          { type: "String", value: "One" },
          { type: "String", value: "Two" }
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

  context "Integers" do
    types = %w[Int UInt Int8 UInt8 Int16 UInt16 Int32 UInt32 Int64 UInt64 Int128
               UInt128 Int256 UInt256]

    types.each do |type|
      it "" do
        json = {
          type: type,
          value: "1"
        }.to_json
        result = CadenceType.send(type, "1")
        expect(result.deep_to_h.to_json).to eq(json)
      end
    end
  end

  context "Word8" do
    let(:json) do
      {
        type: "Word8",
        value: "8"
      }.to_json
    end

    it { expect(CadenceType.Word8(8).deep_to_h.to_json).to eq(json) }
    it { expect(CadenceType.Word8("8").deep_to_h.to_json).to eq(json) }
  end

  context "Word16" do
    let(:json) do
      {
        type: "Word16",
        value: "16"
      }.to_json
    end

    it { expect(CadenceType.Word16(16).deep_to_h.to_json).to eq(json) }
    it { expect(CadenceType.Word16("16").deep_to_h.to_json).to eq(json) }
  end

  context "Word32" do
    let(:json) do
      {
        type: "Word32",
        value: "32"
      }.to_json
    end

    it { expect(CadenceType.Word32(32).deep_to_h.to_json).to eq(json) }
    it { expect(CadenceType.Word32("32").deep_to_h.to_json).to eq(json) }
  end

  context "Word64" do
    let(:json) do
      {
        type: "Word64",
        value: "64"
      }.to_json
    end

    it { expect(CadenceType.Word64(64).deep_to_h.to_json).to eq(json) }
    it { expect(CadenceType.Word64("64").deep_to_h.to_json).to eq(json) }
  end

  context "Fix64" do
    let(:json) do
      {
        type: "Fix64",
        value: "64.01"
      }.to_json
    end

    it { expect(CadenceType.Fix64(64.01).deep_to_h.to_json).to eq(json) }
    it { expect(CadenceType.Fix64("64.01").deep_to_h.to_json).to eq(json) }
  end

  context "UFix64" do
    let(:json) do
      {
        type: "UFix64",
        value: "64.01"
      }.to_json
    end

    it { expect(CadenceType.UFix64(64.01).deep_to_h.to_json).to eq(json) }
    it { expect(CadenceType.UFix64("64.01").deep_to_h.to_json).to eq(json) }
  end

  context "Address" do
    let(:json) do
      {
        type: "Address",
        value: "0x123"
      }.to_json
    end

    it { expect(CadenceType.Address("0x123").deep_to_h.to_json).to eq(json) }
  end

  context "Void" do
    let(:json) do
      {
        type: "Void"
      }.to_json
    end

    it { expect(CadenceType.Void().deep_to_h.to_json).to eq(json) }
  end

  context "Bool" do
    let(:true_json) do
      {
        type: "Bool",
        value: true
      }.to_json
    end

    let(:false_json) do
      {
        type: "Bool",
        value: false
      }.to_json
    end

    it { expect(CadenceType.Bool(true).deep_to_h.to_json).to eq(true_json) }
    it { expect(CadenceType.Bool("true").deep_to_h.to_json).to eq(true_json) }
    it { expect(CadenceType.Bool(false).deep_to_h.to_json).to eq(false_json) }
    it { expect(CadenceType.Bool("false").deep_to_h.to_json).to eq(false_json) }
  end

  context "Path" do
    domains = %w[storage private public]

    domains.each do |domain|
      json = {
        type: "Path",
        value: {
          domain: domain.to_s,
          identifier: "flowTokenVault"
        }
      }.to_json

      it { expect(CadenceType.Path(domain, "flowTokenVault").deep_to_h.to_json).to eq(json) }
    end
  end

  context "Capability" do
    json = {
      type: "Capability",
      value: {
        path: "/public/someInteger",
        address: "0x1",
        borrowType: "Int"
      }
    }.to_json

    it { expect(CadenceType.Capability("/public/someInteger", "0x1", "Int").deep_to_h.to_json).to eq(json) }
  end

  context "Type" do
    it "" do
      json = {
        type: "Type",
        value: {
          staticType: "Int"
        }
      }.to_json

      expect(CadenceType.Type("Int").deep_to_h.to_json).to eq(json)
    end
  end
end
