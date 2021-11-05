module FlowClient
  class CadenceType
    attr_accessor :type, :value

    def to_json
      { type: @type, value: @value }.to_json
    end

    def self.parse_json(json)
      res = JSON.parse(json)
    end
  end

  class Void < CadenceType
    def initialize
      @type = "Void"
    end
  end

  # {
  #   "type": "Bool",
  #   "value": true | false
  # }
  class Bool < CadenceType
    def initialize(bool)
      @type = "Boolean"
      @value = bool
    end
  end

  class String < CadenceType
    def initialize(string)
      @type = "String"
      @value = string
    end
  end

  class Address < CadenceType
    def initialize
      @type = "String"
    end
  end
end