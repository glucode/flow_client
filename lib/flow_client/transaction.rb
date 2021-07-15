# frozen_string_literal: true
require "flow/entities/transaction_pb"

module FlowClient
  # A Transaction is a full transaction object containing a payload and signatures.
  class Transaction
    DOMAIN_TAG = "FLOW-V0.0-transaction"

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
      @payload = Payload.new
      @envelope = Envelope.new
      @envelope_signatures = []
      @payload_signatures = []
    end

    def self.padded_domain_tag
      bytes = Transaction.left_pad_bytes(DOMAIN_TAG.bytes, 32)
      bytes.pack("c*")
    end

    def payload_canonical_form
      script = "\n            transaction { \n                prepare(signer: AuthAccount) { log(signer.address) }\n            }\n        "

      gas_limit = 100

      arguments = []
      # puts arguments = {}.to_json.bytes

      # puts script.bytes
      ref_block_id = "fcda9a61596251b2bfe20b0d510921b0dac99f0794f1645ad0a0fff5750a9804"
      # puts Transaction.left_pad_bytes(ref_block_id.bytes, 32)

      address = ["01cf0e2f2f715450"].pack("H*")

      payload = [
        script,
        arguments,
        [ref_block_id].pack("H*"),
        gas_limit,
        address,
        0,
        0,
        address,
        [address]
      ]
    end

    def payload_message
      payload = payload_canonical_form

      # example = %w[248 186 184 119 10 32 32 32 32 32 32 32 32 32 32 32 32 116 114 97 110 115 97 99 116 105 111 110 32 123 32 10 32 32 32 32 32 32 32 32 32 32 32 32 32 32 32 32 112 114 101 112 97 114 101 40 115 105 103 110 101 114 58 32 65 117 116 104 65 99 99 111 117 110 116 41 32 123 32 108 111 103 40 115 105 103 110 101 114 46 97 100 100 114 101 115 115 41 32 125 10 32 32 32 32 32 32 32 32 32 32 32 32 125 10 32 32 32 32 32 32 32 32 192 160 63 121 162 22 110 78 24 218 96 97 59 50 199 220 202 201 20 229 187 187 202 30 165 210 217 22 116 81 129 102 221 254 100 136 235 23 156 39 20 79 120 60 128 128 136 235 23 156 39 20 79 120 60 201 136 235 23 156 39 20 79 120 60].map(&:to_i).pack("c*")
      # decoded_example = RLP.decode(example)
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
      [
        payload_canonical_form,
        []
      ]
    end

    def envelope_message
      # example = %w[248 189 248 186 184 119 10 32 32 32 32 32 32 32 32 32 32 32 32 116 114 97 110 115 97 99 116 105 111 110 32 123 32 10 32 32 32 32 32 32 32 32 32 32 32 32 32 32 32 32 112 114 101 112 97 114 101 40 115 105 103 110 101 114 58 32 65 117 116 104 65 99 99 111 117 110 116 41 32 123 32 108 111 103 40 115 105 103 110 101 114 46 97 100 100 114 101 115 115 41 32 125 10 32 32 32 32 32 32 32 32 32 32 32 32 125 10 32 32 32 32 32 32 32 32 192 160 252 218 154 97 89 98 81 178 191 226 11 13 81 9 33 176 218 201 159 7 148 241 100 90 208 160 255 245 117 10 152 4 100 136 1 207 14 47 47 113 84 80 128 128 136 1 207 14 47 47 113 84 80 201 136 1 207 14 47 47 113 84 80 192].map(&:to_i).pack("c*")
      # decoded_example = RLP.decode(example)
      # puts "----------"
      # puts decoded_example.inspect
      # puts RLP.decode(RLP.encode(envelope_canonical_form)).inspect
      # puts "----------"
       
      # puts "**********"
      # puts "ENVELOPE MESSAGE"
      # puts "----------------"
      # puts RLP.encode(envelope_canonical_form).bytes.inspect
      # puts "**********"
      RLP.encode(envelope_canonical_form)
      # Transaction.padded_domain_tag << RLP.encode(envelope_canonical_form)
    end

    def signed_payload(address, key_index, signer)
      # tagged_message = envelope_message.bytes << Transaction.padded_domain_tag
      # puts "**********"

      # puts "**********"
      # message = envelope_message

    end

    def signed_envelope()
      tagged_message = Transaction.padded_domain_tag.bytes + envelope_message.bytes
      tagged_message = tagged_message.pack('C*')
      # puts "**********"
      # puts "TAGGED ENVELOPE MESSAGE"
      # puts "----------------"
      # puts tagged_message.bytes.inspect
      # puts "**********"

      key = FlowClient::Crypto.key_from_hex_keys(
        '96ccb4d1856d18d5aed93abf558e2235e1226fa1fc5010a1bc48278b70115317',
        '040be797c6f1eb6ac8eda984493c4a159d6b016e9a6e6808280b1c5f08ab319687d4eb0750d61fdeed919a76719d43a2edc230abad05ec9f6413c63f5c2b6690e5'
      )

      FlowClient::Crypto.sign(tagged_message, key)
    end

    def to_message
      script = %{
        transaction {
          prepare(signer: AuthAccount) { log(signer.address) }
        }
      }

      address = ["01cf0e2f2f715450"].pack('H*')
      reference_block_id = [@payload.reference_block_id].pack('H*')

      puts "<<<<< &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n\n"
      puts signed_envelope.inspect
      # puts signed_envelope.inspect
      puts "<<<<< &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n\n"

      envelope_signature = Entities::Transaction::Signature.new(
        address: address,
        key_id: 0,
        signature: [signed_envelope].pack("H*")
      )

      proposal_key = Entities::Transaction::ProposalKey.new(
        address: address,
        key_id: 0,
        sequence_number: 0
      )

      Entities::Transaction.new(
        script: script,
        arguments: [],
        reference_block_id: reference_block_id,
        gas_limit: 100,
        proposal_key: proposal_key,
        payer: address,
        authorizers: [address],
        payload_signatures: [],
        envelope_signatures: [envelope_signature]
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
