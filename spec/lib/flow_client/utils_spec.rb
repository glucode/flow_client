# frozen_string_literal: true

RSpec.describe FlowClient::Utils do
  it :left_pad_bytes do
    bytes = [0x41]
    expect(FlowClient::Utils.left_pad_bytes(bytes, 2)).to eq([0x00, 0x41])
  end

  it :right_pad_bytes do
    bytes = [0x41]
    expect(FlowClient::Utils.right_pad_bytes(bytes, 2)).to eq([0x41, 0x00])
  end

  describe :substitute_address_aliases do
    let(:script) do
      %{
        import FungibleToken from 0xFUNGIBLE_TOKEN_ADDRESS
        import FUSD from 0xFUSD
        transaction(message: String) {}
      }
    end

    it "replaces import aliases" do
      output = FlowClient::Utils.substitute_address_aliases(script, { "0xFUNGIBLE_TOKEN_ADDRESS": "0x01", "0xFUSD": "0x02" })
      expect(output.include?("import FungibleToken from 0xFUNGIBLE_TOKEN_ADDRESS")).to be(false)
      expect(output.include?("import FUSD from 0xFUSD")).to be(false)
    end
  end
end
