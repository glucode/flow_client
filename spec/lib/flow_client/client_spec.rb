# frozen_string_literal: true

RSpec.describe FlowClient::Transaction do
  let(:client) { FlowClient::Client.new("localhost:3569") }
  let(:service_account_address) { "f8d6e0586b0a20c7" }
  let(:service_account_private_key) {
    FlowClient::Crypto.key_from_hex_keys(
      "4d9287571c8bff7482ffc27ef68d5b4990f9bd009a1e9fa812aae08ba167d57f"
    )
  }

  describe "ping" do
    it "pings the " do
      expect(client.ping).to be_an_instance_of(Access::PingResponse)
    end
  end

  context "accounts" do
    describe "get_account" do
      it "returns an account object" do
        account = client.get_account(service_account_address)
        expect(account).to be_an_instance_of(FlowClient::Account)
        expect(account.address).not_to be_nil
        expect(account.balance).not_to be_nil
        expect(account.keys).not_to be_nil
      end
    end

    describe "create_account" do
      before(:each) do
        @priv_key, @pub_key = FlowClient::Crypto.generate_key_pair
      end

      it "creates a new account" do
        signer = FlowClient::LocalSigner.new(service_account_private_key)
        payer_account = FlowClient::Account.new(address: service_account_address)
        new_account = client.create_account(@pub_key, payer_account, signer)

        expect(new_account).to be_an_instance_of(FlowClient::Account)
        expect(new_account.address).not_to be_nil
        expect(new_account.balance).not_to be_nil
        expect(new_account.keys).not_to be_nil
      end
    end

    describe "add_account_key" do
      it "adds the key to the account" do
        priv_key_one, pub_key_one = FlowClient::Crypto.generate_key_pair
        priv_key_two, pub_key_two = FlowClient::Crypto.generate_key_pair

        signer = FlowClient::LocalSigner.new(service_account_private_key)
        payer_account = FlowClient::Account.new(address: service_account_address)
        new_account = client.create_account(pub_key_one, payer_account, signer)

        new_account_key = FlowClient::Crypto.key_from_hex_keys(priv_key_one)
        signer = FlowClient::LocalSigner.new(new_account_key)
        client.add_account_key(new_account.address, pub_key_two, new_account, signer)

        expect(client.get_account(new_account.address).keys.count).to eq(2)
      end
    end
  end
end
