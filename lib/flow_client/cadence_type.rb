require "ostruct"

module FlowClient
  def self.String(string)
    OpenStruct.new(type: "String", value: string.to_s)
  end

  def self.Optional(value: nil)
    OpenStruct.new(type: "Optional", value: value)
  end

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
    OpenStruct.new(type: "UInt", value: value.to_i)
  end

  def self.Int8(value)
    OpenStruct.new(type: "Int8", value: value.to_i)
  end

  def self.UInt8(value)
    OpenStruct.new(type: "UInt8", value: value.to_i)
  end

  def self.Int16(value)
    OpenStruct.new(type: "Int16", value: value.to_i)
  end

  def self.UInt16(value)
    OpenStruct.new(type: "UInt16", value: value.to_i)
  end

  def self.Int32(value)
    OpenStruct.new(type: "Int32", value: value.to_i)
  end

  def self.UInt32(value)
    OpenStruct.new(type: "UInt32", value: value.to_i)
  end

  def self.Int64(value)
    OpenStruct.new(type: "Int64", value: value.to_i)
  end

  def self.UInt64(value)
    OpenStruct.new(type: "UInt64", value: value.to_i)
  end

  def self.Int64(value)
    OpenStruct.new(type: "Int64", value: value.to_i)
  end

  def self.UInt64(value)
    OpenStruct.new(type: "UInt64", value: value.to_i)
  end

  def self.Int128(value)
    OpenStruct.new(type: "Int128", value: value.to_i)
  end

  def self.UInt128(value)
    OpenStruct.new(type: "UInt128", value: value.to_i)
  end

  def self.Int256(value)
    OpenStruct.new(type: "Int256", value: value.to_i)
  end

  def self.UInt256(value)
    OpenStruct.new(type: "UInt256", value: value.to_i)
  end

  def self.Word8(value)
    OpenStruct.new(type: "Word8", value: value.to_i)
  end

  def self.Word8(value)
    OpenStruct.new(type: "Word8", value: value.to_i)
  end

  def self.Word16(value)
    OpenStruct.new(type: "Word16", value: value.to_i)
  end

  def self.Word16(value)
    OpenStruct.new(type: "Word16", value: value.to_i)
  end

  def self.Word32(value)
    OpenStruct.new(type: "Word32", value: value.to_i)
  end

  def self.Word32(value)
    OpenStruct.new(type: "Word32", value: value.to_i)
  end

  def self.Word64(value)
    OpenStruct.new(type: "Word64", value: value.to_i)
  end

  def self.Word64(value)
    OpenStruct.new(type: "Word64", value: value.to_i)
  end

  def self.Fix64(value)
    OpenStruct.new(type: "Fix64", value: value.to_i)
  end

  def self.Fix64(value)
    OpenStruct.new(type: "Fix64", value: value.to_i)
  end

  def self.UFix64(value)
    OpenStruct.new(type: "Fix64", value: value.to_i)
  end

  def self.UFix64(value)
    OpenStruct.new(type: "Fix64", value: value.to_i)
  end

  def self.Array(values)
    OpenStruct.new(type: "Array", value: values.to_a)
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
      type: "Type",
      value: OpenStruct.new(
        path: path.to_s,
        address: address.to_s,
        borrow_type: borrow_type.to_s
      )
    )
  end
end