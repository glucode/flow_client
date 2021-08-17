# FlowClient

FlowClient is a Ruby gRPC client for the Flow blockchain (onflow.org)

- [x] Ping the blockchain
- [x] Get account information
- [x] Execute a script
- [x] Single signature transactions
- [ ] Multi signature transactions
- [ ] secp256k1 keys
- [x] prime256v1 keys

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'flow_client'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install flow_client

## Usage

```ruby
# Connect to the Flow testnet
client = FlowClient::Client.new("access.devnet.nodes.onflow.org:9000")

# Ping the blockchain
res = client.ping

# Execute a Cadence script
res = client.execute_script(script, args)
```

### Transactions

```ruby
transaction = FlowClient::Transaction.new
transaction.script = cadence
transaction.reference_block_id = ref_block_id
transaction.proposer_address = "0xAlice"
transaction.proposer_key_index = 0
transaction.arguments = [
  { type: "Address", value: user_address }.to_json
]
transaction.proposer_key_sequence_number = sequence_number
transaction.payer_address = "76ecd94a2bb02327"
transaction.authorizer_addresses = ["0xAlice"]
transaction.add_envelope_signature("0xAlice", 0, key)
res = client.send_transaction(transaction)
```

### Address alias resolution

Using address aliases is handy for switching between different environments.

```ruby
cadence =  %{
    import FungibleToken from 0xFungibleToken
    
    ...
}

client.address_aliases = { "0xFungibleToken": "0x123234545" }

# 0xFungibleToken get resolved to the address "0x123234545"
res = client.execute_script(cadence)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/glucode/flow_client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/flow_client/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the FlowClient project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/flow_client/blob/master/CODE_OF_CONDUCT.md).
