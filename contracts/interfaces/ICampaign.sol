// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

interface ICampaign {
    function enlist(uint256 heroId) external;
    function delist(uint256 heroId) external;
    function delistAndClaimRewards(uint256 heroId) external;
}