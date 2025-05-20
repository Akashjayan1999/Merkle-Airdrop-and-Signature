//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MerkleAirDrop is EIP712 {

    using SafeERC20 for IERC20; // Prevent sending tokens to recipients who can’t receive
    //some list of ddresses
    //Allow someone in the list to claim ERC20 tokens
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();


    IERC20 private immutable i_airdropToken;
    bytes32 private immutable i_merkleRoot;
    mapping(address => bool) private s_hasClaimed;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");
    // define the message hash struct
    struct AirdropClaim {
        address account;
        uint256 amount;
    }




     event Claimed(address account, uint256 amount);

     constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("Merkle Airdrop", "1.0.0") {
        i_airdropToken = airdropToken;
        i_merkleRoot = merkleRoot;
     }

     function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
       //calculate using the amount and account, the hash -> leaf
           if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // Verify the signature
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
       // Verify the merkle proof
        // calculate the leaf node hash
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

         // verify the merkle proof
         if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

         s_hasClaimed[account] = true; // prevent users claiming more than once and draining the contract
         emit Claimed(account, amount);

          // transfer the tokens
        i_airdropToken.safeTransfer(account, amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }
    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    // message we expect to have been signed
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({ account: account, amount: amount })))
        );
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL
    //////////////////////////////////////////////////////////////*/

    // verify whether the recovered signer is the expected signer/the account to airdrop tokens for
    function _isValidSignature(
        address signer,
        bytes32 digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
        pure
        returns (bool)
    {
        // could also use SignatureChecker.isValidSignatureNow(signer, digest, signature)
        (
            address actualSigner,
            /*ECDSA.RecoverError recoverError*/
            ,
            /*bytes32 signatureLength*/
        ) = ECDSA.tryRecover(digest, _v, _r, _s);
        return (actualSigner == signer);
    }

    // function _isValidSignature(
    //     address signer,
    //     bytes32 digest,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s
    // )
    // internal view returns (bool) {
    //     bytes memory signature = abi.encode(_v, _r, _s);
    //     return SignatureChecker.isValidSignatureNow(signer, digest, signature);
    // }

}