# frozen_string_literal: true
include FlowClient

RSpec.describe FlowClient::CadenceType do
  context "arg constuction" do
    describe "Array" do
      it "" do
        json = {
          type: "Array",
          value: [
            { type: "String", value: "123" }
          ]
        }

        array = CadenceType.Array(
          [CadenceType.String("123")]
        )

        expect(array.deep_to_h.to_json).to eq(json.to_json)
      end

      # it { expect(block.id).to eq(response.id) }
      # it { expect(block.parent_id).to eq(response.parent_id) }
      # it { expect(block.height).to eq(response.height) }
    end
  end
end