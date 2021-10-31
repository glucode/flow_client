[![Gem Version](https://badge.fury.io/rb/flow_client.svg)](https://badge.fury.io/rb/flow_client)
![RSpec Tests](https://github.com/glucode/flow_client/actions/workflows/ruby.yml/badge.svg)

# FlowClient

FlowClient is a Ruby gRPC client for Flow (onflow.org)

#### Features

Blocks:
- [x] retrieve a block by ID
- [x] retrieve a block by height
- [x] retrieve the latest block

Collections:
- [x] retrieve a collection by ID 

Events:
- [x] retrieve events by name in the block height range

Scripts:
- [x] submit a script and parse the response
- [x] submit a script with arguments
- [x] create a script that returns complex structure and parse the response

Accounts:
- [x] retrieve an account by address
- [x] create a new account
- [x] deploy a new contract to the account
- [x] remove a contract from the account
- [x] update an existing contract on the account

Transactions: 
- [x] retrieve a transaction by ID
- [x] sign a transaction with same payer, proposer and authorizer
- [x] sign a transaction with different payer and proposer
- [x] sign a transaction with different authorizers using sign method multiple times
- [x] submit a signed transaction
- [x] sign a transaction with arguments and submit it


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
res = client.ping
```

### Blocks

#### Retrieve a block by ID
```ruby
latest_block = client.get_latest_block
res = client.get_block_by_id(latest_block.block.id.unpack1("H*"))
```

#### Retrieve a block by height
```ruby
latest_block = client.get_latest_block
res = client.get_block_by_height(latest_block.block.height)
```

#### Retrieve the latest block
```ruby
latest_block = client.get_latest_block
```

### Collections

#### Retrieve a collection by ID

```ruby
latest_block = client.get_latest_block
cid = latest_block.block.collection_guarantees.first.collection_id.unpack1("H*")
res = client.get_collection_by_id(cid)
```

### Events

```ruby
# get_events(type, start_height, end_height)
res = client.get_events("A.0b2a3299cc857e29.TopShot.Deposit", 12913388, 12913389)
```

### Scripts

```ruby
# execute_script(cadence_string, args_array)
args = [{ type: "Address", value: "0xAlice" }.to_json]
# Execute a Cadence script
res = client.execute_script(script, args)
```

### Accounts

#### Create account
```ruby
# get_account(account_address)
res = client.get_account("0xAlice")
```

#### Get account
```ruby
# get_account(account_address)
res = client.get_account("0xAlice")
```

#### Add contract
```ruby
contract_code = "..."
signer = FlowClient::LocalSigner.new(service_account_private_key)
payer = FlowClient::Account.new(address: service_account_address)
client.add_contract("ContractName", contract_code, payer, signer)
```

#### Update contract
```ruby
contract_code = "..."
signer = FlowClient::LocalSigner.new(service_account_private_key)
payer = FlowClient::Account.new(address: service_account_address)
client.update_contract("ContractName", contract_code, payer, signer)
```

#### Remove contract
```ruby
signer = FlowClient::LocalSigner.new(service_account_private_key)
payer = FlowClient::Account.new(address: service_account_address)
client.remove_contract("ContractName", payer, signer)
```

### Transactions

#### Get transaction result

```ruby
# Get a transaction result
# get_transaction_result(transaction_id)
client.get_transaction_result(res.id.unpack("H*"))
```

#### Single signer, proposer and authorizer

```ruby
service_account_address = "f8d6e0586b0a20c7"
service_account_key = client.get_account(service_account_address).keys.first

arguments = [{ type: "String", value: "Hello world!" }.to_json]

transaction = FlowClient::Transaction.new
transaction.script = script
transaction.reference_block_id = reference_block_id
transaction.gas_limit = 100
transaction.proposer_address = service_account_address
transaction.proposer_key_index = service_account_key.index
transaction.arguments = arguments
transaction.proposer_key_sequence_number = service_account_key.sequence_number
transaction.payer_address = service_account_address
transaction.authorizer_addresses = [service_account_address]

# Only the envelope needs to be signed in this special case
signer = FlowClient::LocalSigner.new(service_account_private_key)
transaction.add_envelope_signature(service_account_address, 0, signer)

tx = client.send_transaction(transaction)
client.wait_for_transaction(tx.id.unpack1("H*")) do |result|
  puts result.inspect
end
```

#### Sign a transaction with different payer and proposer

```ruby
service_account_address = "f8d6e0586b0a20c7"
service_account_key = client.get_account(service_account_address).keys.first

service_account = client.get_account(service_account_address)
payer_signer = FlowClient::LocalSigner.new(service_account_private_key)

# Create a new account that will be executing the transaction
authorizer_priv_key, authorizer_pub_key = FlowClient::Crypto.generate_key_pair
new_account = client.create_account(authorizer_pub_key, service_account, payer_signer)
authorizer_signer = FlowClient::LocalSigner.new(
  authorizer_priv_key
)

arguments = [{ type: "String", value: "Hello world!" }.to_json]

transaction = FlowClient::Transaction.new
transaction.script = script
transaction.reference_block_id = reference_block_id
transaction.gas_limit = 100
transaction.proposer_address = service_account_address
transaction.proposer_key_index = service_account_key.index
transaction.arguments = arguments
transaction.proposer_key_sequence_number = service_account_key.sequence_number
transaction.payer_address = service_account_address
transaction.authorizer_addresses = [service_account_address]

# The authorizer signs the payload
transaction.add_payload_signature(new_account.address, new_account.keys.first.index, authorizer_signer)

# The payer signs the envelope
transaction.add_envelope_signature(service_account_address, service_account.keys.first.index, payer_signer)

tx = client.send_transaction(transaction)
client.wait_for_transaction(tx.id.unpack1("H*")) do |result|
  puts result.inspect
end
```

#### Sign a transaction with different authorizers using sign method multiple times

```ruby
service_account_address = "f8d6e0586b0a20c7"
service_account_key = client.get_account(service_account_address).keys.first

arguments = [{ type: "String", value: "Hello world!" }.to_json]

priv_key_one, pub_key_one = FlowClient::Crypto.generate_key_pair
priv_key_two, pub_key_two = FlowClient::Crypto.generate_key_pair

payer_signer = FlowClient::LocalSigner.new(service_account_private_key)
payer_account = FlowClient::Account.new(address: service_account_address)
new_account = client.create_account(pub_key_one, payer_account, payer_signer)

auth_signer_one = FlowClient::LocalSigner.new(priv_key_one)
auth_signer_two = FlowClient::LocalSigner.new(priv_key_two)
client.add_account_key(new_account.address, pub_key_two, new_account, auth_signer_one, 1000.0)

new_account = client.get_account(new_account.address)

@transaction = FlowClient::Transaction.new
@transaction.script = script
@transaction.reference_block_id = client.get_latest_block.block.id.unpack1("H*")
@transaction.gas_limit = gas_limit
@transaction.proposer_address = new_account.address
@transaction.proposer_key_index = new_account.keys[0].index
@transaction.arguments = arguments
@transaction.proposer_key_sequence_number = new_account.keys[0].sequence_number
@transaction.payer_address = new_account.address
@transaction.authorizer_addresses = [new_account.address]
@transaction.add_envelope_signature(new_account.address, new_account.keys[0].index, auth_signer_one)
@transaction.add_envelope_signature(new_account.address, new_account.keys[1].index, auth_signer_two)
tx_res = client.send_transaction(@transaction)
client.wait_for_transaction(tx_res.id.unpack1("H*")) do |response|
  expect(response.status_code).to eq(0)
end
```

## Tests

Running the tests require the emulator to be started.

```
docker-compose up
bundle exec rspec
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
