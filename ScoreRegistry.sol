// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ScoreRegistry
 * @dev Stores attestations posted by registered attestors. Attestations are lightweight
 * and contain: wallet, featuresHash (off-chain manifest pointer), score, timestamp, optional metadata.
 *
 * This contract does not perform scoring itself — it stores attestations that can be verified
 * by off-chain consumers. Attestor authorization is handled by an external AttestorStaking contract.
 */

import "@openzeppelin/contracts/access/Ownable.sol";

interface IAttestorStaking {
    function isRegisteredAttestor(address _addr) external view returns (bool);
}

/**
 * @dev Attestation structure:
 * - attestor: address that posted it (must be a registered attestor)
 * - featuresHash: bytes32 pointing to off-chain feature manifest (e.g., IPFS hash mapped in a manifest),
 *                 or hash of features used to produce the score
 * - score: as returned by ScoreCalculator (0..10000)
 * - metadata: optional arbitrary bytes (e.g. model version)
 * - timestamp: block timestamp
 */
contract ScoreRegistry is Ownable {
    IAttestorStaking public attestorRegistry;

    struct Attestation {
        address attestor;
        bytes32 featuresHash;
        uint16 score;
        bytes metadata;
        uint256 timestamp;
    }

    // mapping wallet => list of attestations (append-only)
    mapping(address => Attestation[]) private attestations;

    event AttestationPosted(address indexed wallet, address indexed attestor, bytes32 featuresHash, uint16 score, uint256 timestamp);

    constructor(address _attestorRegistry) {
        attestorRegistry = IAttestorStaking(_attestorRegistry);
    }

    /// @notice change attestor registry (owner/DAO)
    function setAttestorRegistry(address _addr) external onlyOwner {
        attestorRegistry = IAttestorStaking(_addr);
    }

    /// @notice post an attestation for a wallet. Caller must be a registered attestor.
    /// @param wallet the subject wallet
    /// @param featuresHash hash of the feature manifest / IPFS pointer
    /// @param score score value (0..10000)
    /// @param metadata optional metadata (model hash, version, signature reference)
    function postAttestation(
        address wallet,
        bytes32 featuresHash,
        uint16 score,
        bytes calldata metadata
    ) external {
        require(attestorRegistry.isRegisteredAttestor(msg.sender), "Not registered attestor");
        Attestation memory a = Attestation({
            attestor: msg.sender,
            featuresHash: featuresHash,
            score: score,
            metadata: metadata,
            timestamp: block.timestamp
        });
        attestations[wallet].push(a);

        emit AttestationPosted(wallet, msg.sender, featuresHash, score, block.timestamp);
    }

    /// @notice get count of attestations for wallet
    function getAttestationCount(address wallet) external view returns (uint256) {
        return attestations[wallet].length;
    }

    /// @notice get attestation by index
    function getAttestation(address wallet, uint256 index)
        external
        view
        returns (address attestor, bytes32 featuresHash, uint16 score, bytes memory metadata, uint256 timestamp)
    {
        require(index < attestations[wallet].length, "Index OOB");
        Attestation storage a = attestations[wallet][index];
        return (a.attestor, a.featuresHash, a.score, a.metadata, a.timestamp);
    }

    /// @notice get latest (most recent) attestation's score for a wallet
    function getLatestScore(address wallet) external view returns (uint16 score, address attestor, uint256 timestamp) {
        uint256 len = attestations[wallet].length;
        if (len == 0) return (0, address(0), 0);
        Attestation storage a = attestations[wallet][len - 1];
        return (a.score, a.attestor, a.timestamp);
    }
}
