# frozen_string_literal: true

RSpec.describe FlowClient::Transaction do
  # TODO: Read these values from flow.json
  let(:client) { FlowClient::Client.new("localhost:3569") }
  let(:service_account_address) { "f8d6e0586b0a20c7" }
  let(:service_account_private_key) do
    "4d9287571c8bff7482ffc27ef68d5b4990f9bd009a1e9fa812aae08ba167d57f"
  end

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
        _priv_key_two, pub_key_two = FlowClient::Crypto.generate_key_pair

        signer = FlowClient::LocalSigner.new(service_account_private_key)
        payer_account = FlowClient::Account.new(address: service_account_address)
        new_account = client.create_account(pub_key_one, payer_account, signer)

        signer = FlowClient::LocalSigner.new(priv_key_one)
        client.add_account_key(new_account.address, pub_key_two, new_account, signer)

        expect(client.get_account(new_account.address).keys.count).to eq(2)
      end

      describe "contracts" do
        it "adds, updates and removes a contract" do
          code = File.read(File.join("lib", "cadence", "contracts", "NonFungibleToken.cdc"))
          
          priv_key_one, pub_key_one = FlowClient::Crypto.generate_key_pair
          _priv_key_two, pub_key_two = FlowClient::Crypto.generate_key_pair
  
          signer = FlowClient::LocalSigner.new(service_account_private_key)
          account = FlowClient::Account.new(address: service_account_address)

          client.remove_contract("NonFungibleToken", account, signer)

          expect{
            client.add_contract("NonFungibleToken", code, account, signer)
          }.not_to raise_error

          expect{
            client.update_contract("NonFungibleToken", code, account, signer)
          }.not_to raise_error

          expect{
            client.remove_contract("NonFungibleToken", account, signer)
          }.not_to raise_error
        end
      end
    end
  end

  context "blocks" do
    describe "get_latest_block" do
      before(:each) do
        @res = client.get_latest_block
      end

      it { expect(@res).to be_an_instance_of(Access::BlockResponse) }
      it { expect(@res.block.id.unpack1("H*")).to be_an_instance_of(String) }
      it { expect(@res.block.parent_id.unpack1("H*")).to be_an_instance_of(String) }
      it { expect(@res.block.height).to be_an_instance_of(Integer) }
      it { expect(@res.block.collection_guarantees).to be_an_instance_of(Google::Protobuf::RepeatedField) }
    end

    describe "get_block_by_id" do
      before(:each) do
        latest_block = client.get_latest_block
        @res = client.get_block_by_id(latest_block.block.id.unpack1("H*"))
      end

      it { expect(@res).to be_an_instance_of(Access::BlockResponse) }
      it { expect(@res.block.id.unpack1("H*")).to be_an_instance_of(String) }
      it { expect(@res.block.parent_id.unpack1("H*")).to be_an_instance_of(String) }
      it { expect(@res.block.height).to be_an_instance_of(Integer) }
      it { expect(@res.block.collection_guarantees).to be_an_instance_of(Google::Protobuf::RepeatedField) }
    end

    describe "get_block_by_height" do
      before(:each) do
        latest_block = client.get_latest_block
        @res = client.get_block_by_height(latest_block.block.height)
      end

      it { expect(@res).to be_an_instance_of(Access::BlockResponse) }
      it { expect(@res.block.id.unpack1("H*")).to be_an_instance_of(String) }
      it { expect(@res.block.parent_id.unpack1("H*")).to be_an_instance_of(String) }
      it { expect(@res.block.height).to be_an_instance_of(Integer) }
      it { expect(@res.block.collection_guarantees).to be_an_instance_of(Google::Protobuf::RepeatedField) }
    end
  end

  context "collections" do
    describe "get_collection_by_id" do
      before(:each) do
        latest_block = client.get_latest_block
        cid = latest_block.block.collection_guarantees.first.collection_id.unpack1("H*")
        @res = client.get_collection_by_id(cid)
      end

      it { expect(@res).not_to be(nil) }
      it { expect(@res.collection.id.unpack1("H*")).to be_an_instance_of(String) }
      it { expect(@res.collection.transaction_ids).to be_an_instance_of(Google::Protobuf::RepeatedField) }
    end
  end
end
