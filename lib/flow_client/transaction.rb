# frozen_string_literal: true

require "flow/entities/transaction_pb"
require "openssl"
require "rlp"

module FlowClient
  # A Transaction is a full transaction object containing a payload and signatures.
  class Transaction
    TRANSACTION_DOMAIN_TAG = "FLOW-V0.0-transaction"

    attr_accessor :script,
                  :arguments,
                  :reference_block_id,
                  :gas_limit,
                  :payer_address,
                  :authorizer_addresses,
                  :address_aliases,
                  :envelope_signatures,
                  :payload_signatures,
                  :proposal_key

    attr_reader :envelope_signatures, :payload_signatures

    def initialize
      @authorizer_addresses = []
      @arguments = []
      @script = ""
      @gas_limit = 999
      @envelope_signatures = []
      @payload_signatures = []
      @address_aliases = {}
      @signers = {}
      @proposal_key = ProposalKey.new
    end

    def arguments=(arguments)
      arguments.to_a.each do |arg|
        processed_arg = arg.class == OpenStruct ? Utils.openstruct_to_json(arg) : arg
        @arguments << processed_arg
      end
    end

    def proposer_address=(address)
      @proposal_key.address = address
    end

    def proposer_key_index=(index)
      @proposal_key.key_id = index
    end

    def proposer_key_sequence_number=(sequence_number)
      @proposal_key.sequence_number = sequence_number
    end

    def self.padded_transaction_domain_tag
      Utils.right_pad_bytes(TRANSACTION_DOMAIN_TAG.bytes, 32).pack("c*")
    end

    def add_envelope_signature(signer_address, key_index, signer)
      domain_tagged_envelope = (Transaction.padded_transaction_domain_tag.bytes + envelope_message.bytes).pack("C*")

      @envelope_signatures << Entities::Transaction::Signature.new(
        address: padded_address(signer_address),
        key_id: key_index,
        signature: signer.sign(domain_tagged_envelope)
      )
    end

    def add_payload_signature(signer_address, key_index, signer)
      domain_tagged_payload = (Transaction.padded_transaction_domain_tag.bytes + payload_message.bytes).pack("C*")

      @payload_signatures << Entities::Transaction::Signature.new(
        address: padded_address(signer_address),
        key_id: key_index,
        signature: signer.sign(domain_tagged_payload)
      )
    end

    def to_protobuf_message
      payload = payload_canonical_form

      proposal_key = Entities::Transaction::ProposalKey.new(
        address: payload[4],
        key_id: payload[5],
        sequence_number: payload[6]
      )

      Entities::Transaction.new(script: payload[0], arguments: payload[1],
                                reference_block_id: payload[2], gas_limit: payload[3], proposal_key: proposal_key,
                                payer: payload[7], authorizers: payload[8], payload_signatures: @payload_signatures,
                                envelope_signatures: @envelope_signatures)
    end

    def self.parse_grpc_type(type)
      tx = Transaction.new
      tx.script = type.script
      tx.arguments = type.arguments
      tx.reference_block_id = type.reference_block_id.unpack1("H*")
      tx.gas_limit = type.gas_limit
      tx.authorizer_addresses = type.authorizers.map { |address| address.unpack1("H*") }
      tx.envelope_signatures = type.envelope_signatures.map { |sig| Signature.parse_grpc_type(sig) }
      tx.payload_signatures = type.payload_signatures.map { |sig| Signature.parse_grpc_type(sig) }
      tx.proposal_key = ProposalKey.parse_grpc_type(type.proposal_key)
      tx.payer_address = type.payer.unpack1("H*")
      tx
    end

    protected

    def resolved_script
      FlowClient::Utils.substitute_address_aliases(@script, @address_aliases)
    end

    def padded_address(address_hex_string)
      Utils.left_pad_bytes([address_hex_string].pack("H*").bytes, 8).pack("C*")
    end

    def payload_canonical_form
      [
        resolved_script, @arguments,
        [@reference_block_id].pack("H*"), @gas_limit,
        padded_address(@proposal_key.address), @proposal_key.key_id,
        @proposal_key.sequence_number, padded_address(@payer_address),
        @authorizer_addresses.map { |address| padded_address(address) }
      ]
    end

    def payload_message
      payload = payload_canonical_form
      RLP.encode(payload)
    end

    def envelope_canonical_form
      @signers[@proposal_key.address] = 0

      @payload_signatures.each do |sig|
        @signers[sig.address] = @signers.keys.count
      end

      signatures = []
      @payload_signatures.each do |sig|
        signatures << [
          @signers[sig.address.unpack1("H*")],
          sig.key_id,
          sig.signature
        ]
      end

      [
        payload_canonical_form,
        signatures
      ]
    end

    def envelope_message
      RLP.encode(envelope_canonical_form)
    end

    def payload_message
      RLP.encode(payload_canonical_form)
    end
  end

  class TransactionResult
    attr_accessor :status,
                  :status_code,
                  :error_message,
                  :events,
                  :block_id

    def self.parse_grpc_type(type)
      result = TransactionResult.new
      result.block_id = type.block_id.unpack1("H*")
      result.status = type.status
      result.status_code = type.status_code
      result.error_message = type.error_message
      result.events = type.events.to_a.map { |event| FlowClient::Event.parse_grpc_type(event) }
      result
    end
  end

  class TransactionResponse
    attr_accessor :id

    def self.parse_grpc_type(type)
      response = TransactionResponse.new
      response.id = type.id.unpack1("H*")
      response
    end
  end
end