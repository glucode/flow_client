# frozen_string_literal: true

RSpec.describe FlowClient::Utils do
  it "left pads a byte array" do
    bytes = [0x41]
    expect(FlowClient::Utils.left_pad_bytes(bytes, 2)).to eq([0x00, 0x41])
  end

  it "right pads a byte array" do
    bytes = [0x41]
    expect(FlowClient::Utils.right_pad_bytes(bytes, 2)).to eq([0x41, 0x00])
  end
end
