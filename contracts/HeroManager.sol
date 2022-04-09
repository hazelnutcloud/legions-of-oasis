// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IValor is IERC20 {
  function burn(address account, uint256 amount) external returns (bool);
}

contract HeroManager is ERC1155Supply, AccessControlEnumerable, ReentrancyGuard, Multicall, ERC1155Holder {
  using SafeERC20 for IERC20;

  bytes32 public constant MINTER = keccak256("MINTER");
  bytes32 public constant OPERATOR = keccak256("OPERATOR");
  bytes32 public constant EQUIPMENT_MASTER = keccak256("EQUIPMENT_MASTER");

  enum EquipmentSlot {
    Helmet,
    Chest,
    Gauntlet,
    Leg,
    Weapon,
    Talisman,
    Ring
  }

  enum Attribute {
    Strength,
    Intelligence,
    Dexterity,
    Luck,
    Faith,
    PhysicalAtk,
    FireAtk,
    IceAtk,
    BloodAtk,
    HolyAtk,
    PhysicalResistance,
    FireResistance,
    IceResistance,
    BloodResistance,
    HolyResistance,
    MaxHealth,
    MaxMana,
    MaxStamina
  }

  struct HeroInfo {
    uint256 lastLevelAttributeCost;
    mapping(Attribute => uint256) attributeAt;
    mapping(EquipmentSlot => uint256) equipmentAt;
  }

  struct EquipmentInfo {
    EquipmentSlot slot;
    Attribute[] reqAttr;
    uint256[] reqValues;
    Attribute[] boostAttrs;
    uint256[] boostValues;
  }

  IERC721 public legions;
  IValor public immutable valor;
  address public immutable campaignManager;

  mapping(uint256 => HeroInfo) public heroInfo;
  mapping(uint256 => EquipmentInfo) public equipmentInfo;
  mapping(uint256 => string) public equipmentToUri;

  uint256 baseLevelAttributeCost = 100 ether;

  constructor(string memory _uri, IValor _valor, IERC721 _legions, address _campaignManager) ERC1155(_uri) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER, _campaignManager);

    valor = _valor;
    legions = _legions;
    campaignManager = _campaignManager;
  }

  /**
  ACCESS CONTROL FUNCTIONS
   */

  // TODO: only minter role in production
  function mint(address to, uint256 id, uint256 amount) external onlyRole(MINTER) {
    _mint(to, id, amount, "");
  }

  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external onlyRole(MINTER) {
    _mintBatch(to, ids, amounts, "");
  }

  function setLegions(IERC721 _legions) external onlyRole(OPERATOR) {
    legions = _legions;
  }

  function setTokenURI(uint256 _equipmentId, string memory _uri) external onlyRole(OPERATOR) {
    equipmentToUri[_equipmentId] = _uri;
  }

  function setEquipmentInfo(
    uint256 _equipmentId,
    EquipmentInfo calldata _info
  ) external onlyRole(EQUIPMENT_MASTER) returns (bool) {
    equipmentInfo[_equipmentId] = _info;

    return true;
  }

  /**
    PUBLIC STATE-CHANGING FUNCTIONS
   */
  
  function equipItem(uint256 _heroId, uint256 _equipmentId) external nonReentrant returns (bool) {
    require(_ownerOfHero(_heroId) == msg.sender, "not owner of hero");
    require(balanceOf(msg.sender, _equipmentId) != 0, "not owner of equipment");
    require(meetsAttrReq(_heroId, _equipmentId), "insufficient attributes");

    EquipmentSlot slot = equipmentInfo[_equipmentId].slot;

    if (heroInfo[_heroId].equipmentAt[slot] != 0) {
      require(heroInfo[_heroId].equipmentAt[slot] != _equipmentId, "already equipped");
      _unequipItem(msg.sender, _heroId, slot);
    }
    _equipItem(msg.sender, _heroId, _equipmentId, slot);

    return true;
  }

  function unequipItem(uint256 _heroId, EquipmentSlot _slot) external nonReentrant returns (bool) {
    require(_ownerOfHero(_heroId) == msg.sender, "not owner of hero");
    require(heroInfo[_heroId].equipmentAt[_slot] != 0, "nothing equipped");

    _unequipItem(msg.sender, _heroId, _slot);
    return true;
  }

  function levelAttributes(uint256 _heroId, Attribute[] calldata _attrToLevel, uint256[] calldata _levelBy) public nonReentrant returns (bool) {
    require(_ownerOfHero(_heroId) == msg.sender, "not owner of hero");
    require(_attrToLevel.length != 0);
    require(_levelBy.length != 0);
    require(_attrToLevel.length == _levelBy.length);

    HeroInfo storage hero = heroInfo[_heroId];
    uint levelCost;
    if (hero.lastLevelAttributeCost == 0) {
      levelCost = baseLevelAttributeCost;
    } else {
      levelCost = hero.lastLevelAttributeCost;
    }
    uint256 totalCost = 0;

    for (uint i = 0; i < _attrToLevel.length; i++) {
      require(uint(_attrToLevel[i]) >= 0 && uint(_attrToLevel[i]) <= 4, "invalid attribute");
      heroInfo[_heroId].attributeAt[_attrToLevel[i]] += _levelBy[i];
      for(uint j=0; j<_levelBy[i]; j++) {          
        levelCost *= 110;
        levelCost /= 100;
        totalCost += levelCost;
      }
    }
    
    valor.burn(msg.sender, totalCost);
    hero.lastLevelAttributeCost = levelCost;

    return true;
  }

  /**
    PUBLIC VIEW FUNCTIONS
   */

  function meetsAttrReq(uint256 _heroId, uint256 _equipmentId) public view returns (bool) {
    EquipmentInfo storage equipment = equipmentInfo[_equipmentId];
    HeroInfo storage hero = heroInfo[_heroId];

    for (uint i = 0; i < equipment.reqAttr.length; i++) {
      if (hero.attributeAt[equipment.reqAttr[i]] < equipment.reqValues[i]) {
        return false;
      }
    }
    return true;
  }

  function getEquipmentForHeroAt(EquipmentSlot _slot, uint256 _heroId) external view returns (uint256) {
    return heroInfo[_heroId].equipmentAt[_slot];
  }

  function getAttributeForHeroAt(Attribute _attribute, uint256 _heroId) external view returns (uint256) {
    return heroInfo[_heroId].attributeAt[_attribute];
  }

  function tokenURI(uint256 _id) public view returns (string memory) {
    require(exists(_id), "token does not exist");
    return equipmentToUri[_id];
  }

  function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
    return tokenURI(_id);
  }

  function getHeroLastLevelAttributeCost(uint256 _heroId) external view returns (uint256) {
    HeroInfo storage hero = heroInfo[_heroId];
    return hero.lastLevelAttributeCost;
  }

  function getEquipmentsForHero(uint256 _heroId) external view returns (uint256[7] memory) {
    uint256[7] memory equipments;
    EquipmentSlot[7] memory slots = [
      EquipmentSlot.Helmet,
      EquipmentSlot.Chest,
      EquipmentSlot.Gauntlet,
      EquipmentSlot.Leg,
      EquipmentSlot.Weapon,
      EquipmentSlot.Talisman,
      EquipmentSlot.Ring
    ];
    for (uint i=0; i<7; i++) {
      equipments[i] = heroInfo[_heroId].equipmentAt[slots[i]];
    }

    return equipments;
  }

  function getAttributesForHero(uint256 _heroId) external view returns (uint256[18] memory) {
    uint256[18] memory result;
    Attribute[18] memory attributes = [
      Attribute.Strength,
      Attribute.Intelligence,
      Attribute.Dexterity,
      Attribute.Luck,
      Attribute.Faith,
      Attribute.PhysicalAtk,
      Attribute.FireAtk,
      Attribute.IceAtk,
      Attribute.BloodAtk,
      Attribute.HolyAtk,
      Attribute.PhysicalResistance,
      Attribute.FireResistance,
      Attribute.IceResistance,
      Attribute.BloodResistance,
      Attribute.HolyResistance,
      Attribute.MaxHealth,
      Attribute.MaxMana,
      Attribute.MaxStamina
    ];
    for (uint i=0; i<18; i++) {
      result[i] = heroInfo[_heroId].attributeAt[attributes[i]];
    }

    return result;
  }


  /**
    INTERNAL FUNCTIONS
   */

  function _equipItem(address _owner, uint256 _heroId, uint256 _equipmentId, EquipmentSlot _slot) internal returns (bool) {
    heroInfo[_heroId].equipmentAt[_slot] = _equipmentId;

    _updateAttributes(_heroId, _equipmentId);
    safeTransferFrom(_owner, address(this), _equipmentId, 1, "");
    return true;
  }

  function _unequipItem(address _owner, uint256 _heroId, EquipmentSlot _slot) internal returns (bool) {
    uint256 equipmentId = heroInfo[_heroId].equipmentAt[_slot];
    heroInfo[_heroId].equipmentAt[_slot] = 0;

    _resetAttributes(_heroId, equipmentId);
    safeTransferFrom(address(this), _owner, equipmentId, 1, "");
    return true;
  }

  function _updateAttributes(uint256 _heroId, uint256 _equipmentId) internal {
    HeroInfo storage hero = heroInfo[_heroId];
    EquipmentInfo storage equipment = equipmentInfo[_equipmentId];
    
    for (uint i = 0; i < equipment.boostAttrs.length; i++) {
      hero.attributeAt[equipment.boostAttrs[i]] += equipment.boostValues[i];
    }
  }

  function _resetAttributes(uint256 _heroId, uint256 _equipmentId) internal {
    HeroInfo storage hero = heroInfo[_heroId];
    EquipmentInfo storage equipment = equipmentInfo[_equipmentId];
    
    for (uint i = 0; i < equipment.boostAttrs.length; i++) {
      hero.attributeAt[equipment.boostAttrs[i]] -= equipment.boostValues[i];
    }
  }

  function _ownerOfHero(uint256 _heroId) internal view returns (address owner) {
    return legions.ownerOf(_heroId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControlEnumerable, ERC1155Receiver) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}