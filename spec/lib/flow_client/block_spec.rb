# frozen_string_literal: true

RSpec.describe FlowClient::Block do
  context "response parsing" do
    describe "gRPC parsing" do
      let(:service_account_address) { "f8d6e0586b0a20c7" }
      let(:client) { FlowClient::Client.new("localhost:3569") }

      let(:service_account_private_key) do
        "4d9287571c8bff7482ffc27ef68d5b4990f9bd009a1e9fa812aae08ba167d57f"
      end

      before(:each) do
        cadence = %{
          transaction() {
            prepare(authorizer: AuthAccount) {
              log("Hello")
            }
          }
        }

        account = client.get_account(service_account_address)
        signer = FlowClient::LocalSigner.new(service_account_private_key)

        transaction = FlowClient::Transaction.new
        transaction.script = cadence
        transaction.reference_block_id = client.get_latest_block.id
        transaction.gas_limit = 100
        transaction.proposer_address = account.address
        transaction.proposer_key_index = account.keys.first.index
        transaction.proposer_key_sequence_number = account.keys.first.sequence_number
        transaction.payer_address = account.address
        transaction.authorizer_addresses = [account.address]
        transaction.add_envelope_signature(account.address, 0, signer)
        tx = client.send_transaction(transaction)
        client.wait_for_transaction(tx.id) do |result|
          puts result.inspect
        end
      end

      # it { expect(block.id).to eq(response.id) }
      # it { expect(block.parent_id).to eq(response.parent_id) }
      # it { expect(block.height).to eq(response.height) }
    end
  end
end
