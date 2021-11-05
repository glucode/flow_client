# frozen_string_literal: true

module FlowClient
  class AccountKey
    attr_accessor :public_key,
                  :index, :sequence_number,
                  :sign_algo, :hash_algo,
                  :weight, :revoked

    def initialize(public_key: nil, index: nil, sequence_number: nil, weight: 1000, revoked: false, hash_algo: FlowClient::Crypto::HashAlgos::SHA3_256)
      @public_key = public_key
      @index = index
      @sequence_number = sequence_number
      @weight = weight
      @revoked = revoked
      @hash_algo = hash_algo
    end
  end

  class Account
    attr_accessor :address, :balance, :keys, :contracts

    def initialize(address: nil, balance: nil, keys: [], contracts: {})
      @keys = keys
      @address = address
      @balance = balance
      @contracts = {}
    end
  end
end
