module FlowClient
  module Utils
    def self.left_pad_bytes(byte_array, length)
      required_pad_count = length - byte_array.count
      padding = []
      for i in 1..required_pad_count
        padding << 0
      end
      padding + byte_array
    end

    def self.right_pad_bytes(byte_array, length)
      required_pad_count = length - byte_array.count
      padding = []
      for i in 1..required_pad_count
        padding << 0
      end
      byte_array + padding
    end
  end
end