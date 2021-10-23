import Crypto

transaction(publicKeys: [String], contracts: {String: String}) {
	prepare(signer: AuthAccount) {
		let acct = AuthAccount(payer: signer)
		for keyHex in publicKeys {
			let key = PublicKey(
				publicKey: keyHex.decodeHex(),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			)

			acct.keys.add(
				publicKey: key,
				hashAlgorithm: HashAlgorithm.SHA3_256,
				weight: 1000.0
			)
		}
	}
}