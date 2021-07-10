module FlowClient
  class Transaction

    Payload = Struct.new(
      :script,
      :arguments,
      :reference_block_id,
      :gas_limit,
      :proposal_key_address,
      :proposal_key_index,
      :proposal_key_sequence_number,
      :payer,
      :authorizers
    )

    Envelope = Struct.new(
      :payload,
      :payload_signatures
    )

  end
end