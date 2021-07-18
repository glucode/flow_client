# frozen_string_literal: true

require "rlp"

RSpec.describe FlowClient::Transaction do
  it "has a valid domain tag const" do
    expect(FlowClient::Transaction.padded_transaction_domain_tag.unpack1("H*")).to eq(
      "464c4f572d56302e302d7472616e73616374696f6e0000000000000000000000"
    )
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
      block_id = "123"
      @transaction.reference_block_id = block_id
      expect(@transaction.reference_block_id).to eq(block_id)
    end
  end

  context 'the generated payload' do
    it "correctly packages the script" do
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
    client = FlowClient::Client.new("127.0.0.1:3569")
    ref_block_id = client.get_latest_block.block.id.unpack1('H*')

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
    transaction.proposer_key_sequence_number = 3
    transaction.payer_address = "f8d6e0586b0a20c7"
    transaction.authorizer_addresses = ["f8d6e0586b0a20c7"]
    transaction.add_envelope_signature("f8d6e0586b0a20c7", 0, key)
    message = transaction.to_message
    # puts client.send_transaction(message)
  end
end
