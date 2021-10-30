# frozen_string_literal: true

require "flow/access/access_services_pb"
require "flow/execution/execution_services_pb"
require "json"

# Collection of classes to interact with the Flow blockchain
module FlowClient
  class CadenceRuntimeError < StandardError
  end

  class ClientError < StandardError
  end

  # Flow client
  class Client
    attr_accessor :address_aliases

    def initialize(node_address)
      @stub = Access::AccessAPI::Stub.new(node_address, :this_channel_is_insecure)
      @address_aliases = {}
    end

    def ping
      req = Access::PingRequest.new
      @stub.ping(req)
    end

    # Accounts

    # Gets account detail for address
    def get_account(address)
      req = Access::GetAccountAtLatestBlockRequest.new(address: to_bytes(address))

      begin
        res = @stub.get_account_at_latest_block(req)
      rescue GRPC::BadStatus => e
        raise ClientError, e.details
      else
        account = FlowClient::Account.new(
          address: res.account.address.unpack1("H*"),
          balance: res.account.balance
        )

        res.account.keys.each do |key|
          account.keys << FlowClient::AccountKey.new(
            public_key: key.public_key.unpack1("H*"),
            index: key.index,
            sequence_number: key.sequence_number,
            revoked: key.revoked,
            weight: key.weight
          )
        end

        account.contracts = res.account.contracts

        account
      end
    end

    # Create a new account
    def create_account(public_key_hex, payer_account, signer)
      script = File.read(File.join("lib", "cadence", "templates", "create-account.cdc"))

      arguments = [
        {
          type: "Array",
          value: [
            { type: "String", value: public_key_hex }
          ]
        }.to_json,
        {
          type: "Dictionary",
          value: []
        }.to_json
      ]

      transaction = FlowClient::Transaction.new
      transaction.script = script
      transaction.reference_block_id = get_latest_block.block.id.unpack1("H*")
      transaction.proposer_address = payer_account.address
      transaction.proposer_key_index = 0
      transaction.arguments = arguments
      transaction.proposer_key_sequence_number = get_account(payer_account.address).keys.first.sequence_number
      transaction.payer_address = payer_account.address
      transaction.authorizer_addresses = [payer_account.address]
      transaction.add_envelope_signature(payer_account.address, 0, signer)
      res = send_transaction(transaction)

      new_account = nil
      wait_for_transaction(res.id.unpack1("H*")) do |response|
        raise CadenceRuntimeError, response.error_message if response.status_code != 0

        event_payload = response.events.select { |e| e.type == "flow.AccountCreated" }.first.payload
        payload_json = JSON.parse(event_payload)
        new_account_address = payload_json["value"]["fields"][0]["value"]["value"]
        new_account = get_account(new_account_address)
      end

      new_account
    end

    # Add account key
    def add_account_key(_address, public_key_hex, payer_account, signer)
      script = File.read(File.join("lib", "cadence", "templates", "add-account-key.cdc"))

      arguments = [
        {
          type: "String",
          value: public_key_hex
        }.to_json
      ]

      transaction = FlowClient::Transaction.new
      transaction.script = script
      transaction.reference_block_id = get_latest_block.block.id.unpack1("H*")
      transaction.proposer_address = payer_account.address
      transaction.proposer_key_index = 0
      transaction.arguments = arguments
      transaction.proposer_key_sequence_number = get_account(payer_account.address).keys.first.sequence_number
      transaction.payer_address = payer_account.address
      transaction.authorizer_addresses = [payer_account.address]
      transaction.add_envelope_signature(payer_account.address, 0, signer)
      res = send_transaction(transaction)

      wait_for_transaction(res.id.unpack1("H*")) do |response|
        raise CadenceRuntimeError, response.error_message if response.status_code != 0
      end
    end

    # Contracts

    def add_contract(name, code, payer_account, signer)
      script = File.read(File.join("lib", "cadence", "templates", "add-contract.cdc"))
      code_hex = code.unpack1("H*")

      arguments = [
        {
          type: "String",
          value: name
        }.to_json,
        {
          type: "String",
          value: code_hex
        }.to_json
      ]

      transaction = FlowClient::Transaction.new
      transaction.script = script
      transaction.reference_block_id = get_latest_block.block.id.unpack1("H*")
      transaction.proposer_address = payer_account.address
      transaction.proposer_key_index = 0
      transaction.arguments = arguments
      transaction.proposer_key_sequence_number = get_account(payer_account.address).keys.first.sequence_number
      transaction.payer_address = payer_account.address
      transaction.authorizer_addresses = [payer_account.address]
      transaction.add_envelope_signature(payer_account.address, 0, signer)
      res = send_transaction(transaction)

      wait_for_transaction(res.id.unpack1("H*")) do |response|
        raise CadenceRuntimeError, response.error_message if response.status_code != 0
      end
    end

    def remove_contract(name, payer_account, signer)
      script = File.read(File.join("lib", "cadence", "templates", "remove-contract.cdc"))

      arguments = [
        {
          type: "String",
          value: name
        }.to_json
      ]

      transaction = FlowClient::Transaction.new
      transaction.script = script
      transaction.reference_block_id = get_latest_block.block.id.unpack1("H*")
      transaction.proposer_address = payer_account.address
      transaction.proposer_key_index = 0
      transaction.arguments = arguments
      transaction.proposer_key_sequence_number = get_account(payer_account.address).keys.first.sequence_number
      transaction.payer_address = payer_account.address
      transaction.authorizer_addresses = [payer_account.address]
      transaction.add_envelope_signature(payer_account.address, 0, signer)
      res = send_transaction(transaction)

      wait_for_transaction(res.id.unpack1("H*")) do |response|
        raise CadenceRuntimeError, response.error_message if response.status_code != 0
      end
    end

    def update_contract(name, code, payer_account, signer)
      script = File.read(File.join("lib", "cadence", "templates", "update-contract.cdc"))
      code_hex = code.unpack1("H*")

      arguments = [
        {
          type: "String",
          value: name
        }.to_json,
        {
          type: "String",
          value: code_hex
        }.to_json
      ]

      transaction = FlowClient::Transaction.new
      transaction.script = script
      transaction.reference_block_id = get_latest_block.block.id.unpack1("H*")
      transaction.proposer_address = payer_account.address
      transaction.proposer_key_index = 0
      transaction.arguments = arguments
      transaction.proposer_key_sequence_number = get_account(payer_account.address).keys.first.sequence_number
      transaction.payer_address = payer_account.address
      transaction.authorizer_addresses = [payer_account.address]
      transaction.add_envelope_signature(payer_account.address, 0, signer)
      res = send_transaction(transaction)

      wait_for_transaction(res.id.unpack1("H*")) do |response|
        raise CadenceRuntimeError, response.error_message if response.status_code != 0
      end
    end

    # Scripts
    def execute_script(script, args = [])
      req = Access::ExecuteScriptAtLatestBlockRequest.new(
        script: FlowClient::Utils.substitute_address_aliases(script, @address_aliases),
        arguments: args
      )
      res = @stub.execute_script_at_latest_block(req)
      parse_json(res.value)
    end

    # Blocks
    def get_latest_block(is_sealed: true)
      req = Access::GetLatestBlockRequest.new(
        is_sealed: is_sealed
      )
      @stub.get_latest_block(req)
    end

    def get_block_by_id(id)
      req = Access::GetBlockByIDRequest.new(
        id: to_bytes(id)
      )
      @stub.get_block_by_id(req)
    end

    def get_block_by_height(height)
      req = Access::GetBlockByHeightRequest.new(
        height: height
      )
      @stub.get_block_by_height(req)
    end

    # Collections

    def get_collection_by_id(id)
      req = Access::GetCollectionByIDRequest.new(
        id: to_bytes(id)
      )
      @stub.get_collection_by_id(req)
    end

    # Events
    def get_events(type, start_height, end_height)
      req = Access::GetEventsForHeightRangeRequest.new(
        type: type,
        start_height: start_height,
        end_height: end_height
      )
      @stub.get_events_for_height_range(req)
    end

    # Transactions

    # Send a FlowClient::Transaction transaction to the blockchain
    def send_transaction(transaction)
      transaction.address_aliases = @address_aliases
      req = Access::SendTransactionRequest.new(
        transaction: transaction.to_protobuf_message
      )
      @stub.send_transaction(req)
    end

    def get_transaction(transaction_id)
      req = Access::GetTransactionRequest.new(
        id: to_bytes(transaction_id)
      )
      @stub.get_transaction(req)
    end

    def get_transaction_result(transaction_id)
      req = Access::GetTransactionRequest.new(
        id: to_bytes(transaction_id)
      )
      @stub.get_transaction_result(req)
    end

    def wait_for_transaction(transaction_id)
      response = get_transaction_result(transaction_id)
      while response.status != :SEALED
        sleep(1)
        response = get_transaction_result(transaction_id)
      end

      yield(response)
    end

    private

    def parse_json(event_payload)
      JSON.parse(event_payload, object_class: OpenStruct)
    end

    def to_bytes(string)
      [string].pack("H*")
    end

    def to_string(bytes)
      bytes.unpack1("H*")
    end
  end
end
