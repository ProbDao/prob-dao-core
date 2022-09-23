// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../utils/Context.sol";
import "../interface/IERC20.sol";
import {BytesConv} from "../utils/Conv.sol";


enum Choice{ Rock, Paper, Scissors }
enum Result{ Player1Win, Player2Win, Tie , Unknown}
enum Status{ AlreadySettled, NotSettled}

struct Game {
    address player1;
    address player2;
    IERC20 stake;

    bytes32 betHash1;
    bytes32 betHash2;

    uint256 bet1;
    uint256 bet2;

    uint256 stakeAmount;
    uint lastBlockNumber;

    address winner;
    Status status;
    Result result;
}

contract RockPaperScissors is Context {

    mapping(uint256 => Game) public games;
    uint256 public newGameID;

    constructor() {}

    function createGame(address player1, address player2, address stake, uint256 amount) public returns(uint256) {
        Game memory newGame;
        newGame.player1 = player1;
        newGame.player2 = player2;
        newGame.stake = IERC20(stake);
        newGame.lastBlockNumber = block.number;
        newGame.stakeAmount = amount;
        newGame.bet1 = 0;
        newGame.bet2 = 0;
        newGame.result = Result.Unknown;
        newGame.status = Status.NotSettled;

        uint256 gameID = newGameID;
        newGameID+=1;
        
        games[gameID] = newGame;
        return gameID;
    }

    function isPlayer(uint256 gameID) internal view returns (bool) {
        address betor = _msgSender();
        return (betor == games[gameID].player1 || betor == games[gameID].player2);
    }

    function betOn(uint256 gameID, bytes32 betHash) public {
        require(isPlayer(gameID), "RockPaperScissors: only player can bet on");
        address betor = _msgSender();
        if (betor == games[gameID].player1) {
            require(games[gameID].bet1 == 0 ,"RockPaperScissors: cannot betOn twice");
            games[gameID].betHash1 = betHash;
        }else if (betor == games[gameID].player2) {
            require(games[gameID].bet2 == 0 ,"RockPaperScissors: cannot betOn twice");
            games[gameID].betHash2 = betHash;
        }
        games[gameID].stake.transferFrom(betor,address(this), games[gameID].stakeAmount);
        games[gameID].lastBlockNumber = block.number;
    }

    function reveal(uint256 gameID, uint256 bet) public {
        require(isPlayer(gameID), "RockPaperScissors: only player can reveal");
        address betor = _msgSender();
        bytes32 betHash;

        if (betor == games[gameID].player1) {
            betHash = games[gameID].betHash1;
            games[gameID].bet1 = bet;
        }else if (betor == games[gameID].player2) {
            betHash = games[gameID].betHash2;
            games[gameID].bet2 = bet;
        }

        require(betHash == keccak256(BytesConv.uint256ToBytes(bet)),"RockPaperScissors: do not lie on your bet");
        games[gameID].lastBlockNumber = block.number;
    }

    function settle(uint256 gameID) public {
        if ( games[gameID].status == Status.AlreadySettled ) {
            return;
        }

        if ( games[gameID].bet1 != 0 && games[gameID].bet2 != 0 ) {
            Result r = cmpToResult(
                toChoice(games[gameID].bet1),
                toChoice(games[gameID].bet2)
            );
            games[gameID].result = r;
        }

        // play2 not reveal -> lose
        if ( games[gameID].bet1 != 0 && games[gameID].bet2 == 0 && block.number - games[gameID].lastBlockNumber > 100 ) {
            games[gameID].result = Result.Player1Win;
        }

        // play1 not reveal -> lose
        if ( games[gameID].bet1 == 0 && games[gameID].bet2 != 0 && block.number - games[gameID].lastBlockNumber > 100 ) {
            games[gameID].result = Result.Player2Win;
        }
        // enum Result{ Player1Win, Player2Win, Tie , Unknown}
        if ( games[gameID].result == Result.Player1Win ) {
            games[gameID].stake.transfer(games[gameID].player1, games[gameID].stakeAmount * 2 * 98 / 100);
        }else if ( games[gameID].result == Result.Player2Win ) {
            games[gameID].stake.transfer(games[gameID].player2, games[gameID].stakeAmount * 2 * 98 / 100);
        }else if ( games[gameID].result == Result.Tie ) {
            games[gameID].stake.transfer(games[gameID].player1, games[gameID].stakeAmount);
            games[gameID].stake.transfer(games[gameID].player2, games[gameID].stakeAmount);
        }else{
            return;
        }
        games[gameID].status = Status.AlreadySettled;
        return;
    }


    function toChoice(uint256 n) internal pure returns(Choice) {
        if ( 0 == n % 3 ) {
            return Choice.Paper;
        }else if ( 1 == n % 3) {
            return Choice.Scissors;
        }else{
            return Choice.Rock;
        }
    }

    function cmpToResult(Choice c1, Choice c2) public pure returns(Result) {
        if (c1 == Choice.Paper && c2 == Choice.Scissors ) {
            return Result.Player2Win;
        }else if (c1 == Choice.Paper && c2 == Choice.Rock ) {
            return Result.Player1Win;
        }else if (c1 == Choice.Rock && c2 == Choice.Paper ) {
            return Result.Player2Win;
        }else if (c1 == Choice.Rock && c2 == Choice.Scissors ) {
            return Result.Player1Win;
        }else if (c1 == Choice.Scissors && c2 == Choice.Rock ) {
            return Result.Player2Win;
        }else if (c1 == Choice.Scissors && c2 == Choice.Paper ) {
            return Result.Player1Win;
        }
        return Result.Tie;
    }

    
}