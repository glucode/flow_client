# frozen_string_literal: true

require "openssl"

module FlowClient
  # Crypto helpers
  class Crypto
    module Curves
      P256 = "prime256v1"
      SECP256K1 = "secp256k1"
    end

    # Sign data using the provided key
    def self.sign(data, key)
      asn = key.dsa_sign_asn1(OpenSSL::Digest.digest("SHA3-256", data))
      r, s = OpenSSL::ASN1.decode(asn).value
      combined_bytes = Utils.left_pad_bytes([r.value.to_s(16)].pack("H*").unpack("C*"), 32) +
                       Utils.left_pad_bytes([s.value.to_s(16)].pack("H*").unpack("C*"), 32)
      combined_bytes.pack("C*")
    end

    # Constructs an OpenSSL::PKey::EC key from an octet string
    # keypair.
    #
    # secp256k1
    # prime256v1
    def self.key_from_hex_keys(private_hex, algo = Curves::P256)
      group = OpenSSL::PKey::EC::Group.new(algo)
      new_key = OpenSSL::PKey::EC.new(group)
      new_key.private_key = OpenSSL::BN.new(private_hex, 16)
      new_key.public_key = group.generator.mul(new_key.private_key)
      new_key
    end

    # Returns an octet string keypair.
    #
    # Supported ECC curves are:
    # Crypto::Curves::P256
    # Crypto::Curves::SECP256K1
    #
    # The 04 prefix indicating that the public key is uncompressed is stripped.
    # https://datatracker.ietf.org/doc/html/rfc5480
    #
    # Usage example:
    # private_key, public_key = FlowClient::Crypto.generate_key(FlowClient::Crypto::Curves::P256)
    def self.generate_key(curve = Curves::P256)
      key = OpenSSL::PKey::EC.new(curve).generate_key
      public_key = key.public_key.to_bn.to_s(16).downcase
      [
        key.private_key.to_s(16).downcase,
        public_key[2..public_key.length]
      ]
    end
  end
end
