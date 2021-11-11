require "ostruct"

module FlowClient
  module CadenceType

    # Returns an OpenStruct representing a Cadence String type
    #
    # @example
    #   @arg = FlowClient::CadenceType.String("Hello world!")
    #
    # @param [String] the string value
    #
    # @returns [OpenStruct] the Cadence String struct
    def self.String(value)
      OpenStruct.new(type: "String", value: value.to_s)
    end

    # Returns an OpenStruct representing a Cadence Optional type
    #
    # @example
    #   @arg = FlowClient::CadenceType.Optional("Hello world!")
    #   @arg = FlowClient::CadenceType.Optional()
    #
    # @param [String] the string value
    #
    # @returns [OpenStruct] the Cadence Optional struct
    def self.Optional(value = nil)
      OpenStruct.new(type: "Optional", value: value)
    end

    # Returns an OpenStruct representing a Cadence Void type
    #
    # @example
    #   @arg = FlowClient::CadenceType.Void()
    #
    # @returns [OpenStruct] the Cadence Void struct
    def self.Void()
      OpenStruct.new(type: "Void")
    end

    def self.Bool(bool)
      OpenStruct.new(type: "Bool", value: bool.to_s.downcase == "true")
    end

    def self.Address(address)
      OpenStruct.new(type: "Address", value: address.to_s)
    end

    def self.Int(value)
      OpenStruct.new(type: "Int", value: value.to_s)
    end

    def self.UInt(value)
      OpenStruct.new(type: "UInt", value: value.to_s)
    end

    def self.Int8(value)
      OpenStruct.new(type: "Int8", value: value.to_s)
    end

    def self.UInt8(value)
      OpenStruct.new(type: "UInt8", value: value.to_s)
    end

    def self.Int16(value)
      OpenStruct.new(type: "Int16", value: value.to_s)
    end

    def self.UInt16(value)
      OpenStruct.new(type: "UInt16", value: value.to_s)
    end

    def self.Int32(value)
      OpenStruct.new(type: "Int32", value: value.to_s)
    end

    def self.UInt32(value)
      OpenStruct.new(type: "UInt32", value: value.to_s)
    end

    def self.Int64(value)
      OpenStruct.new(type: "Int64", value: value.to_s)
    end

    def self.UInt64(value)
      OpenStruct.new(type: "UInt64", value: value.to_s)
    end

    def self.Int64(value)
      OpenStruct.new(type: "Int64", value: value.to_s)
    end

    def self.UInt64(value)
      OpenStruct.new(type: "UInt64", value: value.to_s)
    end

    def self.Int128(value)
      OpenStruct.new(type: "Int128", value: value.to_s)
    end

    def self.UInt128(value)
      OpenStruct.new(type: "UInt128", value: value.to_s)
    end

    def self.Int256(value)
      OpenStruct.new(type: "Int256", value: value.to_s)
    end

    def self.UInt256(value)
      OpenStruct.new(type: "UInt256", value: value.to_s)
    end

    def self.Word8(value)
      OpenStruct.new(type: "Word8", value: value.to_s)
    end

    def self.Word16(value)
      OpenStruct.new(type: "Word16", value: value.to_s)
    end

    def self.Word32(value)
      OpenStruct.new(type: "Word32", value: value.to_s)
    end

    def self.Word64(value)
      OpenStruct.new(type: "Word64", value: value.to_s)
    end

    def self.Fix64(value)
      OpenStruct.new(type: "Fix64", value: value.to_s)
    end

    def self.UFix64(value)
      OpenStruct.new(type: "UFix64", value: value.to_s)
    end

    def self.Array(values)
      OpenStruct.new(type: "Array", value: values)
    end

    def self.Dictionary(values)
      OpenStruct.new(type: "Dictionary", value: values)
    end

    def self.DictionaryValue(key, value)
      OpenStruct.new(key: key, value: value)
    end

    def self.Path(domain, identifier)
      raise raise ArgumentError.new(
        "Domain can only be one of storage, private or public"
      ) unless ["storage", "private", "public"].include? domain.to_s.downcase

      OpenStruct.new(
        type: "Path",
        value: OpenStruct.new(domain: domain, identifier: identifier)
      )
    end

    def self.Type(type_value)
      OpenStruct.new(type: "Type", value: OpenStruct.new(staticType: type_value.to_s))
    end

    def self.Capability(path, address, borrow_type)
      OpenStruct.new(
        type: "Capability",
        value: OpenStruct.new(
          path: path.to_s,
          address: address.to_s,
          borrowType: borrow_type.to_s
        )
      )
    end

    def self.Composite(type, value)
      valid_types = [:struct, :resource, :event, :contract, :enum]
      raise ArgumentError.new("incorrect type, expected :struct, :resource, :event, :contract or :enum") unless valid_types.include? type
      OpenStruct.new(type: type.to_s.capitalize, value: value)
    end

    def self.CompositeValue(id, fields)
      OpenStruct.new(id: id, fields: fields)
    end

    def self.Field(name, value)
      OpenStruct.new(name: name, value: value)
    end
  end
end