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

    transaction = FlowClient::Transaction.new
    transaction.script = %{
      transaction { 
        prepare(signer: AuthAccount) { log(signer.address) }
      }
    }
    transaction.reference_block_id = ref_block_id
    transaction.proposer_address = "f8d6e0586b0a20c7"
    transaction.proposer_key_index = 0
    transaction.proposer_key_sequence_number = 0
    transaction.payer_address = "f8d6e0586b0a20c7"
    transaction.authorizer_addresses = ["f8d6e0586b0a20c7"]
    message = transaction.to_message

    puts client.send_transaction(message).inspect
  end
end
