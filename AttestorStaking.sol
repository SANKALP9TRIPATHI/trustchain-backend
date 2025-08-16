// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title AttestorStaking
 * @dev Simple attestor registry with staking and slashing. Attestors deposit an ERC20 token (protocol token)
 * to register. Owner (later DAO) can slash balances for proven misbehavior.
 *
 * This is intentionally simple: a robust production system would add dispute games, multisig slashing,
 * slashing via on-chain challenges, time-locked exits, and more.
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AttestorStaking is Ownable {
    IERC20 public immutable stakingToken;
    uint256 public immutable minStake; // minimum stake required to register

    mapping(address => uint256) public stakes;
    mapping(address => bool) public registered;

    event Staked(address indexed attestor, uint256 amount);
    event Unstaked(address indexed attestor, uint256 amount);
    event Registered(address indexed attestor);
    event Deregistered(address indexed attestor);
    event Slashed(address indexed attestor, uint256 amount, address indexed to);

    constructor(address _stakingToken, uint256 _minStake) {
        stakingToken = IERC20(_stakingToken);
        minStake = _minStake;
    }

    /// @notice deposit tokens to stake
    function stake(uint256 amount) external {
        require(amount > 0, "Zero stake");
        stakes[msg.sender] += amount;
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit Staked(msg.sender, amount);
    }

    /// @notice register as attestor if stake >= minStake
    function register() external {
        require(stakes[msg.sender] >= minStake, "Insufficient stake");
        require(!registered[msg.sender], "Already registered");
        registered[msg.sender] = true;
        emit Registered(msg.sender);
    }

    /// @notice deregister (attestor remains staked but not registered)
    function deregister() external {
        require(registered[msg.sender], "Not registered");
        registered[msg.sender] = false;
        emit Deregistered(msg.sender);
    }

    /// @notice withdraw stake (only allowed if not registered)
    function unstake(uint256 amount) external {
        require(!registered[msg.sender], "Deregister before unstaking");
        require(amount > 0 && stakes[msg.sender] >= amount, "Bad amount");
        stakes[msg.sender] -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
        emit Unstaked(msg.sender, amount);
    }

    /// @notice owner/DAO slashes an attestor for misbehavior to `to` address
    function slash(address attestor, uint256 amount, address to) external onlyOwner {
        require(amount > 0, "Zero");
        require(stakes[attestor] >= amount, "Insufficient stake");
        stakes[attestor] -= amount;
        // auto-deregister if stake falls below minStake
        if (registered[attestor] && stakes[attestor] < minStake) {
            registered[attestor] = false;
            emit Deregistered(attestor);
        }
        require(stakingToken.transfer(to, amount), "Transfer failed");
        emit Slashed(attestor, amount, to);
    }

    /// @notice view helper
    function isRegisteredAttestor(address a) external view returns (bool) {
        return registered[a];
    }
}
