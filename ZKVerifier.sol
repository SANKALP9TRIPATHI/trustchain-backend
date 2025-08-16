// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ZKVerifierRegistry
 * @dev Registry of approved ZK verifier contracts. Consumers can call `verify` which delegates to the verifier.
 * The registry only controls which verifier implementations are trusted; verification logic lives in verifier contracts.
 */

import "@openzeppelin/contracts/access/Ownable.sol";

interface IVerifier {
    /// @notice Verify a proof with given public inputs
    /// @param proof opaque proof bytes (verifier-specific)
    /// @param publicInputs ABI-encoded public inputs (verifier-specific)
    /// @return bool true if proof verifies
    function verify(bytes calldata proof, bytes calldata publicInputs) external view returns (bool);
}

contract ZKVerifierRegistry is Ownable {
    // mapping verifierAddress => enabled
    mapping(address => bool) public verifiers;

    event VerifierAdded(address verifier);
    event VerifierRemoved(address verifier);

    function addVerifier(address verifier) external onlyOwner {
        require(verifier != address(0), "Zero address");
        require(!verifiers[verifier], "Already added");
        verifiers[verifier] = true;
        emit VerifierAdded(verifier);
    }

    function removeVerifier(address verifier) external onlyOwner {
        require(verifiers[verifier], "Not present");
        verifiers[verifier] = false;
        emit VerifierRemoved(verifier);
    }

    /// @notice Delegate verification to a trusted verifier.
    /// @dev Reverts if verifier is not approved or verifier.verify returns false.
    /// @param verifier address of verifier contract (must be approved)
    /// @param proof opaque proof bytes
    /// @param publicInputs ABI-encoded public inputs
    function verifyWith(address verifier, bytes calldata proof, bytes calldata publicInputs) external view returns (bool) {
        require(verifiers[verifier], "Verifier not approved");
        return IVerifier(verifier).verify(proof, publicInputs);
    }
}
