# frozen_string_literal: true

require "rlp"

RSpec.describe FlowClient::Transaction do
  it "instantiates a payload" do
    expect(FlowClient::Transaction.new.payload).not_to be nil
  end

  it "has a valid domain tag const" do
    expect(FlowClient::Transaction.padded_TRANSACTION_DOMAIN_TAG.unpack1("H*")).to eq(
      "464c4f572d56302e302d7472616e73616374696f6e0000000000000000000000"
    )
  end

  context 'the generated payload' do
    it "correctly packages the script" do
      decoded_payload = RLP.decode(FlowClient::Transaction.new.payload_message)
    end
  end

  it "envelope" do
    # puts FlowClient::Transaction.new.envelope_message.inspect
  end

  it "converts the transaction to a pb message" do
    client = FlowClient::Client.new("127.0.0.1:3569")
    ref_block_id = client.get_latest_block.block.id.unpack1('H*')

    transaction = FlowClient::Transaction.new
    # transaction.payload.reference_block_id = ref_block_id
    message = transaction.to_message

    puts client.send_transaction(message).inspect
  end
end
