module FlowClient
  class EventsResult
    attr_accessor :block_id,
                  :block_height,
                  :events,
                  :block_timestamp

    def initialize
      @block_id = nil
      @block_height = nil
      @events = nil
      @block_timestamp= nil
    end

    def self.parse_grpc_type(type)
      event = EventsResult.new
      event.block_id = type.block_id.unpack1("H*")
      event.block_height = type.block_height
      event.block_timestamp = FlowClient::Utils.parse_protobuf_timestamp(type.block_timestamp)
      event.events = type.events.map { |event| FlowClient::Event.parse_grpc_type(event) }
      event
    end
  end

  class Event
    attr_accessor :type,
                  :transaction_id,
                  :transaction_index,
                  :event_index,
                  :payload
                  
    def initialize
      @type = nil
      @transaction_id = nil
      @transaction_index = nil
      @event_index = nil
      @payload = nil
    end

    def self.parse_grpc_type(type)
      event = Event.new
      event.type = type.type
      event.transaction_id = type.transaction_id.unpack1("H*")
      event.transaction_index = type.transaction_index
      event.event_index = type.event_index
      event.payload = type.payload
      event
    end
  end
end