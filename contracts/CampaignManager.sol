// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import './interfaces/ICampaignManager.sol';

interface IValor {
    function mint(address to, uint256 amount) external;
}

interface IHeroManager {
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function mint(address to, uint256 amount) external;
}

contract CampaignManager is AccessControlEnumerable, ICampaignManager {
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    mapping(uint256 => address) public campaignIdToContract;
    mapping(address => bool) public contractIsCampaign;

    uint256 campaignsLength;

    IValor public valor;
    IHeroManager public heroManager;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
        Operator-only functions
     */

    function setValor(address _valor) external onlyRole(OPERATOR) {
        valor = IValor(_valor);
    }

    function setHeroManager(address _heroManager) external onlyRole(OPERATOR) {
        heroManager = IHeroManager(_heroManager);
    }

    function addCampaign(address campaign)
        external
        onlyRole(OPERATOR)
        returns (uint256)
    {
        campaignIdToContract[campaignsLength++] = campaign;
        contractIsCampaign[campaign] = true;
        return campaignsLength;
    }

    /**
        Campaign-restricted functions
     */

    function claimRewards(
        address to,
        uint256 valorAmount,
        uint256[] memory equipmentIds
    ) external {
        require(contractIsCampaign[msg.sender]);

        uint256[] memory amounts = new uint[](equipmentIds.length);
        for (uint256 i=0; i<equipmentIds.length; i++) {
            amounts[i] = 1;
        }

        valor.mint(to, valorAmount);
        heroManager.mintBatch(to, equipmentIds, amounts);
    }
}
