// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import {Test,console} from "forge-std/Test.sol";
import {MerkleAirDrop} from "../../src/MerkleAirDrop.sol";
import {BagelToken} from "../../src/BagelToken.sol";
import {DeployMerkleAirdrop} from "../../script/DeployMerkleAirdrop.s.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";
contract MerkleAirdropTest is ZkSyncChainChecker,Test {
    MerkleAirDrop airdrop;
    BagelToken token;

    address user;
    uint256 userPrivKey;

    bytes32 merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 amountToCollect = (25 * 1e18); // 25.000000
    uint256 amountToSend = amountToCollect * 4;
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [proofOne, proofTwo];

    function setUp() public {
        if (!isZkSyncChain()) {
            //You are not in zksync chain script not working in zksync
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        }
        else{
        // deploy the token
        token = new BagelToken();
        // deploy the airdrop contract
        airdrop = new MerkleAirDrop(merkleRoot, token);
        token.mint(token.owner(), amountToSend);
        token.transfer(address(airdrop), amountToSend);
    }
        (user, userPrivKey) = makeAddrAndKey("user");
    }
   function testUsersCanClaim() public view{
        uint256 startingBalance = token.balanceOf(user);

        // get the signature
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivKey, user);
        vm.stopPrank();

        // gasPayer claims the airdrop for the user
        vm.prank(gasPayer);
        airdrop.claim(user, amountToCollect, proof, v, r, s);
        uint256 endingBalance = token.balanceOf(user);
        console.log("Ending balance: %d", endingBalance);
        assertEq(endingBalance - startingBalance, amountToCollect);

    }
}