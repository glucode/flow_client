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
                  :authorizer_addresses
    attr_reader :envelope_signatures

    def initialize
      @authorizer_addresses = []
      @arguments = []
      @script = ""
      @gas_limit = 0
      @envelope_signatures = []
      @proposer_key_index = 0
      @proposer_key_sequence_number = 0
    end

    def self.padded_transaction_domain_tag
      Utils.right_pad_bytes(TRANSACTION_DOMAIN_TAG.bytes, 32).pack("c*")
    end

    def payload_canonical_form
      [
        @script,
        @arguments,
        [@reference_block_id].pack('H*'),
        @gas_limit,
        padded_address(@proposer_address),
        @proposer_key_index,
        @proposer_key_sequence_number,
        padded_address(@payer_address),
        @authorizer_addresses.map { |address| padded_address(address) }
      ]
    end

    def payload_message
      payload = payload_canonical_form
      puts payload.inspect

      # example = %w[248 114 176 116 114 97 110 115 97 99 116 105 111 110 32 123 32 101 120 101 99 117 116 101 32 123 32 108 111 103 40 34 72 101 108 108 111 44 32 87 111 114 108 100 33 34 41 32 125 32 125 192 160 72 121 153 246 93 184 142 181 159 21 71 108 105 182 234 79 105 166 51 159 166 79 128 92 248 80 65 251 159 240 90 36 100 136 243 252 210 193 167 143 94 238 128 128 136 243 252 210 193 167 143 94 238 201 136 243 252 210 193 167 143 94 238].map(&:to_i).pack("c*")
      # decoded_example = RLP.decode(example)
      # puts "----------"
      # puts decoded_example.inspect
      # puts "----------"
      # puts RLP.decode(RLP.encode(payload)).inspect

      # # puts Utils.left_pad_bytes(ref_block_id.bytes, 32).pack('i*').inspect
      # puts RLP.decode(RLP.encode(payload)).inspect
      # ref_block_id = "da8d80c775d75c86064aa0e35a418d02c83cbc198f26d906a4441a90069b63b6"
      # puts [ref_block_id].pack("H*").unpack("C*")
      # puts ["192440c99cb17282"].pack("H*").unpack("C*")
      # # puts RLP.encode(payload).inspect

      # puts RLP.encode(payload).bytes.inspect
      RLP.encode(payload)
    end

    def envelope_canonical_form
      # puts "1 !!!!!!!!!!!!!!!!!!!!!!!!!"
      # puts payload_canonical_form.inspect
      # puts "2 !!!!!!!!!!!!!!!!!!!!!!!!!"
      # puts %w[248 117 248 114 176 116 114 97 110 115 97 99 116 105 111 110 32 123 32 101 120 101 99 117 116 101 32 123 32 108 111 103 40 34 72 101 108 108 111 44 32 87 111 114 108 100 33 34 41 32 125 32 125 192 160 72 121 153 246 93 184 142 181 159 21 71 108 105 182 234 79 105 166 51 159 166 79 128 92 248 80 65 251 159 240 90 36 100 136 243 252 210 193 167 143 94 238 128 128 136 243 252 210 193 167 143 94 238 201 136 243 252 210 193 167 143 94 238 192].map(&:to_i).pack("c*").inspect
      # puts "3 !!!!!!!!!!!!!!!!!!!!!!!!!"
      [
        payload_canonical_form,
        []
      ]
    end

    def envelope_message
      # example = %w[248 117 248 114 176 116 114 97 110 115 97 99 116 105 111 110 32 123 32 101 120 101 99 117 116 101 32 123 32 108 111 103 40 34 72 101 108 108 111 44 32 87 111 114 108 100 33 34 41 32 125 32 125 192 160 191 126 254 24 34 116 225 100 48 61 146 58 249 107 64 242 242 137 30 200 85 212 68 73 165 214 72 89 185 86 47 53 100 136 4 90 23 99 201 48 6 202 128 128 136 4 90 23 99 201 48 6 202 201 136 4 90 23 99 201 48 6 202 192].map(&:to_i).pack("c*")
      # decoded_example = RLP.decode(example)
      # puts "----------"
      # puts decoded_example.inspect
      # puts RLP.decode(RLP.encode(envelope_canonical_form)).inspect
      # puts "----------"

      # puts "**********"
      # puts "RLP ENCODED ENVELOPE MESSAGE"
      # puts "----------------"
      # puts RLP.encode(envelope_canonical_form).bytes.inspect
      # puts "**********"
      envelope = envelope_canonical_form
      RLP.encode(envelope_canonical_form)
    end

    def add_envelope_signature(signer_address, key_index, key)
      domain_tagged_payload = (Transaction.padded_transaction_domain_tag.bytes + envelope_message.bytes).pack('C*')

      @envelope_signatures << Entities::Transaction::Signature.new(
        address: padded_address(signer_address),
        key_id: key_index,
        signature: FlowClient::Crypto.sign(domain_tagged_payload, key)
      )
    end

    def to_protobuf_message
      payload = payload_canonical_form
      # puts envelope_signature.inspect
      # puts %w[201 159 186 250 20 195 169 176 16 128 200 154 50 249 239 220 221 149 255 210 230 181 237 96 56 158 51 241 110 139 34 201 93 88 248 235 55 206 229 231 39 47 106 31 54 122 59 252 171 165 245 9 112 33 175 6 70 180 157 77 148 130 69 225].map(&:to_i).pack("c*").inspect

      proposal_key = Entities::Transaction::ProposalKey.new(
        address: payload[4],
        key_id: payload[5],
        sequence_number: payload[6]
      )

      Entities::Transaction.new(
        script: payload[0],
        arguments: payload[1],
        reference_block_id: payload[2],
        gas_limit: payload[3],
        proposal_key: proposal_key,
        payer: payload[7],
        authorizers: payload[8],
        payload_signatures: [],
        envelope_signatures: @envelope_signatures
      )
    end

    protected

    def padded_address(address_hex_string)
      Utils.left_pad_bytes([address_hex_string].pack('H*').bytes, 8).pack("C*")
    end
  end
end
