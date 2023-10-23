// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Script, console} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/raffle.sol";
import {helperConfig} from "../script/helperConfig.s.sol";
import {CreateSubscriptions, fundCreateSubscription, addConsumers} from "./interaction.s.sol";


 
contract DeployRaffle is Script{
    function run() external returns(Raffle, helperConfig) {
        helperConfig HelperConfig = new helperConfig();
       ( uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2,
        address link, uint deployerKey)= HelperConfig.activeNetworkConfig();
        if (subscriptionId == 0) {
            //we are going to need to create a subcription
            CreateSubscriptions createSubscriptions = new CreateSubscriptions();
            subscriptionId = createSubscriptions.createSubscription(vrfCoordinatorV2, deployerKey);

              
              // fund it!
            fundCreateSubscription FundingSubscription = new fundCreateSubscription();
            FundingSubscription.fundSubscription(subscriptionId, vrfCoordinatorV2, link, deployerKey);






        }
      
        
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            subscriptionId,
            gasLane, // keyHash
            interval,
            entranceFee,
            callbackGasLimit,
            vrfCoordinatorV2  
        );
        vm.stopBroadcast();
        addConsumers AddConsumers = new addConsumers();
        AddConsumers.addConsumer(address(raffle), vrfCoordinatorV2, subscriptionId, deployerKey);
        return (raffle, HelperConfig);
        
    } 


}