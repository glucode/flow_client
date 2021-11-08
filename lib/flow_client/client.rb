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

    # Gets an account
    def get_account(address)
      req = Access::GetAccountAtLatestBlockRequest.new(address: to_bytes(address))

      begin
        res = @stub.get_account_at_latest_block(req)
      rescue GRPC::BadStatus => e
        raise ClientError, e.details
      else
        account = FlowClient::Account.new(
          address: res.account.address.unpack1("H*"),
          balance: res.account.balance/100000000.0
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

    # Creates a new account
    #
    # 
    def create_account(new_account_public_key, payer_account, signer)
      script = File.read(File.join("lib", "cadence", "templates", "create-account.cdc"))

      arguments = [
        # CadenceType.Array(
        #   [CadenceType.String(new_account_public_key)]
        # ),
        {
          type: "Array",
          value: [
            { type: "String", value: new_account_public_key }
          ]
        }.to_json,
        {
          type: "Dictionary",
          value: []
        }.to_json
      ]

      transaction = FlowClient::Transaction.new
      transaction.script = script
      transaction.reference_block_id = get_latest_block.id
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

    # Adds a public key to an account
    def add_account_key(public_key_hex, payer_account, signer, weight)
      script = File.read(File.join("lib", "cadence", "templates", "add-account-key.cdc"))

      arguments = [
        {
          type: "String",
          value: public_key_hex
        }.to_json,
        {
          type: "UFix64",
          value: weight.to_s
        }.to_json
      ]

      transaction = FlowClient::Transaction.new
      transaction.script = script
      transaction.reference_block_id = get_latest_block.id
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

    # Adds a contract to an account
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
      transaction.reference_block_id = get_latest_block.id
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

    # Removes a contract from an account
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
      transaction.reference_block_id = get_latest_block.id
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

    # Updates a contract on an account
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
      transaction.reference_block_id = get_latest_block.id
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
      processed_args = []
      args.to_a.each do |arg|
        processed_arg = arg.class == OpenStruct ? Utils.openstruct_to_json(arg) : arg
        processed_args << processed_arg
      end

      req = Access::ExecuteScriptAtLatestBlockRequest.new(
        script: FlowClient::Utils.substitute_address_aliases(script, @address_aliases),
        arguments: processed_args
      )

      res = @stub.execute_script_at_latest_block(req)
      parse_json(res.value)
    end

    # Blocks
    def get_latest_block(is_sealed: true)
      req = Access::GetLatestBlockRequest.new(
        is_sealed: is_sealed
      )
      res = @stub.get_latest_block(req)
      Block.parse_grpc_block_response(res)
    end

    def get_block_by_id(id)
      req = Access::GetBlockByIDRequest.new(
        id: to_bytes(id)
      )
      res = @stub.get_block_by_id(req)
      Block.parse_grpc_block_response(res)
    end

    def get_block_by_height(height)
      req = Access::GetBlockByHeightRequest.new(
        height: height
      )
      res = @stub.get_block_by_height(req)
      Block.parse_grpc_block_response(res)
    end

    # Collections
    def get_collection_by_id(id)
      req = Access::GetCollectionByIDRequest.new(
        id: to_bytes(id)
      )
      res = @stub.get_collection_by_id(req)
      Collection.parse_grpc_type(res)
    end

    # Events
    def get_events(type, start_height, end_height)
      req = Access::GetEventsForHeightRangeRequest.new(
        type: type,
        start_height: start_height,
        end_height: end_height
      )
      begin
        res = @stub.get_events_for_height_range(req)
        puts res.inspect
      rescue GRPC::BadStatus => e
        raise ClientError, e.details
      else
        res.results.map { |event| EventsResult.parse_grpc_type(event) }
      end
    end

    # Transactions

    # Sends a transaction to the blockchain
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

      begin
        res = @stub.get_transaction(req)
      rescue GRPC::BadStatus => e
        raise ClientError, e.details
      else
        Transaction.parse_grpc_type(res.transaction)
      end
    end

    # Returns a transaction result
    def get_transaction_result(transaction_id)
      req = Access::GetTransactionRequest.new(
        id: to_bytes(transaction_id)
      )

      begin
        res = @stub.get_transaction_result(req)
      rescue GRPC::BadStatus => e
        raise ClientError, e.details
      else
        TransactionResult.parse_grpc_type(res)
      end
    end

    def wait_for_transaction(transaction_id)
      response = get_transaction_result(transaction_id)
      while response.status != :SEALED
        sleep(0.5)
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
