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
      digest = OpenSSL::Digest.digest("SHA3-256", data)
      asn = key.dsa_sign_asn1(digest)
      asn1 = OpenSSL::ASN1.decode(asn)
      r, s = asn1.value
      combined_bytes = Utils.left_pad_bytes([r.value.to_s(16)].pack("H*").unpack("C*"), 32) +
                       Utils.left_pad_bytes([s.value.to_s(16)].pack("H*").unpack("C*"), 32)
      combined_bytes.pack("C*")
    end

    # Constructs an OpenSSL::PKey::EC key from an octet string
    # keypair.
    #
    # secp256k1
    # prime256v1
    def self.key_from_hex_keys(private_hex, public_hex, algo = Curves::P256)
      asn1 = OpenSSL::ASN1::Sequence(
        [
          OpenSSL::ASN1::Integer(1),
          OpenSSL::ASN1::OctetString([private_hex].pack("H*")),
          OpenSSL::ASN1::ObjectId(algo, 0, :EXPLICIT),
          OpenSSL::ASN1::BitString([public_hex].pack("H*"), 1, :EXPLICIT)
        ]
      )

      OpenSSL::PKey::EC.new(asn1.to_der)
    end

    # Returns an octet string keypair.
    #
    # Supported ECC curves are:
    # Crypto::Curves::P256
    # Crypto::Curves::SECP256K1
    #
    # Usage example:
    # private_key, public_key = FlowClient::Crypto.generate_keys(FlowClient::Crypto::Curves::P256)
    def self.generate_keys(curve)
      key = OpenSSL::PKey::EC.new(curve).generate_key
      [
        key.private_key.to_s(16).downcase,
        key.public_key.to_bn.to_s(16).downcase
      ]
    end
  end
end
