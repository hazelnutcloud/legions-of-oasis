// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

interface ICampaignManager {
    function claimRewards(
        address to,
        uint256 valorAmount,
        uint256[] memory equipmentIds
    ) external;
}