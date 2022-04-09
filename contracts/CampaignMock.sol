// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import './interfaces/ICampaign.sol';
import './interfaces/ICampaignManager.sol';
import './interfaces/IHeroManager.sol';
import './interfaces/ILegions.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';

contract CampaignMock is ICampaign, ERC721Holder {
    ICampaignManager public immutable campaignMananger;
    ILegions public immutable legions;

    struct EnlistorInfo {
        address enlistor;
        uint256 enlistTime;
    }

    mapping(uint256 => EnlistorInfo) public heroToEnlistor;
    mapping(uint256 => bool) public heroAlreadyEnlisted;
    mapping(address => mapping(uint256 => uint256)) private _enlistedHeroes;
    mapping(uint256 => uint256) private _enlistedHeroesIndex;
    mapping(address => uint256) public enlistorEnlistedLength;

    uint256 public constant campaignTime = 10 seconds;
    uint256 public enlistorLength;
    uint256 public minLevel;
    uint256 public minPrestige;

    constructor(
        address _campaignManager,
        address _legions,
        uint256 _minLevel,
        uint256 _minPrestige
    ) {
        campaignMananger = ICampaignManager(_campaignManager);
        legions = ILegions(_legions);
        minLevel = _minLevel;
        minPrestige = _minPrestige;
    }

    function enlist(uint256 heroId) external override {
        address from = msg.sender;
        require(legions.ownerOf(heroId) == from);

        EnlistorInfo storage enlistor = heroToEnlistor[heroId];
        require(!heroAlreadyEnlisted[heroId], "hero already enlisted");

        ILegions.PositionInfo memory hero = legions.positionForId(heroId);
        require(hero.level >= minLevel, "level too low");
        require(hero.prestigeAmount >= minPrestige, "prestige too low");

        legions.safeTransferFrom(from, address(this), heroId);

        enlistor.enlistor = from;
        enlistor.enlistTime = block.timestamp;
        heroAlreadyEnlisted[heroId] = true;
        uint256 enlisted = enlistorEnlistedLength[from]++;
        _enlistedHeroesIndex[heroId] = enlisted;
        _enlistedHeroes[from][enlisted] = heroId;
    }

    function delistAndClaimRewards(uint256 heroId) external override {
        address to = msg.sender;

        EnlistorInfo storage enlistor = heroToEnlistor[heroId];
        require(enlistor.enlistor == to, "not owner");
        require(block.timestamp >= enlistor.enlistTime + campaignTime, "not done campaigning");

        delete heroToEnlistor[heroId];
        _removeEnlistedFromEnumeration(to, heroId);

        legions.safeTransferFrom(address(this), to, heroId);

        uint256[] memory equipmentIds = new uint256[](7);
        for (uint i=0; i<7; i++) {
            equipmentIds[i] = i + 1;
        }
        campaignMananger.claimRewards(
            to,
            1000 ether,
            equipmentIds
        );
    }

    function delist(uint256 heroId) external override {
        address to = msg.sender;
        
        EnlistorInfo storage enlistor = heroToEnlistor[heroId];
        require(enlistor.enlistor == to);
        
        delete heroToEnlistor[heroId];
        heroAlreadyEnlisted[heroId] = false;
        _removeEnlistedFromEnumeration(to, heroId);

        legions.safeTransferFrom(address(this), to, heroId);
    }
    
    function getAllEnlistedHeroes(address from) external view returns (uint256[] memory) {
        uint256 length = enlistorEnlistedLength[from];
        uint256[] memory result = new uint256[](length);

        for (uint256 i; i<length; i++) {
            result[i] = _enlistedHeroes[from][i];
        }
        
        return result;
    }

    function getAllFinishedHeroes(address from) external view returns (uint256[] memory) {
        uint256 length = enlistorEnlistedLength[from];
        uint256[] memory result = new uint256[](length);
        uint256 resultLength = 0;

        for (uint256 i; i<length; i++) {
            uint256 id = _enlistedHeroes[from][i];
            if (heroToEnlistor[id].enlistTime + campaignTime < block.timestamp) {
                result[i] = id;
                resultLength++;
            }
        }

        uint256[] memory newResult = new uint256[](resultLength);
        for (uint256 i; i<resultLength; i++) {
            newResult[i] = result[i];
        }
        return newResult;
    }

    function _removeEnlistedFromEnumeration(address from, uint256 heroId) private {
        uint256 lastEnlistedIndex = --enlistorEnlistedLength[from];
        uint256 heroEnlistedIndex = _enlistedHeroesIndex[heroId];

        if (heroEnlistedIndex != lastEnlistedIndex) {
            uint256 lastEnlistedId = _enlistedHeroes[from][lastEnlistedIndex];

            _enlistedHeroes[from][heroEnlistedIndex] = lastEnlistedId;
            _enlistedHeroesIndex[lastEnlistedId] = heroEnlistedIndex;
        }

        delete _enlistedHeroes[from][lastEnlistedIndex];
        delete _enlistedHeroesIndex[heroId];
    }
}