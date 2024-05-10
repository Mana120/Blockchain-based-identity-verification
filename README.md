# Identity Verification Smart Contract

## Introduction
This Solidity smart contract, `IdentityVerification`, facilitates the verification of user identities and registration of third-party applications for accessing user data. It ensures secure verification through cryptographic signatures and provides a mechanism for registering and verifying third-party apps.

## Features
- User identity registration with details such as username, phone number, email, and Aadhar number.
- Third-party application registration with company name, email, and phone number.
- Cryptographic signature verification for user and app registration.
- Admin privileges for verifying third-party applications and managing user data validation.

## Use Case Diagram
<img width="933" alt="Screenshot 2024-05-10 at 2 43 32 PM" src="https://github.com/shreya241103/Blockchain-based-identity-verification/assets/115857097/40b0a531-b944-404d-a3d5-6de0350918e6">

## Flow Diagram
<img width="1032" alt="Screenshot 2024-05-10 at 2 44 20 PM" src="https://github.com/shreya241103/Blockchain-based-identity-verification/assets/115857097/1575a766-52bf-4645-afd9-b8da47aa6356">

## Contract Structure
The contract consists of two main components:
1. **IdentityVerification**: Manages user identity registration and third-party app registration.
2. **DataValidator**: Validates user data during registration.

## Usage
### Identity Verification
`registerIdentity`: Allows users to register their identity with the contract by providing username, phone number, email, Aadhar number, and cryptographic signature (v, r, s).
   - Signature Verification: Users must generate a cryptographic signature using their private key and include it along with v, r, and s components to ensure data integrity and authentication.

### Third-Party App Registration
`registerThirdPartyApp`: Allows third-party apps to register with the contract by providing company name, email, phone number, and cryptographic signature (v, r, s).
   - Signature Verification: Third-party apps must generate a cryptographic signature using their private key and include it along with v, r, and s components to ensure data integrity and authentication.

### Data Validation
The `DataValidator` contract validates user data during registration and provides an initial dataset of users for testing purposes.

### Signature Generation
The Signature verification process is explained below:

<img width="752" alt="Screenshot 2024-04-26 at 6 41 20 PM" src="https://github.com/shreya241103/Blockchain-based-identity-verification/assets/115857097/977efd7c-7284-461a-b711-757164861a0d">

`Signing`:

Create message to sign: Initiate the signing process by creating a message to be authenticated.
Hash the message: Apply a cryptographic hash function to convert the message into a fixed-length string of characters.
Sign the hash: Sign the hashed message using the private key of the signer.

`Verification`:

Recreate hash from the original message: Reconstruct the hash of the original message using the same inputs as during the signing process.
Recover signer from signature and hash: Utilize the signature and reconstructed hash to recover the signer’s address.
Compare recovered signer to claimed signer: Verify whether the recovered signer’s address matches the claimed signer’s address to determine the validity of the signature.

### File Explantion:
1. `IdentityVerfication.sol`: Contains the smart contract.
2. `user_Signature_Generation.html`: Interface for users to generate a signature using their private key.
3. `third_Party_Signature_Generation.html`: Interface for third-party apps to generate a signature using their private key.

## Contributors
- Shreya Kashyap ([@Shreya241103](https://github.com/shreya241103))
- Sai Manasa Nadimpalli ([@Mana120](https://github.com/Mana120))
