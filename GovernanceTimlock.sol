// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title GovernanceTimelock
 * @dev Minimal timelock: owner schedules an operation (target, value, calldata) with a delay.
 * After the delay passes, anyone can execute. This is deliberately simple — replace with OpenZeppelin's
 * TimelockController for production.
 */
import "@openzeppelin/contracts/access/Ownable.sol";

contract GovernanceTimelock is Ownable {
    struct Operation {
        address target;
        uint256 value;
        bytes data;
        uint256 executeAfter; // timestamp
        bool executed;
    }

    mapping(bytes32 => Operation) public operations;
    uint256 public minDelay; // e.g., 2 days

    event OperationScheduled(bytes32 opId, address target, uint256 executeAfter);
    event OperationExecuted(bytes32 opId, address target);

    constructor(uint256 _minDelay) {
        minDelay = _minDelay;
    }

    function schedule(address target, uint256 value, bytes calldata data, uint256 delaySeconds) external onlyOwner returns (bytes32) {
        require(delaySeconds >= minDelay, "Delay too small");
        bytes32 opId = keccak256(abi.encodePacked(target, value, data, block.timestamp));
        require(operations[opId].target == address(0), "Already scheduled");
        operations[opId] = Operation({
            target: target,
            value: value,
            data: data,
            executeAfter: block.timestamp + delaySeconds,
            executed: false
        });
        emit OperationScheduled(opId, target, block.timestamp + delaySeconds);
        return opId;
    }

    function execute(bytes32 opId) external payable returns (bytes memory) {
        Operation storage op = operations[opId];
        require(op.target != address(0), "No such op");
        require(!op.executed, "Already executed");
        require(block.timestamp >= op.executeAfter, "Too early");

        op.executed = true;
        (bool success, bytes memory returndata) = op.target.call{value: op.value}(op.data);
        require(success, "Op execution failed");
        emit OperationExecuted(opId, op.target);
        return returndata;
    }

    // Helper to compute opId client-side with deterministic inputs (target, value, data, timestamp)
    function computeOpId(address target, uint256 value, bytes calldata data, uint256 timestamp) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(target, value, data, timestamp));
    }
}
