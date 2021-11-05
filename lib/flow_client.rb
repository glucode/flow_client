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
  require "flow_client/block"
  require "flow_client/collection"
  require "flow_client/signer"
  require "flow_client/proposal_key"
  require "flow_client/event"
  require "flow_client/cadence_type.rb"
  require "flow_client/signature"
end
