// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../utils/Context.sol";


contract TwoColorBallV1 is Context {
    string _name;
    string _symbol;
    uint256 _cycle;

    mapping(uint256 => address) winner;

    mapping(address => uint) prize_pool;
    

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function get_block() public view returns (uint) {
        return block.difficulty;
    }

    // bet on
    function bet_on( ) public {}

    // reveal

    function reveal() public {}



}