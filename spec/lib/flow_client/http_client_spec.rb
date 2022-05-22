# frozen_string_literal: true
require 'webmock'
include WebMock::API

RSpec.describe FlowClient::HTTPClient do
  describe "get_account" do
    before(:each) do
      multiline = <<-TEXT
        {
          "address": "string",
          "balance": "string",
          "keys": [
            {
              "index": "string",
              "public_key": "string",
              "signing_algorithm": "BLSBLS12381",
              "hashing_algorithm": "SHA2_256",
              "sequence_number": "string",
              "weight": "string",
              "revoked": true
            }
          ],
          "contracts": {
            "property1": "string",
            "property2": "string"
          },
          "_expandable": {
            "keys": "string",
            "contracts": "string"
          },
          "_links": {
            "_self": "string"
          }
        }
        TEXT

        stub_request(:get, "https://rest-testnet.onflow.org/v1/accounts/0x0000000000000000000000000000000000000001").
        with(
          headers: {
         'Accept'=>'*/*',
         'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
         'User-Agent'=>'Ruby'
          }).
        to_return(status: 200, body: multiline, headers: { 'Content-type': 'application/json' })

    end

    it "returns an account" do
      account = FlowClient::HTTPClient.new.get_account("0x0000000000000000000000000000000000000001")
      expect(account).to be_a(FlowClient::Account)
    end

    it "parses the address" do
      account = FlowClient::HTTPClient.new.get_account("0x0000000000000000000000000000000000000001")
      expect(account.address).to eq("string")
    end
  end
end