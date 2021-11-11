# frozen_string_literal: true

module FlowClient
  class Signature
    attr_accessor :address,
                  :signature,
                  :key_id

    def initialize
      @address = nil
      @signature = nil
      @key_id = nil
    end

    def self.parse_grpc_type(pb_signature)
      signature = Signature.new
      signature.address = pb_signature.address.unpack1("H*")
      signature.signature = pb_signature.signature.unpack1("H*")
      signature.key_id = pb_signature.key_id
      signature
    end
  end
end
