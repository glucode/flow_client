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
      output = FlowClient::Utils.substitute_address_aliases(
        script,
        { "0xFUNGIBLE_TOKEN_ADDRESS": "0x01", "0xFUSD": "0x02" }
      )
      expect(output.include?("import FungibleToken from 0xFUNGIBLE_TOKEN_ADDRESS")).to be(false)
      expect(output.include?("import FUSD from 0xFUSD")).to be(false)
    end
  end

  describe "account proof" do
    let(:address) { "ABC123DEF456" }
    let(:nonce) { "3037366134636339643564623330316636626239323161663465346131393662" }
    let(:app_identifier) { "AWESOME-APP-ID" }

    it "has a valid domain tag" do
      expect(FlowClient::Utils::FCL_ACCOUNT_PROOF_DOMAIN_TAG).to eq("FCL-ACCOUNT-PROOF-V0.0")
    end

    it "encodes the message" do
      message = FlowClient::Utils.encoded_account_proof(
        address, nonce, app_identifier
      )
      expect(message).to eq("46434c2d4143434f554e542d50524f4f462d56302e3000000000000000000000f8398e415745534f4d452d4150502d4944880000abc123def456a03037366134636339643564623330316636626239323161663465346131393662")
    end
  end

  describe "left_pad_bytes pads the byte array" do
    let(:bytes) { [0x41] }
    let(:expected) { [0x00, 0x41] }

    it "left pads the byte array" do
      expect(FlowClient::Utils.left_pad_bytes(bytes, 2)).to eq(expected)
    end
  end

end
