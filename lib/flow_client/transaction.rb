# frozen_string_literal: true
require "flow/entities/transaction_pb"

module FlowClient
  # A Transaction is a full transaction object containing a payload and signatures.
  class Transaction
    TRANSACTION_DOMAIN_TAG = "FLOW-V0.0-transaction"

    Payload = Struct.new(
      :script,
      :arguments,
      :reference_block_id,
      :gas_limit,
      :proposer_address,
      :proposer_key_index,
      :proposer_key_sequence_number,
      :payer_address,
      :authorizer_addresses
    )

    Envelope = Struct.new(
      :payload,
      :payload_signatures
    )

    attr_reader :payload

    def initialize
      client = FlowClient::Client.new("127.0.0.1:3569")
      ref_block_id = client.get_latest_block.block.id.unpack1('H*')
      # ref_block_id = "bf7efe182274e164303d923af96b40f2f2891ec855d44449a5d64859b9562f35"

      puts "ADDRESS: #{Transaction.left_pad_bytes(["e03daebed8ca0615"].pack('H*').bytes, 8)}"

      @payload = Payload.new
      @envelope = Envelope.new
      @envelope_signatures = []
      @payload_signatures = []

      @payload.script = %{
        transaction { 
          prepare(signer: AuthAccount) { log(signer.address) }
        }
      }

      @payload.arguments = []
      @payload.gas_limit = 100
      @payload.proposer_address = Transaction.left_pad_bytes(["045a1763c93006ca"].pack('H*').bytes, 8).pack("C*")
      @payload.proposer_key_index = 0
      @payload.proposer_key_sequence_number = 3
      @payload.payer_address = @payload.proposer_address
      @payload.authorizer_addresses = [@payload.proposer_address]
      @payload.reference_block_id = ref_block_id
    end

    def self.padded_TRANSACTION_DOMAIN_TAG
      bytes = Transaction.left_pad_bytes(TRANSACTION_DOMAIN_TAG.bytes, 32)
      bytes.pack("c*")
    end

    def payload_canonical_form
      [
        @payload.script,
        @payload.arguments,
        [@payload.reference_block_id].pack('H*'),
        @payload.gas_limit,
        @payload.proposer_address,
        @payload.proposer_key_index,
        @payload.proposer_key_sequence_number,
        @payload.payer_address,
        @payload.authorizer_addresses
      ]
    end

    def payload_message
      payload = payload_canonical_form

      example = %w[248 114 176 116 114 97 110 115 97 99 116 105 111 110 32 123 32 101 120 101 99 117 116 101 32 123 32 108 111 103 40 34 72 101 108 108 111 44 32 87 111 114 108 100 33 34 41 32 125 32 125 192 160 72 121 153 246 93 184 142 181 159 21 71 108 105 182 234 79 105 166 51 159 166 79 128 92 248 80 65 251 159 240 90 36 100 136 243 252 210 193 167 143 94 238 128 128 136 243 252 210 193 167 143 94 238 201 136 243 252 210 193 167 143 94 238].map(&:to_i).pack("c*")
      decoded_example = RLP.decode(example)
      # puts "----------"
      # puts decoded_example.inspect
      # puts "----------"
      # puts RLP.decode(RLP.encode(payload)).inspect

      # # puts Transaction.left_pad_bytes(ref_block_id.bytes, 32).pack('i*').inspect
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
      example = %w[248 117 248 114 176 116 114 97 110 115 97 99 116 105 111 110 32 123 32 101 120 101 99 117 116 101 32 123 32 108 111 103 40 34 72 101 108 108 111 44 32 87 111 114 108 100 33 34 41 32 125 32 125 192 160 191 126 254 24 34 116 225 100 48 61 146 58 249 107 64 242 242 137 30 200 85 212 68 73 165 214 72 89 185 86 47 53 100 136 4 90 23 99 201 48 6 202 128 128 136 4 90 23 99 201 48 6 202 201 136 4 90 23 99 201 48 6 202 192].map(&:to_i).pack("c*")
      decoded_example = RLP.decode(example)
      puts "----------"
      puts decoded_example.inspect
      puts RLP.decode(RLP.encode(envelope_canonical_form)).inspect
      puts "----------"

      puts "**********"
      puts "RLP ENCODED ENVELOPE MESSAGE"
      puts "----------------"
      puts RLP.encode(envelope_canonical_form).bytes.inspect
      puts "**********"
      RLP.encode(envelope_canonical_form)
    end

    def signed_payload(address, key_index, signer)
      # tagged_message = envelope_message.bytes << Transaction.padded_TRANSACTION_DOMAIN_TAG
      # puts "**********"

      # puts "**********"
      # message = envelope_message
    end

    def envelope_signature
      tagged_message = Transaction.padded_TRANSACTION_DOMAIN_TAG.bytes + envelope_message.bytes
      tagged_message = tagged_message.pack('C*')
      puts "**********"
      puts "TAGGED ENVELOPE MESSAGE"
      puts "----------------"
      puts tagged_message.inspect
      puts %w[70 76 79 87 45 86 48 46 48 45 116 114 97 110 115 97 99 116 105 111 110 0 0 0 0 0 0 0 0 0 0 0 248 117 248 114 176 116 114 97 110 115 97 99 116 105 111 110 32 123 32 101 120 101 99 117 116 101 32 123 32 108 111 103 40 34 72 101 108 108 111 44 32 87 111 114 108 100 33 34 41 32 125 32 125 192 160 191 126 254 24 34 116 225 100 48 61 146 58 249 107 64 242 242 137 30 200 85 212 68 73 165 214 72 89 185 86 47 53 100 136 4 90 23 99 201 48 6 202 128 128 136 4 90 23 99 201 48 6 202 201 136 4 90 23 99 201 48 6 202 192].map(&:to_i).pack("c*").inspect
      puts "<<<<<<<<<<< **********"

      key = FlowClient::Crypto.key_from_hex_keys(
        '86d466c36c02c9897844057a7435d0ae42b77294433e70ddd8c80e6b162a2489',
        '04c35e9e97bfe10a01b3803631e94c05761515b389f25c43786f7c5886e7d1545dcb1588719aa295b42d459c51e6e25ef25756abd06895d972d3cf78d62608dbd2'
      )

      FlowClient::Crypto.sign(tagged_message, key)
    end

    def to_message
      puts envelope_signature.inspect
      puts %w[201 159 186 250 20 195 169 176 16 128 200 154 50 249 239 220 221 149 255 210 230 181 237 96 56 158 51 241 110 139 34 201 93 88 248 235 55 206 229 231 39 47 106 31 54 122 59 252 171 165 245 9 112 33 175 6 70 180 157 77 148 130 69 225].map(&:to_i).pack("c*").inspect
      sig = Entities::Transaction::Signature.new(
        address: @payload.payer_address,
        key_id: @payload.proposer_key_index,
        signature: envelope_signature
      )

      proposal_key = Entities::Transaction::ProposalKey.new(
        address: @payload.proposer_address,
        key_id: @payload.proposer_key_index,
        sequence_number: @payload.proposer_key_sequence_number
      )

      Entities::Transaction.new(
        script: @payload.script,
        arguments: @payload.arguments,
        reference_block_id: [@payload.reference_block_id].pack('H*'),
        gas_limit: @payload.gas_limit,
        proposal_key: proposal_key,
        payer: @payload.payer_address,
        authorizers: @payload.authorizer_addresses,
        payload_signatures: [],
        envelope_signatures: [sig]
      )
    end

    def self.left_pad_bytes(byte_array, pad_count)
      required_pad_count = pad_count - byte_array.count
      for i in 1..required_pad_count
        byte_array << 0
      end
      byte_array
    end

  end
end
