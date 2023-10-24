// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from  "../test/mocks/linkToken.sol";
contract helperConfig is Script{
    

    networkConfig public activeNetworkConfig;
    struct networkConfig {
        uint64 subscriptionId;
        bytes32 gasLane; // keyHash
        uint256 interval;
        uint256 entranceFee;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2; 
        address link;
        uint deployerKey;
        }
        uint public constant Default_anvil_key = 
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    constructor () {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSapoliaETH();
        } else {
            activeNetworkConfig = getOrCreateSapoliaAnvil();
        }
    }

    function getSapoliaETH() public view returns (networkConfig memory) {
        return networkConfig ({
        subscriptionId: 1893,
        gasLane:0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // keyHash
        interval: 30 seconds,
        entranceFee: 0.01 ether,
        callbackGasLimit:5000,
        vrfCoordinatorV2: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
        link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
        deployerKey: vm.envUint("PRIVATE_KEY")//c55c76ed5fd3c774b38e8f9fdea1b16e12dd174594adefddfa1a01dff691dbc8
        });
    }
    function getOrCreateSapoliaAnvil() public returns (networkConfig memory) {
        if (activeNetworkConfig.vrfCoordinatorV2 != address(0)) {
            return activeNetworkConfig;
        }
        uint96 basefee = 0.0025 ether;
        uint96 gaspricelink = 1e9;
        vm.startBroadcast();
        VRFCoordinatorV2Mock VRFCoordinatorMock = new VRFCoordinatorV2Mock (basefee , gaspricelink);
        vm.stopBroadcast();
        LinkToken linkToken = new LinkToken();
        return networkConfig ({
            subscriptionId: 0,
            gasLane:0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // keyHash
            interval: 30 seconds,
            entranceFee: 0.05 ether,
            callbackGasLimit:500000,
            vrfCoordinatorV2: address(VRFCoordinatorMock),
            link: address(linkToken),
            deployerKey : Default_anvil_key
        });
       
    }
  

    
}