// SPDX-Licence-Indentifier: MIT
pragma solidity ^0.8.12;

import { Script, console } from "forge-std/Script.sol";
import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { MerkleAirDrop } from "../src/MerkleAirDrop.sol";

contract ClaimAirdrop is Script {
    address private constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant AMOUNT_TO_COLLECT = (25 * 1e18); // 25.000000

    bytes32 private constant PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 private constant PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] private proof = [PROOF_ONE, PROOF_TWO];
    //To get the signature
    /*
    ubuntu@DESKTOP-R7CV0OC:~/foundary-f25/merkle-airdrop$ cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getMessageHash(address,uint256)" 0xf39Fd6e51aad88F
   6F4ce6aB8827279cffFb92266 25000000000000000000 --rpc-url http://localhost:8545
     0x7886453564f3abce484240ab03353027bde591090caf1f82ce22c3487afe9568
    ubuntu@DESKTOP-R7CV0OC:~/foundary-f25/merkle-airdrop$ cast wallet sign --no-hash 0x7886453564f3abce484240ab03353027bde591090caf1f82ce22c3487afe9568 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 
   0x04209f8dfd0ef06724e83d623207ba8c33b6690e08772f8887a4eaf9a66b9182188938adea374fa542ad5ddde24bdc981f5e26a628e65fb425a68db8a938f6761c
    ubuntu@DESKTOP-R7CV0OC:~/foundary-f25/merkle-airdrop$ 
 */
    //also remove 0x from the genarated signature
    bytes private SIGNATURE = hex"04209f8dfd0ef06724e83d623207ba8c33b6690e08772f8887a4eaf9a66b9182188938adea374fa542ad5ddde24bdc981f5e26a628e65fb425a68db8a938f6761c";
    error ClaimAirdropScript__InvalidSignatureLength();
    
    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
         console.log("Claiming Airdrop");
         MerkleAirDrop(airdrop).claim(CLAIMING_ADDRESS, AMOUNT_TO_COLLECT, proof, v, r, s);
         vm.stopBroadcast();
        console.log("Claimed Airdrop");
     }

function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert ClaimAirdropScript__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
    function run() external {
       address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirDrop", block.chainid); 
        claimAirdrop(mostRecentlyDeployed);
    
    }
}