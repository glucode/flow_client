# frozen_string_literal: true

RSpec.describe FlowClient::Client do
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
        nft_contract = File.read(File.join("lib", "cadence", "contracts", "NonFungibleToken.cdc"))


        signer = FlowClient::LocalSigner.new(service_account_private_key)
        payer_account = FlowClient::Account.new(address: service_account_address)


        new_account = client.create_account([@pub_key], { "NonFungibleToken": nft_contract }, payer_account, signer)

        expect(new_account).to be_an_instance_of(FlowClient::Account)
        expect(new_account.address).not_to be_nil
        expect(new_account.balance).not_to be_nil
        expect(new_account.keys).not_to be_nil
        expect(new_account.contracts.count).to eq(1)
      end
    end

    describe "add_account_key" do
      it "adds the key to the account" do
        priv_key_one, pub_key_one = FlowClient::Crypto.generate_key_pair(FlowClient::Crypto::Curves::P256)
        _priv_key_two, pub_key_two = FlowClient::Crypto.generate_key_pair(FlowClient::Crypto::Curves::P256)

        signer = FlowClient::LocalSigner.new(service_account_private_key)
        payer_account = FlowClient::Account.new(address: service_account_address)
        new_account = client.create_account([pub_key_one], {}, payer_account, signer)

        signer = FlowClient::LocalSigner.new(priv_key_one)
        client.add_account_key(pub_key_two, new_account, signer, 1000.0)

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

          expect do
            client.add_contract("NonFungibleToken", code, account, signer)
          end.not_to raise_error

          expect do
            client.update_contract("NonFungibleToken", code, account, signer)
          end.not_to raise_error

          expect do
            client.remove_contract("NonFungibleToken", account, signer)
          end.not_to raise_error
        end
      end
    end
  end

  context "blocks" do
    describe "get_latest_block" do
      before(:each) do
        @block = client.get_latest_block
      end

      it { expect(@block).to be_an_instance_of(FlowClient::Block) }
      it { expect(@block.id).to be_an_instance_of(String) }
      it { expect(@block.parent_id).to be_an_instance_of(String) }
      it { expect(@block.height).to be_an_instance_of(Integer) }
      it { expect(@block.collection_guarantees).to be_an_instance_of(Array) }
    end

    describe "get_block_by_id" do
      before(:each) do
        latest_block = client.get_latest_block
        @block = client.get_block_by_id(latest_block.id)
      end

      it { expect(@block).to be_an_instance_of(FlowClient::Block) }
      it { expect(@block.id).to be_an_instance_of(String) }
      it { expect(@block.parent_id).to be_an_instance_of(String) }
      it { expect(@block.height).to be_an_instance_of(Integer) }
      it { expect(@block.collection_guarantees).to be_an_instance_of(Array) }
    end

    describe "get_block_by_height" do
      before(:each) do
        latest_block = client.get_latest_block
        @block = client.get_block_by_height(latest_block.height)
      end

      it { expect(@block).to be_an_instance_of(FlowClient::Block) }
      it { expect(@block.id).to be_an_instance_of(String) }
      it { expect(@block.parent_id).to be_an_instance_of(String) }
      it { expect(@block.height).to be_an_instance_of(Integer) }
      it { expect(@block.collection_guarantees).to be_an_instance_of(Array) }
    end
  end

  context "collections" do
    describe "get_collection_by_id" do
      before(:each) do
        latest_block = client.get_latest_block
        cid = latest_block.collection_guarantees.first.collection_id
        @collection = client.get_collection_by_id(cid)
      end

      it { expect(@collection).to be_an_instance_of(FlowClient::Collection) }
      it { expect(@collection).not_to be(nil) }
      it { expect(@collection.id).to be_an_instance_of(String) }
      it { expect(@collection.transaction_ids).to be_an_instance_of(Array) }
    end
  end

  context "script" do
    it "sends a simple script" do
      
      script = %{
        pub fun main(a: Int): Int {
          return a + 10
        }
      }
      
      args = [FlowClient::CadenceType.Int(1)]
      res = client.execute_script(script, args)

      expect(res.type).to eq("Int")
      expect(res.value).to eq("11")
    end
  end
end
