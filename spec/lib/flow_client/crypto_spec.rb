# frozen_string_literal: true

RSpec.describe FlowClient::Transaction do
  describe "key import" do
    let(:key) do
      FlowClient::Crypto.key_from_hex_keys(
        "81c9655ca2affbd3421c90a1294260b62f1fd4e9aaeb70da4b9185ebb4f4a26b"
      )
    end

    it "imports a key a hex string key pair for prime256v1" do
      expect(key.private?).to eq(true)
    end

    it "imports a key a hex string key pair for prime256v1" do
      expect(key.private?).to eq(true)
    end
  end

  describe "key generation" do
    it "generates valid prime256v1 keys" do
      private_key, _public_key = FlowClient::Crypto.generate_key_pair(FlowClient::Crypto::Curves::P256)
      openssl_key = FlowClient::Crypto.key_from_hex_keys(
        private_key
      )
      expect(openssl_key).to be_a(OpenSSL::PKey::EC)
    end

    it "generates valid secp256k1 keys" do
      private_key, _public_key = FlowClient::Crypto.generate_key_pair(FlowClient::Crypto::Curves::SECP256K1)
      openssl_key = FlowClient::Crypto.key_from_hex_keys(
        private_key,
        FlowClient::Crypto::Curves::SECP256K1
      )
      expect(openssl_key).to be_a(OpenSSL::PKey::EC)
    end

    it "strips the uncompressed header" do
      _private_key, public_key = FlowClient::Crypto.generate_key_pair(FlowClient::Crypto::Curves::P256)
      expect(public_key[0..1]).not_to eq("04")
      expect(public_key.length).to eq(128)
    end
  end
end
