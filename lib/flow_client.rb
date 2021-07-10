# frozen_string_literal: true

require_relative "flow_client/version"

# Collection of classes to interact with the Flow blockchain
module FlowClient
  class Error < StandardError; end
  # Your code goes here...
  require "flow_client/client"
end
