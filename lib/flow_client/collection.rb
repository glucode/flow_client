# frozen_string_literal: true

module FlowClient
  class Collection
    attr_accessor :id, :transaction_ids

    def initialize
      @id = nil
      @transaction_ids = []
    end

    def self.parse_grpc_type(grpc_type)
      collection = Collection.new
      collection.id = grpc_type.collection.id.unpack1("H*")
      collection.transaction_ids = grpc_type.collection.transaction_ids.to_a.map { |tid| tid.unpack1("H*") }
      collection
    end
  end

  class CollectionGuarantee
    attr_accessor :collection_id, :signatures

    def initialize
      @collection_id = nil
      @signatures = []
    end

    def self.parse_grpc_type(grpc_type)
      collection_guarantee = CollectionGuarantee.new
      collection_guarantee.collection_id = grpc_type.collection_id.unpack1("H*")
      collection_guarantee.signatures = grpc_type.signatures.to_a.map { |s| s.unpack1("H*") }
      collection_guarantee
    end
  end
end
