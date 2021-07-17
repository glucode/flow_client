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
    client = FlowClient::Client.new("access.devnet.nodes.onflow.org:9000")
    ref_block_id = client.get_latest_block.block.id.unpack1('H*')

    key = FlowClient::Crypto.key_from_hex_keys(
      '703efdc5c8594759b35ba110c352e2e55cf780eb41d94484125ec71553474a20',
      '045f729cef1fe88ab59063b9f3eca7c9ec4a4b37cb6cb914b94b9fc49d71e299e08986949c92994de5fba0887753a17d19cc257fc31a69f20568b5bfb211147d8a'
    )

    transaction = FlowClient::Transaction.new
    transaction.script = %{
      transaction {
          prepare(acct: AuthAccount){}
          execute { log("Hello") }
      }
    }
    transaction.reference_block_id = ref_block_id
    transaction.proposer_address = "76ecd94a2bb02327"
    transaction.proposer_key_index = 0
    transaction.arguments = []
    transaction.proposer_key_sequence_number = 45
    transaction.payer_address = "76ecd94a2bb02327"
    transaction.authorizer_addresses = ["76ecd94a2bb02327"]
    transaction.add_envelope_signature("76ecd94a2bb02327", 0, key)
    message = transaction.to_message
  end
end
