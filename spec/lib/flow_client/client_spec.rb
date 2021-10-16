# frozen_string_literal: true

RSpec.describe FlowClient::Transaction do
  let(:client) { FlowClient::Client.new("localhost:3569") }

  describe "ping" do
    it "pings the " do
      expect(client.ping).to be_an_instance_of(Access::PingResponse)
    end
  end

  context "accounts" do
    describe "create_account" do
      before(:each) do
        @priv_key, @pub_key = FlowClient::Crypto.generate_key
        puts @pub_key

        @service_account_key = FlowClient::Crypto.key_from_hex_keys(
          "4d9287571c8bff7482ffc27ef68d5b4990f9bd009a1e9fa812aae08ba167d57f"
        )
      end

      it "creates a new account" do
        path = File.join("lib", "cadence", "templates", "create-account.cdc")
        script = File.read(path)

        arguments = [
          {
            type: "Array",
            value: [
              { type: "String", value: @pub_key }
            ]
          }.to_json,
          {
            type: "Dictionary",
            value: [
            ]
          }.to_json
        ]
  
        transaction = FlowClient::Transaction.new
        transaction.script = script
        transaction.reference_block_id = client.get_latest_block().block.id.unpack1("H*")
        transaction.proposer_address = "f8d6e0586b0a20c7"
        transaction.proposer_key_index = 0
        transaction.arguments = arguments
        transaction.proposer_key_sequence_number = client.get_account("f8d6e0586b0a20c7").keys.first.sequence_number
        transaction.payer_address = "f8d6e0586b0a20c7"
        transaction.authorizer_addresses = ["f8d6e0586b0a20c7"]
        transaction.add_envelope_signature("f8d6e0586b0a20c7", 0, @service_account_key)
        res = client.send_transaction(transaction)        
      end
    end
  end
end
