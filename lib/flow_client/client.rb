require 'flow/access/access_services_pb'
require 'flow/execution/execution_services_pb'
require 'json'

module FlowClient
  class Client
    def initialize(node_address)
      @stub = Access::AccessAPI::Stub.new(node_address, :this_channel_is_insecure)
    end
  
    def ping
      req = Access::PingRequest.new
      @stub.ping(req)
    end
  
    def get_account(address)
      req = Access::GetAccountAtLatestBlockRequest.new(address: to_bytes(address))
      res = @stub.get_account_at_latest_block(req)
      res.account
    end
  
    def execute_script(script, args = [])
      req = Access::ExecuteScriptAtLatestBlockRequest.new(
          script: script, 
          arguments: args
      )
      res = @stub.execute_script_at_latest_block(req)
      parse_json(res.value)
    end
  
    # Blocks
  
    def get_latest_block(is_sealed = true)
      req = Access::GetLatestBlockRequest.new(
        is_sealed:  is_sealed
      )
  
      res = @stub.get_latest_block(req)
      res
    end
  
    # Events
  
    def get_events(type, start_height, end_height)
      req = Access::GetEventsForHeightRangeRequest.new(
        type: type,
        start_height: start_height,
        end_height: end_height
      )
      res = @stub.get_events_for_height_range(req)
    end

    def hello
      puts "Hello"
    end
  
    private
  
    def parse_json(event_payload)
      JSON.parse(event_payload, object_class: OpenStruct)
    end
  
    def to_bytes(string)
      [string].pack('H*')
    end
  
    def to_string(bytes)
      bytes.unpack('H*').first
    end
  end
end