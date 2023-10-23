//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
// import {Script, console} from "forge-std/src/Script.sol";
import {Script, console} from "../lib/forge-std/src/Script.sol";
import {helperConfig} from "../script/helperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from  "../test/mocks/linkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscriptions is Script{
  
    // function createUintConfig() public returns(uint64) {
    //     helperConfig HelperConfig = new helperConfig();
       // }
       function createUintConfig() public returns (uint64) {
        helperConfig HelperConfig = new helperConfig();
        (,,,,, address vrfCoordinatorV2 , , uint deployerKey) = HelperConfig.activeNetworkConfig();
        address vrfCoordinator = vrfCoordinatorV2;
        return createSubscription(vrfCoordinator, deployerKey);
    }
    //the whole point 
    function createSubscription(address vrfCoordinator, uint deployerKey) public returns (uint64) {
        console.log ("creting Subcription on chainId: " , block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("your sub Id is:", subId);
        console.log("please update subcription in helperConfig.s.sol");
        return subId;


    }
      function run() external returns(uint64) {
        return createUintConfig();
    }

}
contract fundCreateSubscription is Script{
    uint96 public fund_Amount = 3 ether;

    function fundSubscriptionUsingConfig() public {
        helperConfig HelperConfig = new helperConfig();
        ( uint64 subscriptionId,,,,, address vrfCoordinatorV2, address link, uint deployerKey) = HelperConfig.activeNetworkConfig();
        fundSubscription(subscriptionId, vrfCoordinatorV2, link, deployerKey);

    }
    function fundSubscription(uint64 subscriptionId, address vrfCoordinatorV2, address link, uint deployerKey) public {
        console.log ("funding Id:" ,  subscriptionId);
        console.log ("vrfCoordinator Id:" , vrfCoordinatorV2);
        console.log ("on chain  id:" ,  block.chainid);
        if (block.chainid == 31337) {
            //we are saying that if we are on a local network/chain(31337)
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinatorV2).fundSubscription(subscriptionId,fund_Amount);
            vm.stopBroadcast();

        }
        
         else {
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinatorV2,
            fund_Amount,
            abi.encode(subscriptionId));

            vm.stopBroadcast();
        }

        

    }
    function run() external returns(uint64) {
        fundSubscriptionUsingConfig();
    }

} 
contract addConsumers is Script{
     function addConsumer (address raffle, address vrfCoordinatorV2, uint64 subscriptionId, uint deployerKey) public {
        console.log ("adding consumer contract:", raffle);
        console.log ("address:", vrfCoordinatorV2);
        console.log ("chain ID:", block.chainid);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinatorV2).addConsumer(subscriptionId, raffle);
        vm.stopBroadcast();

        }

    function addConsumerUsingConfig(address raffle) public {
        helperConfig HelperConfig= new helperConfig();
        (uint64 subscriptionId,,,,, address vrfCoordinatorV2, ,uint deployerKey) = HelperConfig.activeNetworkConfig();
        addConsumer(raffle, vrfCoordinatorV2, subscriptionId, deployerKey);

    } 
   
function run() external {
    address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
    addConsumerUsingConfig(raffle);
}

}

