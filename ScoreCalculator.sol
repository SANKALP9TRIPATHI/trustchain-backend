// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ScoreCalculator
 * @dev Deterministic scoring contract. Stores score weights and computes a 0..10000 score (two decimals)
 * from provided normalized feature values (each expected as 0..10000). Public, transparent and auditable.
 *
 * NOTE: This contract is intentionally simple and deterministic. Off-chain ML outputs should be posted
 * as attestations in ScoreRegistry (see other contracts).
 */

import "@openzeppelin/contracts/access/Ownable.sol";

contract ScoreCalculator is Ownable {
    // Score precision: scores and feature values are represented with 2-decimal fixed point
    // Example: 100.00 => 10000
    uint16 public constant PRECISION = 100; // representation multiplier for 2 decimals (100 -> 2 decimals -> 10000)
    uint16 public constant BASE_SCALE = 10000; // input features normalized to [0, 10000]

    // weights sum is not required to be 1.0; final score is scaled by (BASE_SCALE)
    // weights are expressed with same fixed precision as features (0..10000)
    uint16[] public weights;

    event WeightsUpdated(uint16[] newWeights);
    event ScoreComputed(address indexed caller, uint256 score);

    /// @notice set the weights array. Owner only (DAO multisig).
    /// @param _weights array of weights in fixed point (e.g. 3000 => 30.00)
    function setWeights(uint16[] calldata _weights) external onlyOwner {
        // optional: add limit on number of weights
        weights = _weights;
        emit WeightsUpdated(_weights);
    }

    /// @notice compute deterministic score from normalized features
    /// @param normalizedFeatures array of features normalized to [0, 10000]
    /// @return score uint256 scaled to [0, 10000] (i.e., 100.00 == 10000)
    function computeScore(uint16[] calldata normalizedFeatures) external view returns (uint256) {
        require(weights.length > 0, "Weights not set");
        require(normalizedFeatures.length == weights.length, "Feature/weight length mismatch");

        // use uint256 accumulator
        uint256 acc = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            // weight * normalizedFeature -> both up to 10000 => product up to 1e8 fits in uint256
            acc += uint256(weights[i]) * uint256(normalizedFeatures[i]);
        }

        // acc is sum(weights_i * feature_i) with each in fixed-point 1e4 * 1e4 = 1e8
        // To rescale, divide by BASE_SCALE (10000), so final range ~ 0..10000*SUM(weights)/10000
        // We return (acc / BASE_SCALE) / sum(weightsNormalization) ... simpler approach:
        // Compute sumWeights and normalize:
        uint256 sumWeights = 0;
        for (uint256 j = 0; j < weights.length; j++) {
            sumWeights += uint256(weights[j]);
        }
        require(sumWeights > 0, "Sum weights zero");

        // finalScore = (acc / sumWeights)  / BASE_SCALENormalized
        // acc / sumWeights gives feature-weighted average scaled by 1e4
        uint256 finalScore = acc / sumWeights; // still scaled by 1e4
        // finalScore is in the 0..10000 range (as desired)
        return finalScore;
    }

    /// @notice helper view to get weight count
    function getWeightsCount() external view returns (uint256) {
        return weights.length;
    }

    /// @notice compute and emit event (for convenience)
    function computeAndEmit(uint16[] calldata normalizedFeatures) external returns (uint256) {
        uint256 s = computeScore(normalizedFeatures);
        emit ScoreComputed(msg.sender, s);
        return s;
    }
}
