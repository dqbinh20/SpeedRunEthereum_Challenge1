// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
	ExampleExternalContract public exampleExternalContract;
	mapping(address => uint256) public balances;
	uint256 public constant threshold = 1 ether;
	uint256 public deadline = block.timestamp + 72 hours;
	bool public openForWithdraw = false;

	event Stake(address, uint256);
	event Withdraw(address, uint256);

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);
	}

	function stake() public payable {
		balances[msg.sender] += msg.value;
		emit Stake(msg.sender, msg.value);
	}

	function execute() public returns (uint256) {
		if (!metThreshold()) {
			openForWithdraw = true;
			return 1;
		}
		if (block.timestamp >= deadline) {
			exampleExternalContract.complete{ value: address(this).balance }();
			return 0;
		}
		openForWithdraw = false;
		return 1;
	}

	function withdraw() public payable {
		require(timeLeft() == 0, "deadline not met yet");
		require(!metThreshold(), "threshold not met yet");
		uint256 amount = balances[msg.sender];
		require(amount > 0, "you don't have a balance");
		(bool sent, ) = msg.sender.call{ value: amount }("");
		require(sent, "Failed to send Ether");
		balances[msg.sender] = 0;
		emit Withdraw(msg.sender, amount);
	}

	function timeLeft() public view returns (uint256) {
		if (block.timestamp >= deadline) return 0;
		return deadline - block.timestamp;
	}

	function metThreshold() public view returns (bool) {
		return address(this).balance >= threshold;
	}

	receive() external payable {
		stake();
	}
}
