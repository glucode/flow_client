# frozen_string_literal: true

require "flow/access/access_services_pb"
require "flow/execution/execution_services_pb"
require "json"

# Collection of classes to interact with the Flow blockchain
module FlowClient
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
      res = @stub.get_account_at_latest_block(req)
      res.account
    end

    # Create a new account
    def create_account(account_pub_key, payer_account)
      script = File.read(File.join("lib", "cadence", "templates", "create-account.cdc"))

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

      client.wait_for_transaction(res.id.unpack1("H*")) do |response|
        expect(response.events.select{ |e| e.type == 'flow.AccountCreated' }).not_to be(nil)
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
