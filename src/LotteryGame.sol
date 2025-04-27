// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title LotteryGame
 * @dev A simple number guessing game where players can win ETH prizes
 */
contract LotteryGame {
    struct Player {
        uint256 attempts;
        bool active;
    }

    // State variables
    mapping(address => Player) public players;
    address[] public playerAddresses;
    address[] public winners;
    address[] public previousWinners;
    uint256 public totalPrize;

    // Events
    event PlayerRegistered(address player);
    event GuessResult(address player, uint256 guess, bool correct);
    event PrizesDistributed(uint256 prizeAmount, address[] winners);

    /**
     * @dev Register to play the game
     * Players must stake exactly 0.02 ETH to participate
     */
    function register() public payable {
        require(msg.value == 0.02 ether, "Please stake 0.02 ETH");
        
        // If already registered, no need to add again
        require(!players[msg.sender].active, "Player already registered");

        players[msg.sender] = Player(0, true);
        playerAddresses.push(msg.sender);
        totalPrize += msg.value;

        emit PlayerRegistered(msg.sender);
    }

    /**
     * @dev Make a guess between 1 and 9
     * @param guess The player's guess
     */
    function guessNumber(uint256 guess) public {
        require(guess >= 1 && guess <= 9, "Number must be between 1 and 9");
        require(players[msg.sender].active, "Player is not active");
        require(players[msg.sender].attempts < 2, "Player has already made 2 attempts");

        // Generate the "random" number
        uint256 randomNumber = _generateRandomNumber();

        // Check if guess is correct
        bool isCorrect = guess == randomNumber;
        if (isCorrect) {
            winners.push(msg.sender);
        }

        // Update attempts and emit event
        players[msg.sender].attempts++;
        emit GuessResult(msg.sender, guess, isCorrect);
    }

    /**
     * @dev Distribute prizes to winners
     */
    function distributePrizes() public {
        require(winners.length > 0, "No winners to distribute prizes to");

        // Calculate prize amount per winner
        uint256 prizePerWinner = totalPrize / winners.length;

        // Transfer prizes to winners
        for (uint256 i = 0; i < winners.length; i++) {
            payable(winners[i]).transfer(prizePerWinner);
        }

        // Update previous winners list and reset game state
        for (uint256 i = 0; i < winners.length; i++) {
            previousWinners.push(winners[i]);
        }
        resetGame();

        emit PrizesDistributed(prizePerWinner, winners);
    }

    /**
     * @dev View function to get previous winners
     * @return Array of previous winner addresses
     */
    function getPrevWinners() public view returns (address[] memory) {
        return previousWinners;
    }

    /**
     * @dev Helper function to generate a "random" number
     * @return A uint between 1 and 9
     * NOTE: This is not secure for production use!
     */
    function _generateRandomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 9 + 1;
    }

    /**
     * @dev Reset game state for a new round
     */
    function resetGame() internal {
        delete winners;
        totalPrize = 0;

        // Reset players' attempts
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            players[playerAddresses[i]].attempts = 0;
        }
    }
}
