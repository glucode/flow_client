module FlowClient
  class Signer
    def sign

    end
  end

  class LocalSigner < Signer
    def initialize(private_key)
      @private_key = private_key
    end

    def sign(data)
      FlowClient::Crypto.sign(data, @private_key)
    end
  end

  class GoogleKMSSigner
  end
end