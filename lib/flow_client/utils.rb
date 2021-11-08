# frozen_string_literal: true

module FlowClient
  # A collection of utilities.
  module Utils
    # Left pads a byte array with 0 to length
    def self.left_pad_bytes(byte_array, length)
      required_pad_count = length - byte_array.count
      padding = []
      (1..required_pad_count).each do |_i|
        padding << 0
      end
      padding + byte_array
    end

    # Right pads a byte array with 0 to length
    def self.right_pad_bytes(byte_array, length)
      required_pad_count = length - byte_array.count
      padding = []
      (1..required_pad_count).each do |_i|
        padding << 0
      end
      byte_array + padding
    end

    # Substitutes Candence import statements using aliases with addresses
    # e.g. import FungibleToken from 0xFUNGIBLE_TOKEN_ADDRESS.
    #
    # aliases is a hash with aliases as string keys and addresses as values,
    # e.g. { "0xFUNGIBLE_TOKEN_ADDRESS": "0x0" }
    def self.substitute_address_aliases(script_or_transaction, aliases = {})
      new_string = script_or_transaction
      aliases.each do |key, value|
        new_string = new_string.gsub(key.to_s, value.to_s)
      end
      new_string
    end

    def self.strip_address_prefix(address)
      address[0..1]
    end

    def self.parse_protobuf_timestamp(timestamp)
      epoch_micros = timestamp.nanos / 10 ** 6
      Time.at(timestamp.seconds, epoch_micros)
    end

    def self.openstruct_to_json(struct)
      struct.each_pair.map do |key, value|
        [
          key,
          case value
            when OpenStruct then value.deep_to_h
            when Array then value.map {|el| el.class == OpenStruct ? el.deep_to_h : el}
            else value
          end
        ]
      end.to_h.to_json
    end

  end
end
