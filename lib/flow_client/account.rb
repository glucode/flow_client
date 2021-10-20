module FlowClient
  class AccountKey
    attr_accessor :public_key,
                  :index, :sequence_number,
                  :sign_algo, :hash_algo,
                  :weight, :revoked

    def initialize(public_key: nil, index: nil, sequence_number: nil, weight: 1000, revoked: false)
      @public_key = public_key
      @index = index
      @sequence_number = sequence_number
      @weight = weight
      @revoked = revoked
    end
  end

  class Account
    attr_accessor :address, :balance, :keys

    def initialize(address: nil, balance: nil, keys: [])
      @keys = keys
      @address = address
      @balance = balance
    end
  end
end