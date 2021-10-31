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
                  :proposer_address,
                  :proposer_key_index,
                  :proposer_key_sequence_number,
                  :payer_address,
                  :authorizer_addresses,
                  :address_aliases

    attr_reader :envelope_signatures, :payload_signatures

    def initialize
      @authorizer_addresses = []
      @arguments = []
      @script = ""
      @gas_limit = 0
      @envelope_signatures = []
      @payload_signatures = []
      @proposer_address = nil
      @proposer_key_index = 0
      @proposer_key_sequence_number = 0
      @address_aliases = {}
      @signers = {}
    end

    def self.padded_transaction_domain_tag
      Utils.right_pad_bytes(TRANSACTION_DOMAIN_TAG.bytes, 32).pack("c*")
    end

    def payload_canonical_form
      [
        resolved_script, @arguments,
        [@reference_block_id].pack("H*"), @gas_limit,
        padded_address(@proposer_address), @proposer_key_index,
        @proposer_key_sequence_number, padded_address(@payer_address),
        @authorizer_addresses.map { |address| padded_address(address) }
      ]
    end

    def payload_message
      payload = payload_canonical_form
      RLP.encode(payload)
    end

    def envelope_canonical_form
      @signers[@proposer_address] = 0

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

    protected

    def resolved_script
      FlowClient::Utils.substitute_address_aliases(@script, @address_aliases)
    end

    def padded_address(address_hex_string)
      Utils.left_pad_bytes([address_hex_string].pack("H*").bytes, 8).pack("C*")
    end
  end
end
