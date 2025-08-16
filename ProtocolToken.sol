// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ProtocolToken (OCT)
 * @dev Simple ERC20 token used for staking, governance, and fees.
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProtocolToken is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_, uint256 initialSupply) ERC20(name_, symbol_) {
        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply);
        }
    }

    /// @notice mint function controlled by owner (DAO multisig) for treasury operations.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
