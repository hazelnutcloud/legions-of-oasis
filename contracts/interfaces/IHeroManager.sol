// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

interface IHeroManager {
    function getAttributesForHero(uint256 _heroId) external view returns (uint256[18] memory);
}