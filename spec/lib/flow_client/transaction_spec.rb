# frozen_string_literal: true

require "rlp"

RSpec.describe FlowClient::Transaction do
  let(:service_account_address) { "f8d6e0586b0a20c7" }
  let(:client) { FlowClient::Client.new("localhost:3569") }
  let(:reference_block_id) { client.get_latest_block.id }
  let(:gas_limit) { 9999 }
  let(:arguments) { [FlowClient::CadenceType.String("Hello world!")] }

  let(:service_account_private_key) do
    "4d9287571c8bff7482ffc27ef68d5b4990f9bd009a1e9fa812aae08ba167d57f"
  end

  let(:script) do
    %{
      transaction(message: String) {
        prepare(acct: AuthAccount) {}
        execute { log(message) }
      }
    }
  end

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
    it { expect(@transaction.proposal_key.address).to eq(nil) }
    it { expect(@transaction.proposal_key.key_id).to eq(nil) }
    it { expect(@transaction.proposal_key.sequence_number).to eq(nil) }
    it { expect(@transaction.payer_address).to eq(nil) }
    it { expect(@transaction.authorizer_addresses).to eq([]) }
    it { expect(@transaction.envelope_signatures).to eq([]) }
  end

  context "accessors" do
    before(:example) do
      @transaction = FlowClient::Transaction.new
    end

    it "sets the script" do
      script = %w{transaction { execute { log(HelloWorld.hello()) } }}
      @transaction.script = script
      expect(@transaction.script).to eq(script)
    end

    it "sets the ref block id" do
      @transaction.reference_block_id = reference_block_id
      expect(@transaction.reference_block_id).to eq(reference_block_id)
    end
  end

  describe "signing" do
    let(:padded_address) do
      FlowClient::Utils.left_pad_bytes([service_account_address].pack("H*").bytes, 8).pack("C*")
    end

    let(:service_account_key) { client.get_account(service_account_address).keys.first }

    let(:transaction) do
      @transaction = FlowClient::Transaction.new
      @transaction.script = script
      @transaction.reference_block_id = reference_block_id
      @transaction.gas_limit = gas_limit
      @transaction.proposer_address = service_account_address
      @transaction.proposer_key_index = service_account_key.index
      @transaction.arguments = arguments
      @transaction.proposer_key_sequence_number = service_account_key.sequence_number
      @transaction.payer_address = service_account_address
      @transaction.authorizer_addresses = [service_account_address]
      @transaction
    end

    context "single proposer, payer and signer" do
      it "has a valid signature" do
        signer = FlowClient::LocalSigner.new(service_account_private_key)
        transaction.add_envelope_signature(service_account_address, 0, signer)
        tx = client.send_transaction(transaction)
        client.wait_for_transaction(tx.id) do |result|
          expect(result.status_code).to be(0)
        end
      end
    end

    context "single party, multiple signatures" do
      it "successfully signs with mutliple signatures" do
        priv_key_one, pub_key_one = FlowClient::Crypto.generate_key_pair
        priv_key_two, pub_key_two = FlowClient::Crypto.generate_key_pair

        payer_signer = FlowClient::LocalSigner.new(service_account_private_key)
        payer_account = FlowClient::Account.new(address: service_account_address)
        new_account = client.create_account([pub_key_one], {}, payer_account, payer_signer)

        auth_signer_one = FlowClient::LocalSigner.new(priv_key_one)
        auth_signer_two = FlowClient::LocalSigner.new(priv_key_two)
        client.add_account_key(pub_key_two, new_account, auth_signer_one, 500.0)

        new_account = client.get_account(new_account.address)

        expect(client.get_account(new_account.address).keys.count).to eq(2)

        @transaction = FlowClient::Transaction.new
        @transaction.script = script
        @transaction.reference_block_id = client.get_latest_block.id
        @transaction.gas_limit = gas_limit
        @transaction.proposer_address = new_account.address
        @transaction.proposer_key_index = new_account.keys[0].index
        @transaction.arguments = arguments
        @transaction.proposer_key_sequence_number = new_account.keys[0].sequence_number
        @transaction.payer_address = new_account.address
        @transaction.authorizer_addresses = [new_account.address]
        @transaction.add_envelope_signature(new_account.address, new_account.keys[0].index, auth_signer_one)
        @transaction.add_envelope_signature(new_account.address, new_account.keys[1].index, auth_signer_two)
        tx_res = client.send_transaction(@transaction)
        client.wait_for_transaction(tx_res.id) do |response|
          expect(response.status_code).to eq(0)
        end
      end
    end

    context "multiple parties" do
      it "successfully signs with a single signature" do
        authorizer_priv_key, authorizer_pub_key = FlowClient::Crypto.generate_key_pair

        service_account = client.get_account(service_account_address)
        payer_signer = FlowClient::LocalSigner.new(service_account_private_key)

        # Create a new account that will be executing the transaction
        new_account = client.create_account([authorizer_pub_key], {}, service_account, payer_signer)
        authorizer_signer = FlowClient::LocalSigner.new(
          authorizer_priv_key
        )

        transaction = FlowClient::Transaction.new
        transaction.script = script
        transaction.reference_block_id = client.get_latest_block.id
        transaction.proposer_address = new_account.address
        transaction.proposer_key_index = new_account.keys.first.index
        transaction.arguments = arguments
        transaction.proposer_key_sequence_number = new_account.keys.first.sequence_number
        transaction.authorizer_addresses = [new_account.address]
        transaction.payer_address = service_account_address
        transaction.add_payload_signature(new_account.address, new_account.keys.first.index, authorizer_signer)
        transaction.add_envelope_signature(service_account_address, service_account.keys.first.index, payer_signer)

        res = client.send_transaction(transaction)

        client.wait_for_transaction(res.id) do |response|
          expect(response.status_code).to be(0)
        end
      end

      it "successfully signs with multi party, two authorizers" do
        script = %{
          transaction {
            prepare(signer1: AuthAccount, signer2: AuthAccount) {
              log(signer1.address)
              log(signer2.address)
            }
          }
        }

        payer_account = client.get_account(service_account_address)
        payer_signer = FlowClient::LocalSigner.new(service_account_private_key)

        # Create a new account
        priv_key_one, pub_key_one = FlowClient::Crypto.generate_key_pair
        new_account_one = client.create_account([pub_key_one], {}, payer_account, payer_signer)
        auth_signer_one = FlowClient::LocalSigner.new(priv_key_one)
        client.add_account_key(pub_key_one, new_account_one, auth_signer_one, 1000.0)
        new_account_one = client.get_account(new_account_one.address)

        @transaction = FlowClient::Transaction.new
        @transaction.script = script
        @transaction.reference_block_id = client.get_latest_block.id
        @transaction.gas_limit = gas_limit
        @transaction.arguments = []

        @transaction.proposer_address = new_account_one.address
        @transaction.proposer_key_index = new_account_one.keys[0].index
        @transaction.proposer_key_sequence_number = new_account_one.keys[0].sequence_number

        @transaction.payer_address = payer_account.address
        @transaction.authorizer_addresses = [new_account_one.address, payer_account.address]

        @transaction.add_payload_signature(new_account_one.address, new_account_one.keys[0].index, auth_signer_one)
        @transaction.add_envelope_signature(payer_account.address, payer_account.keys[0].index, payer_signer)

        tx_res = client.send_transaction(@transaction)
        client.wait_for_transaction(tx_res.id) do |response|
          expect(response.status_code).to eq(0)
        end
      end

      it "successfully signs with multiple signatures" do
        script = %{
          transaction {
            prepare(signer: AuthAccount) { log(signer.address) }
          }
        }

        priv_key_one, pub_key_one = FlowClient::Crypto.generate_key_pair
        priv_key_two, pub_key_two = FlowClient::Crypto.generate_key_pair
        priv_key_three, pub_key_three = FlowClient::Crypto.generate_key_pair

        payer_priv_key_two, payer_pub_key_two = FlowClient::Crypto.generate_key_pair
        payer_account = client.get_account(service_account_address)
        payer_signer = FlowClient::LocalSigner.new(service_account_private_key)
        payer_signer_two = FlowClient::LocalSigner.new(payer_priv_key_two)
        client.add_account_key(payer_pub_key_two, payer_account, payer_signer, 500.0)
        payer_account = client.get_account(payer_account.address)

        # Create a new account
        new_account = client.create_account([pub_key_one], {}, payer_account, payer_signer)

        # Create in-memory signers with the private keys
        auth_signer_one = FlowClient::LocalSigner.new(priv_key_one)
        auth_signer_two = FlowClient::LocalSigner.new(priv_key_two)
        auth_signer_three = FlowClient::LocalSigner.new(priv_key_three)

        # Add the public keys to the new account
        client.add_account_key(pub_key_two, new_account, auth_signer_one, 500.0)
        client.add_account_key(pub_key_three, new_account, auth_signer_one, 500.0)

        new_account = client.get_account(new_account.address)
        expect(client.get_account(new_account.address).keys.count).to eq(3)

        @transaction = FlowClient::Transaction.new
        @transaction.script = script
        @transaction.reference_block_id = client.get_latest_block.id
        @transaction.gas_limit = gas_limit
        @transaction.arguments = []

        @transaction.proposer_address = new_account.address
        @transaction.proposer_key_index = new_account.keys[1].index
        @transaction.proposer_key_sequence_number = new_account.keys[1].sequence_number

        @transaction.payer_address = payer_account.address
        @transaction.authorizer_addresses = [new_account.address]

        @transaction.add_payload_signature(new_account.address, new_account.keys[1].index, auth_signer_two)
        @transaction.add_payload_signature(new_account.address, new_account.keys[2].index, auth_signer_three)

        @transaction.add_envelope_signature(payer_account.address, payer_account.keys.first.index, payer_signer)
        @transaction.add_envelope_signature(payer_account.address, payer_account.keys.last.index, payer_signer_two)

        tx_res = client.send_transaction(@transaction)
        client.wait_for_transaction(tx_res.id) do |response|
          expect(response.status_code).to eq(0)
        end
      end
    end
  end

  describe "to_protobuf_message" do
    let(:script) do
      %{
        transaction(message: String) {
            prepare(acct: AuthAccount) {}
            execute { log(message) }
        }
      }
    end

    let(:arguments) { [{ type: "String", value: "Hello world!" }.to_json] }
    let(:gas_limit) { 100 }
    let(:service_account_address) { "f8d6e0586b0a20c7" }

    let(:padded_address) do
      FlowClient::Utils.left_pad_bytes(["f8d6e0586b0a20c7"].pack("H*").bytes, 8).pack("C*")
    end

    let(:protobuf_message) do
      signer = FlowClient::LocalSigner.new(service_account_private_key)
      @transaction = FlowClient::Transaction.new
      @transaction.script = script
      @transaction.reference_block_id = reference_block_id
      @transaction.gas_limit = gas_limit
      @transaction.proposer_address = service_account_address
      @transaction.proposer_key_index = 1
      @transaction.arguments = arguments
      @transaction.proposer_key_sequence_number = 10
      @transaction.payer_address = service_account_address
      @transaction.authorizer_addresses = [service_account_address]
      @transaction.add_envelope_signature(service_account_address, 0, signer)
      @transaction.to_protobuf_message
    end

    it { expect(protobuf_message).to be_a(Entities::Transaction) }
    it { expect(protobuf_message.script).to eq(script) }
    it { expect(protobuf_message.arguments).to eq(arguments) }
    it { expect(protobuf_message.reference_block_id).to eq([reference_block_id].pack("H*")) }
    it { expect(protobuf_message.gas_limit).to eq(gas_limit) }

    it { expect(protobuf_message.proposal_key).to be_a(Entities::Transaction::ProposalKey) }
    it { expect(protobuf_message.proposal_key.address).to eq(padded_address) }
    it { expect(protobuf_message.proposal_key.key_id).to eq(1) }
    it { expect(protobuf_message.proposal_key.sequence_number).to eq(10) }

    it { expect(protobuf_message.payer).to eq(padded_address) }
    it { expect(protobuf_message.authorizers).to eq([padded_address]) }
    it { expect(protobuf_message.payload_signatures).to eq([]) }
    it { expect(protobuf_message.envelope_signatures).to eq(@transaction.envelope_signatures) }
  end
end
