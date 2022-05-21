require 'httparty'

module FlowClient
  class HTTPClient
    include HTTParty

    base_uri 'https://rest-testnet.onflow.org/v1/'

    def get_account(address)
      self.class.get("/accounts/#{address}")
    end

    def get_block(block_id)
      self.class.get("/blocks/#{block_id}")
    end

    def get_transaction(transaction_id)
      self.class.get("/transactions/#{transaction_id}")
    end

    def get_event(event_id)
      self.class.get("/events/#{event_id}")
    end

    def get_proposal_key(proposal_key_id)
      self.class.get("/proposal-keys/#{proposal_key_id}")
    end
  end
end