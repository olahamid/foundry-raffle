// SPDX-License-Identifier:MIT
pragma solidity 0.8.19;
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/raffle.sol";
import {Test} from "../../../lib/forge-std/src/Test.sol";
import {helperConfig} from "script/helperConfig.s.sol";
import {Vm} from "../../../lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2Mock} from "../../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";


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
    uint public constant STARTING_USER_BALANCE = 1 ether;
   
     

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
            link,
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


    // function testEmitEventOnEntrace() public {
    //     vm.prank(PLAYER);
    //     vm.expectEmit (true, false, false, false, address(raffle));
    //     emit EnteredRaffle(PLAYER);
    //     raffle.enterRaffle{value:  entranceFee}();



    // }
    function testCantEnterWhileRaaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }
    function testCheckUpkeepIfIthasNoBalances() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        //assert
        assert (!upkeepNeeded);


    }
    function testCheckUpkeepIfTheRaffleNotOpenen() public {
        //arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        //with the line above this shoud set it to the calculatng state.

        //act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //asert
        assert(!upkeepNeeded);
        //assert(upkeepNeeded == false); since we arre calculating for to see if the upkeep withh return false when in calculating mode.

    }
     //testcheckUpreturnsfalseifenoughtimehasntpassed (correct)
   function testcheckUpreturnsfalseifenoughtimehasntpassed() public {
    //the aim is to set the test function as if the block time stamp has pased
    //arrange 
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    
    // raffle.transferAllBalance();
    vm.warp(block.timestamp + interval - 1); //the link is returning true that says that the link timpased in the raffle contract is true
    // vm.roll(block.number );

    //act
    (bool upkeepNeeded, ) = raffle.checkUpkeep("");

    //assert
    //for the assert part we are calculating for a fale return if the bool istimepasssed false
    assert(!upkeepNeeded);
    // assertTrue(upkeepNeeded);
   }
    //testretunstrueifparameteraregood
    function testretunstrueifparameteraregood( ) public {
        //arrange parameters to arrange this parameter you must first sort it out in a way to indicate that the function checkupkeep is returnin true
        vm.prank (PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);

        // act callling the checkupkeep and storing it ina a return value
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // assert
        assert(upkeepNeeded);
    }
    function testperformUpKeepCanOnlyRunIfCheckUpKeepisTrue() public {
        //arrange 
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //act 
        raffle.checkUpkeep("");

    }
    function testPerformKeepRevertIfCheckUpKeepIsFalse() public {
        //arrange
        uint256 currentBalance = 0;
        uint256 numPlayers  = 0;
        uint256 raffleState = 0;
        //act
        vm.expectRevert(abi.encodeWithSelector(
            Raffle.Raffle__UpkeepNotNeeded.selector, 
            currentBalance,
            numPlayers,
            raffleState

        ));
        raffle.performUpkeep("");

    }
    modifier raffleEnterAndTimePassed() {
           vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee};
        vm.warp(block.timestamp + interval + 1);
        vm.roll (block.number + 1);
        _;
    }
     //what if i need to test using the output of event
     //it's important to check the output of an event because the way the chainlink vrf works is the chaijnlink vrf listen to events(in the vrfMockcoordinator)
    // function testPerformUpKeepUpdateRaffleStateemitRequestID() public 
    //  {
    //      vm.prank(PLAYER);
    //     raffle.enterRaffle{value: entranceFee};
    //     vm.warp(block.timestamp + interval + 1);
    //     vm.roll (block.number + 1);
    //     //ARRANGE 
    //     // vm.prank(PLAYER);
    //     // raffle.enterRaffle{value: entranceFee};
    //     // vm.warp(block.timestamp + interval + 1);
    //     // vm.roll (block.number + 1);
    //     //ACT
    //     //we are going to use another cheatcode called recordlog, it is used to save all the data  output and put it accessible in the getrecord lof
    //     // it auto saves all the log output into the data structure that we can view with getrecordlog    
    //     vm.recordLogs();
    //     raffle.performUpkeep("");// emit the requestID
    //     Vm.Log[] memory logs = vm.getRecordedLogs();//THIS IS going to get all of the values that we used as an event in the performUpkeep. NOTE that you need to always import Vm.log
    //     //there are common ways to figure out which event we are emitting 1} is the cheat code in foundry which is the debugger (forge test --debug (the neame of the function we are debugging))
    //     bytes32 requestID = logs[1].topics[1];
    //     //191. all logs are stored as bytes, 0 will be randomnumber emit in the RAFFLE CONTRACT. 
    //     Raffle.RaffleState rState= raffle.getRaffleState();
    //     //assert
    //     assert(uint(requestID) > 0);
    //     assert(uint (rState) == 1) ;
    //      raffle.enterRaffle{value: entranceFee};

    // }
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // requestId = raffle.getLastRequestId();
        assert(uint256(requestId) > 0);
        assert(uint(raffleState) == 1); // 0 = open, 1 = calculating
    }
    
    function testfullfillRandomWordsCanOnlyBeCalledAfterPerformUPKeep(uint randomRequestid) public raffleEnterAndTimePassed {
        //since we use the random request id here, what will happen is that foundry will create a random number and test it a lot of times this process is called fuzz
        //ARRANGE
        //WE want to make sure that calling fullfillRandomWords in the mock to fail
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
            randomRequestid, 
            address(raffle));


    }
    // ONE BIG TEST
    // function testfullRandomWordsPicksAWinnerResetAndSeendsMoney() public{
    //     //this willl be the full test, we will enter the lottery a couple of times,we will move the the time up so the checkupkeep will become true, we will kick off the request to get a random number, performupkeep, we will pretend to be the chainlink vrf in response and call the fulfillRndomWords
    //      vm.prank(PLAYER);
    //     raffle.enterRaffle{value: entranceFee};
    //     vm.warp(block.timestamp + interval + 1);
    //     vm.roll (block.number + 1);

    //     //ARRANGE 
    //     uint additionalEntrace = 5;//we already have 1 person enterijng the raffle from the raffleEnterAndTimePassed so we are doing 5 more
    //     uint startingIndex = 1;

    //     for (uint i = startingIndex; 
    //     i < startingIndex + additionalEntrace;
    //      i++) {
    //         // address player = //makeAddr(PLAYER);
    //         address player = address(uint160(i));//equivalent of being address of 1 or 2 or 3
    //         hoax(player, STARTING_USER_BALANCE);//hoax is 1 of the cheatcode to set up prank an ether
    //         raffle.enterRaffle{value: entranceFee}();
    //      }

    //      uint price = entranceFee * (additionalEntrace +1);   

    //     vm.recordLogs();
    //     raffle.performUpkeep("");// emit the requestID
    //     Vm.Log[] memory logs = vm.getRecordedLogs();//THIS IS going to get all of the values that we used as an 
    //     bytes32 requestID = logs[1].topics[1];
    //      uint previousTimeStamp = raffle.getTheLastTimeStamp();

       

    //     //pretent to be the chainlink node WINNER 
    //      VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
    //         uint (requestID), 
    //         address(raffle));

    //         //assert
    //         assert(uint (raffle.getRaffleState()) == 0);//to be back to be open
    //     assert (raffle.getRecentWinner() != address(0));
    //     assert(raffle.getlengthOfPlayers() == 0);
    //     assert (previousTimeStamp < raffle.getTheLastTimeStamp());
    //     assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + price - entranceFee);

    // }
    modifier skipFork () {
        if (block.chainid != 31337){
            return;
        }
        _;
    }
    
    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        skipFork
    {
         vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        address expectedWinner = address(1);

        // Arrange
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrances;
            i++
        ) {
            address player = address(uint160(i));
            hoax(player, 1 ether); // deal 1 eth to the player
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 startingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs

        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrances + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == startingBalance + prize - entranceFee);
        assert(endingTimeStamp > startingTimeStamp);
    }

}