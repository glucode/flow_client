# frozen_string_literal: true

require_relative "flow_client/version"
require "openssl"
require "rlp"

# Collection of classes to interact with the Flow blockchain
module FlowClient
  class Error < StandardError; end
  require "flow_client/crypto"
  require "flow_client/utils"
  require "flow_client/client"
  require "flow_client/transaction"
  require "flow_client/account"
  require "flow_client/signer"
end
