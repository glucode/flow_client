module FlowClient

  # Represents a block
  class Block
    attr_accessor :id,
                  :parent_id,
                  :height,
                  :timestamp,
                  :collection_guarantees,
                  :block_seals,
                  :signatures
                  
    def initialize
      @id = nil
      @parent_id = nil
      @height = nil
      @timestamp = nil
      @collection_guarantees = []
      @block_seals = []
      @signatures = []
    end

    def self.parse_grpc_block_response(block_response)
      block = Block.new
      block.id = block_response.block.id.unpack1("H*")
      block.parent_id = block_response.block.parent_id.unpack1("H*")
      block.height = block_response.block.height
      block.timestamp = FlowClient::Utils.parse_protobuf_timestamp(block_response.block.timestamp)
      block.collection_guarantees = block_response.block.collection_guarantees.to_a.map { |cg| FlowClient::CollectionGuarantee.parse_grpc_type(cg) }
      block.block_seals = block_response.block.block_seals.to_a.map { |seal| FlowClient::BlockSeal.parse_grpc_type(seal) }
      block.signatures = block_response.block.signatures.to_a.map { |sig| sig.unpack1("H*") }
      block
    end
  end

  # Represents a block seal
  class BlockSeal
    attr_accessor :block_id,
                  :execution_receipt_id,
                  :execution_receipt_signatures,
                  :result_approval_signatures

    def initialize
      @block_id = nil
      @execution_receipt_id = nil
      @execution_receipt_signatures = []
      @result_approval_signatures = []
    end

    def self.parse_grpc_type(grpc_type)
      block_seal = BlockSeal.new
      block_seal.block_id = grpc_type.block_id.unpack1("H*")
      block_seal.execution_receipt_id = grpc_type.execution_receipt_id.unpack1("H*")
      block_seal.execution_receipt_signatures = grpc_type.execution_receipt_signatures.to_a.map { |sig| sig.unpack1("H*") }
      block_seal.result_approval_signatures = grpc_type.result_approval_signatures.to_a.map { |sig| sig.unpack1("H*") }
      block_seal
    end
  end

  # Represents a block header
  class BlockHeader
    attr_accessor :id, :parent_id, :height, :timestamp

    def initialize
    end

    def self.parse_grpc_type(grpc_type)
      header = BlockHeader.new
      header.id = grpc_type.id.unpack1("H*")
      header.height = grpc_type.height
      header.timestamp = FlowClient::Utils.parse_protobuf_timestamp(grpc_type.timestamp)
      header
    end
  end
end