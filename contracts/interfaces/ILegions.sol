// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface ILegions is IERC721 {
    struct PositionInfo {
        uint256 amount;
        int256 rewardDebt;
        uint256 cooldownTime;
        uint256 prestigeAmount;
        uint256 poolId;
        uint256 level;
    }
    function positionForId(uint256 id) external view returns (PositionInfo memory);
}