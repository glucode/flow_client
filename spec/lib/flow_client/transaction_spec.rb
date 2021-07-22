# frozen_string_literal: true

require "rlp"

RSpec.describe FlowClient::Transaction do
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
      block_id = "7bc42fe85d32ca513769a74f97f7e1a7bad6c9407f0d934c2aa645ef9cf613c7"
      @transaction.reference_block_id = block_id
      expect(@transaction.reference_block_id).to eq(block_id)
    end
  end

  context 'the generated payload' do
    it "correctly packages the script" do
      ref_block_id = "7bc42fe85d32ca513769a74f97f7e1a7bad6c9407f0d934c2aa645ef9cf613c7"

      # transaction = FlowClient::Transaction.new
      # transaction.script = %{
      #   transaction { 
      #     prepare(signer: AuthAccount) { log(signer.address) }
      #   }
      # }
      # transaction.reference_block_id = ref_block_id
      # transaction.proposer_address = "f8d6e0586b0a20c7"
      # transaction.proposer_key_index = 0
      # transaction.proposer_key_sequence_number = 0
      # transaction.payer_address = "f8d6e0586b0a20c7"
      # transaction.authorizer_addresses = []
      # message = transaction.to_message

      # decoded_payload = RLP.decode(FlowClient::Transaction.new.payload_message)
    end
  end

  it "envelope" do
  end

  it "converts the transaction to a pb message" do
    ref_block_id = "7bc42fe85d32ca513769a74f97f7e1a7bad6c9407f0d934c2aa645ef9cf613c7"

    key = FlowClient::Crypto.key_from_hex_keys(
      '81c9655ca2affbd3421c90a1294260b62f1fd4e9aaeb70da4b9185ebb4f4a26b',
      '041c3e4980f2e7d733a7b023b6f9b9f5c0ff8116869492fd3b813597f9d17f826130c2e68fee90fc8beeabcb05c2bffa4997166ba5ab86942b03c8c86ab13e50d8'
    )

    transaction = FlowClient::Transaction.new
    transaction.script = %{
      transaction(message: String) {
          prepare(acct: AuthAccount) {}
          execute { log(message) }
      }
    }
    transaction.reference_block_id = ref_block_id
    transaction.proposer_address = "f8d6e0586b0a20c7"
    transaction.proposer_key_index = 0
    transaction.arguments = [ { type: "String", value: "Hello world!" }.to_json ]
    transaction.proposer_key_sequence_number = 0
    transaction.payer_address = "f8d6e0586b0a20c7"
    transaction.authorizer_addresses = ["f8d6e0586b0a20c7"]
    transaction.add_envelope_signature("f8d6e0586b0a20c7", 0, key)
    message = transaction.to_protobuf_message
    puts message
  end
end
