// SPDX-License-Identifier:MIT
pragma solidity 0.8.19;
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/raffle.sol";
import {Test} from "../../../lib/forge-std/src/Test.sol";
import {helperConfig} from "script/helperConfig.s.sol";

contract raffleTest is Test {
    uint64 subscriptionId;
    bytes32 gasLane; // keyHash
    uint256 interval;
    uint256 entranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2;
    address link;

    event EnteredRaffle(address indexed player);

    Raffle raffle;
    helperConfig HelperConfig;
    address public PLAYER = makeAddr("player");
    uint public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, HelperConfig) = deployer.run();
        (
            subscriptionId,
            gasLane, // keyHash
            interval,
            entranceFee,
            callbackGasLimit,
            vrfCoordinatorV2,
            link
        ) = HelperConfig.activeNetworkConfig();
        //vm.deal is a cheat code to give our contract some money
        vm.deal (PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleStateInitialisedisOPEN() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
    function testRaffleRevert_payEnoughETH() public {
        //arrange
        vm.prank(PLAYER);
        //ACT / ASSERT
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
        
    }

    function testRaffleRecordPlayerWhenTheyEnterRaffle() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecord = raffle.getPlayer(0);
        assert(playerRecord == PLAYER);
    }
    function testEmitEventOnEntrace() public {
        vm.prank(PLAYER);
        vm.expectEmit (true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value:  entranceFee}();



    }
    function testCantEnterWhileRaaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
    }
    
}