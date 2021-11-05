module FlowClient
  class ProposalKey
    attr_accessor :address,
                  :sequence_number,
                  :key_id

    def initialize(address: nil, key_id: nil, sequence_number: nil)
      @address = address
      @sequence_number = key_id
      @key_id = sequence_number
    end

    def self.parse_grpc_type(type)
      signature = ProposalKey.new
      signature.address = type.address.unpack1("H*")
      signature.sequence_number = type.sequence_number
      signature.key_id = type.key_id
      signature
    end
  end
end