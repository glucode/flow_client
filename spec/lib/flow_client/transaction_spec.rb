# frozen_string_literal: true

require "rlp"

RSpec.describe FlowClient::Transaction do
  let(:reference_block_id) { "7bc42fe85d32ca513769a74f97f7e1a7bad6c9407f0d934c2aa645ef9cf613c7" }

  let(:key) do
    FlowClient::Crypto.key_from_hex_keys(
      "81c9655ca2affbd3421c90a1294260b62f1fd4e9aaeb70da4b9185ebb4f4a26b"
    )
  end

  it "has a valid domain tag const" do
    expect(FlowClient::Transaction.padded_transaction_domain_tag.unpack1("H*")).to eq(
      "464c4f572d56302e302d7472616e73616374696f6e0000000000000000000000"
    )
  end

  context "init" do
    before(:example) do
      @transaction = FlowClient::Transaction.new
    end

    it { expect(@transaction.script).to eq("") }
    it { expect(@transaction.arguments).to eq([]) }
    it { expect(@transaction.reference_block_id).to eq(nil) }
    it { expect(@transaction.gas_limit).to eq(0) }
    it { expect(@transaction.proposer_address).to eq(nil) }
    it { expect(@transaction.proposer_key_index).to eq(0) }
    it { expect(@transaction.proposer_key_sequence_number).to eq(0) }
    it { expect(@transaction.payer_address).to eq(nil) }
    it { expect(@transaction.authorizer_addresses).to eq([]) }
    it { expect(@transaction.envelope_signatures).to eq([]) }
  end

  context "with accessors" do
    before(:example) do
      @transaction = FlowClient::Transaction.new
    end

    it "sets the script" do
      script = %w{transaction { execute { log(HelloWorld.hello()) } }}
      @transaction.script = script
      expect(@transaction.script).to eq(script)
    end

    it "sets the ref block id" do
      @transaction.reference_block_id = reference_block_id
      expect(@transaction.reference_block_id).to eq(reference_block_id)
    end
  end

  describe "envelope signatures" do
    let(:script) do
      %{
        transaction(message: String) {
            prepare(acct: AuthAccount) {}
            execute { log(message) }
        }
      }
    end

    let(:arguments) { [{ type: "String", value: "Hello world!" }.to_json] }

    let(:gas_limit) { 100 }

    let(:original_address) { "f8d6e0586b0a20c7" }

    let(:padded_address) do
      FlowClient::Utils.left_pad_bytes(["f8d6e0586b0a20c7"].pack("H*").bytes, 8).pack("C*")
    end

    let(:transaction) do
      @transaction = FlowClient::Transaction.new
      @transaction.script = script
      @transaction.reference_block_id = reference_block_id
      @transaction.gas_limit = gas_limit
      @transaction.proposer_address = original_address
      @transaction.proposer_key_index = 1
      @transaction.arguments = arguments
      @transaction.proposer_key_sequence_number = 10
      @transaction.payer_address = original_address
      @transaction.authorizer_addresses = [original_address]
      @transaction.add_envelope_signature(original_address, 0, key)
      @transaction.to_protobuf_message
      @transaction
    end

    context "single proposer, payer and signer" do
      it "has no payload signatures" do
        expect(transaction.payload_signatures).to eq([])
      end

      it "has a valid signature" do
        # @transaction.
      end
    end
  end

  describe "payload signatures" do
    it "adds a payload signature" do
      exp
    end
  end

  describe "to_protobuf_message" do
    let(:script) do
      %{
        transaction(message: String) {
            prepare(acct: AuthAccount) {}
            execute { log(message) }
        }
      }
    end

    let(:arguments) { [{ type: "String", value: "Hello world!" }.to_json] }
    let(:gas_limit) { 100 }
    let(:original_address) { "f8d6e0586b0a20c7" }

    let(:padded_address) do
      FlowClient::Utils.left_pad_bytes(["f8d6e0586b0a20c7"].pack("H*").bytes, 8).pack("C*")
    end

    let(:protobuf_message) do
      @transaction = FlowClient::Transaction.new
      @transaction.script = script
      @transaction.reference_block_id = reference_block_id
      @transaction.gas_limit = gas_limit
      @transaction.proposer_address = original_address
      @transaction.proposer_key_index = 1
      @transaction.arguments = arguments
      @transaction.proposer_key_sequence_number = 10
      @transaction.payer_address = original_address
      @transaction.authorizer_addresses = [original_address]
      @transaction.add_envelope_signature(original_address, 0, key)
      @transaction.to_protobuf_message
    end

    it { expect(protobuf_message).to be_a(Entities::Transaction) }
    it { expect(protobuf_message.script).to eq(script) }
    it { expect(protobuf_message.arguments).to eq(arguments) }
    it { expect(protobuf_message.reference_block_id).to eq([reference_block_id].pack("H*")) }
    it { expect(protobuf_message.gas_limit).to eq(gas_limit) }

    it { expect(protobuf_message.proposal_key).to be_a(Entities::Transaction::ProposalKey) }
    it { expect(protobuf_message.proposal_key.address).to eq(padded_address) }
    it { expect(protobuf_message.proposal_key.key_id).to eq(1) }
    it { expect(protobuf_message.proposal_key.sequence_number).to eq(10) }

    it { expect(protobuf_message.payer).to eq(padded_address) }
    it { expect(protobuf_message.authorizers).to eq([padded_address]) }
    it { expect(protobuf_message.payload_signatures).to eq([]) }
    it { expect(protobuf_message.envelope_signatures).to eq(@transaction.envelope_signatures) }
  end
end
