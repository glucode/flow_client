module FlowClient

  # An abstract super class for the transaction signers. Subclasses must
  # implement the sign method to sign transactions.
  class Signer
    def sign

    end
  end

  # Implements a local singer using an in-memory key.
  class LocalSigner < Signer
    def initialize(private_key)
      @private_key = private_key
    end

    def sign(data)
      FlowClient::Crypto.sign(data, @private_key)
    end
  end
end