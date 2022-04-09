// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import "./Hero.sol";
import "./interfaces/IRewarder.sol";
import "./libraries/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


contract Legions is Hero, AccessControlEnumerable, Multicall, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using SignedSafeMath for int256;

    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    struct PositionInfo {
        uint256 amount;
        int256 rewardDebt;
        uint256 cooldownTime;
        uint256 prestigeAmount;
        uint256 poolId;
        uint256 level;
    }

    struct PoolInfo {
        uint256 accPrestigePerShare;
        uint256 lastRewardTime;
        uint256 allocPoint;
        string name;
        bool isLP;
        mapping(uint256 => uint256) dailyAccPrestigePerShare;
    }

    struct VestingPrestige {
        uint256 amount;
        uint256 vestingEnd;
        uint256 startTime;
        uint256 claimed;
    }

    /// @notice Address of PRESTIGE contract.
    IERC20 public immutable PRESTIGE;
    /// @notice Info of each Legions pool.
    mapping(uint => PoolInfo) public poolInfo;
    uint256 public poolLength;
    /// @notice Address of the LP token for each Legions pool.
    IERC20[] public lpToken;
    /// @notice Address of each `IRewarder` contract in Legions.
    IRewarder[] public rewarder;

    /// @notice Info of each staked position
    mapping(uint256 => PositionInfo) public positionForId;

    /// @notice ensures the same token isn't added to the contract twice
    mapping(address => bool) public hasBeenAdded;

    /// @notice total balance of prestige inside heroes owned by address
    mapping(address => uint) public totalPrestige;

    mapping(uint256 => VestingPrestige) internal vestingPrestige;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    uint256 public levelUpCooldown = 7 days;
    uint256 public maxLevel = 100;
    uint256 private emissionsPerMillisecond = 2e15;

    uint256 private constant ACC_PRESTIGE_PRECISION = 1e12;
    uint256 private constant MULTIPLIER_PRECISION = 100;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to,
        uint256 heroId
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to,
        uint256 heroId
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to,
        uint256 heroId
    );
    event Harvest(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 heroId
    );
    event LogPoolAddition(
        uint256 pid,
        uint256 allocPoint,
        IERC20 indexed lpToken,
        IRewarder indexed rewarder,
        // address indexed curve,
        bool isLP
    );
    event LogPoolModified(
        uint256 indexed pid,
        uint256 allocPoint,
        IRewarder indexed rewarder,
        // address indexed curve,
        bool isLP
    );
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardTime, uint256 lpSupply, uint256 accPrestigePerShare);
    event LogInit();

    /// @param _prestige The PRESTIGE token contract address.
    constructor(IERC20 _prestige, string memory _baseUri) Hero(_baseUri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        PRESTIGE = _prestige;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControlEnumerable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function changeLevelUpCooldown(uint _newCooldown) public onlyRole(OPERATOR) returns (bool) {
        levelUpCooldown = _newCooldown;
        return true;
    }

    function changeMaxLevel(uint256 _newMaxLevel) public onlyRole(OPERATOR) returns (bool) {
        maxLevel = _newMaxLevel;
        return true;
    }
    
    function changeEmissionsPerMillisecond(uint _newEmissionsPerMillisecond) public onlyRole(OPERATOR) returns (bool) {
        emissionsPerMillisecond = _newEmissionsPerMillisecond;
        return true;
    }

    function addPool(
        uint256 allocPoint,
        IERC20 _lpToken,
        IRewarder _rewarder,
        string memory name,
        bool isLP
    ) public onlyRole(OPERATOR) {
        require(!hasBeenAdded[address(_lpToken)], "this token has already been added");
        require(_lpToken != PRESTIGE, "same token");

        totalAllocPoint += allocPoint;
        lpToken.push(_lpToken);
        rewarder.push(_rewarder);

        PoolInfo storage pool = poolInfo[poolLength++];
        pool.allocPoint = allocPoint;
        pool.lastRewardTime = _timestamp();
        pool.accPrestigePerShare = 0;
        pool.name = name;
        pool.isLP = isLP;

        hasBeenAdded[address(_lpToken)] = true;

        emit LogPoolAddition(
            (lpToken.length - 1),
            allocPoint,
            _lpToken,
            _rewarder,
            isLP
        );
    }

    function modifyPool(
        uint256 pid,
        uint256 allocPoint,
        IRewarder _rewarder,
        string memory name,
        bool isLP,
        bool overwriteRewarder
    ) public onlyRole(OPERATOR) {
        require(pid < poolLength, "set: pool does not exist");
        _updatePool(pid);

        PoolInfo storage pool = poolInfo[pid];
        totalAllocPoint -= pool.allocPoint;
        totalAllocPoint += allocPoint;
        pool.allocPoint = allocPoint;

        if (overwriteRewarder) {
            rewarder[pid] = _rewarder;
        }

        pool.name = name;
        pool.isLP = isLP;

        emit LogPoolModified(
            pid,
            allocPoint,
            overwriteRewarder ? _rewarder : rewarder[pid],
            isLP
        );
    }

    function pendingPrestige(uint256 _heroId) public view returns (uint256 pending) {
        _ensureValidPosition(_heroId);

        PositionInfo storage position = positionForId[_heroId];
        PoolInfo storage pool = poolInfo[position.poolId];
        uint256 accPrestigePerShare = pool.accPrestigePerShare;
        uint256 lpSupply = _poolBalance(position.poolId);

        uint256 millisSinceReward = _timestamp() - pool.lastRewardTime;
        if (millisSinceReward != 0 && lpSupply != 0) {
            uint256 prestigeReward = (millisSinceReward * emissionsPerMillisecond * pool.allocPoint) / totalAllocPoint;
            accPrestigePerShare += (prestigeReward * ACC_PRESTIGE_PRECISION) / lpSupply;
        }

        int256 rawPending = int256((position.amount * accPrestigePerShare) / ACC_PRESTIGE_PRECISION) - position.rewardDebt;
        pending = _calculateEmissions(rawPending.toUInt256(), _heroId);
    }

    function massUpdatePools(uint256[] calldata pids) external nonReentrant {
        for (uint256 i = 0; i < pids.length; i++) {
            _updatePool(pids[i]);
        }
    }

    function updatePool(uint256 pid) external nonReentrant {
        _updatePool(pid);
    }

    function _updatePool(uint256 pid) internal {
        require(pid < poolLength);
        PoolInfo storage pool = poolInfo[pid];
        uint256 millisSinceReward = _timestamp() - pool.lastRewardTime;
        uint256 dayTimestamp = _dayFromTimestamp();

        if (millisSinceReward != 0) {
            uint256 lpSupply = _poolBalance(pid);

            if (lpSupply != 0) {
                uint256 prestigeReward = (millisSinceReward * emissionsPerMillisecond * pool.allocPoint) /
                    totalAllocPoint;
                pool.accPrestigePerShare += (prestigeReward * ACC_PRESTIGE_PRECISION) / lpSupply;
            }

            if (pool.dailyAccPrestigePerShare[dayTimestamp] == 0) {
                pool.dailyAccPrestigePerShare[dayTimestamp] = pool.accPrestigePerShare;
            }
            pool.lastRewardTime = _timestamp();

            emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accPrestigePerShare);
        }
    }

    function createHeroAndDeposit(
        address to,
        uint256 pid,
        uint256 amount
    ) public nonReentrant returns (uint256 id) {
        require(pid < poolLength, "invalid pool ID");
        id = mint(to);
        positionForId[id].poolId = pid;
        positionForId[id].level = 0;
        positionForId[id].cooldownTime = _dayFromTimestamp() + levelUpCooldown;
        _deposit(amount, id);
    }

    function deposit(uint256 amount, uint256 _heroId) external nonReentrant {
        _ensureValidPosition(_heroId);
        _deposit(amount, _heroId);
    }

    function _deposit(uint256 amount, uint256 _heroId) internal {
        require(amount != 0, "depositing 0 amount");
        PositionInfo storage position = positionForId[_heroId];

        _updatePool(position.poolId);
        
        if (position.amount != 0) {
            position.level -= (position.level).min((amount * position.level).ceilDiv(position.amount));
        }

        PoolInfo storage pool = poolInfo[position.poolId];

        position.amount += amount;
        position.rewardDebt += int256((amount * pool.accPrestigePerShare) / ACC_PRESTIGE_PRECISION);

        IRewarder _rewarder = rewarder[position.poolId];
        address to = ownerOf(_heroId);
        if (address(_rewarder) != address(0)) {
            _rewarder.onPrestigeReward(position.poolId, to, to, 0, position.amount);
        }

        lpToken[position.poolId].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, position.poolId, amount, to, _heroId);
    }

    function withdraw(uint256 amount, uint256 _heroId) public nonReentrant {
        _ensureValidPosition(_heroId);
        address to = ownerOf(_heroId);
        require(to == msg.sender, "you do not own this position");
        require(amount != 0, "withdrawing 0 amount");

        PositionInfo storage position = positionForId[_heroId];
        _updatePool(position.poolId);

        PoolInfo storage pool = poolInfo[position.poolId];

        // Effects
        position.rewardDebt -= int256((amount * pool.accPrestigePerShare) / ACC_PRESTIGE_PRECISION);
        position.level -= (position.level).min((amount * position.level).ceilDiv(position.amount));
        uint prestigeAmount = amount * position.prestigeAmount / position.amount;
        position.prestigeAmount -= prestigeAmount;
        totalPrestige[to] -= prestigeAmount;
        position.amount -= amount;

        // Interactions
        IRewarder _rewarder = rewarder[position.poolId];
        if (address(_rewarder) != address(0)) {
            _rewarder.onPrestigeReward(position.poolId, msg.sender, to, 0, position.amount);
        }

        lpToken[position.poolId].safeTransfer(to, amount);
        _vestPrestige(_heroId, prestigeAmount);
        if (position.amount == 0) {
            burn(_heroId);
            delete (positionForId[_heroId]);
        }

        emit Withdraw(msg.sender, position.poolId, amount, to, _heroId);
    }

    function harvest(uint256 _heroId) public nonReentrant {
        _ensureValidPosition(_heroId);
        address to = ownerOf(_heroId);
        require(to == msg.sender, "you do not own this position");

        PositionInfo storage position = positionForId[_heroId];
        _updatePool(position.poolId);

        PoolInfo storage pool = poolInfo[position.poolId];

        int256 accumulatedPrestige = int256((position.amount * pool.accPrestigePerShare) / ACC_PRESTIGE_PRECISION);
        uint256 _pendingPrestige = (accumulatedPrestige - position.rewardDebt).toUInt256();
        uint256 _multipliedPrestige = _calculateEmissions(_pendingPrestige, _heroId);

        // Effects
        position.rewardDebt = accumulatedPrestige;

        // Interactions
        if (_multipliedPrestige != 0) {
            PRESTIGE.safeTransfer(to, _multipliedPrestige);
        }

        IRewarder _rewarder = rewarder[position.poolId];
        if (address(_rewarder) != address(0)) {
            _rewarder.onPrestigeReward(position.poolId, msg.sender, to, _multipliedPrestige, position.amount);
        }

        emit Harvest(msg.sender, position.poolId, _multipliedPrestige, _heroId);
    }

    function withdrawAndHarvest(uint256 amount, uint256 _heroId) public nonReentrant {
        _ensureValidPosition(_heroId);
        address to = ownerOf(_heroId);
        require(to == msg.sender, "you do not own this position");
        require(amount != 0, "withdrawing 0 amount");

        PositionInfo storage position = positionForId[_heroId];
        _updatePool(position.poolId);

        PoolInfo storage pool = poolInfo[position.poolId];
        int256 accumulatedPrestige = int256((position.amount * pool.accPrestigePerShare) / ACC_PRESTIGE_PRECISION);
        uint256 _pendingPrestige = (accumulatedPrestige - position.rewardDebt).toUInt256();
        uint256 _multipliedPrestige = _calculateEmissions(_pendingPrestige, _heroId);

        if (_multipliedPrestige != 0) {
            PRESTIGE.safeTransfer(to, _multipliedPrestige);
        }

        position.rewardDebt = accumulatedPrestige - int256((amount * pool.accPrestigePerShare) / ACC_PRESTIGE_PRECISION);
        position.level -= (position.level).min((amount * position.level).ceilDiv(position.amount));
        uint prestigeAmount = amount * position.prestigeAmount / position.amount;
        position.prestigeAmount -= prestigeAmount;
        totalPrestige[to] -= prestigeAmount;
        position.amount -= amount;

        IRewarder _rewarder = rewarder[position.poolId];
        if (address(_rewarder) != address(0)) {
            _rewarder.onPrestigeReward(position.poolId, msg.sender, to, _multipliedPrestige, position.amount);
        }

        lpToken[position.poolId].safeTransfer(to, amount);
        _vestPrestige(_heroId, prestigeAmount);
        if (position.amount == 0) {
            burn(_heroId);
            delete (positionForId[_heroId]);
        }

        emit Withdraw(msg.sender, position.poolId, amount, to, _heroId);
        emit Harvest(msg.sender, position.poolId, _multipliedPrestige, _heroId);
    }

    function emergencyWithdraw(uint256 _heroId) public nonReentrant {
        _ensureValidPosition(_heroId);
        address to = ownerOf(_heroId);
        require(to == msg.sender, "you do not own this position");

        PositionInfo storage position = positionForId[_heroId];
        uint256 amount = position.amount;
        uint256 prestigeAmount = position.prestigeAmount;

        position.amount = 0;
        position.rewardDebt = 0;
        position.level = 0;
        totalPrestige[to] -= position.prestigeAmount;
        position.prestigeAmount = 0;

        IRewarder _rewarder = rewarder[position.poolId];
        if (address(_rewarder) != address(0)) {
            _rewarder.onPrestigeReward(position.poolId, msg.sender, to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[position.poolId].safeTransfer(to, amount);
        _vestPrestige(_heroId, prestigeAmount);
        burn(_heroId);
        delete (positionForId[_heroId]);

        emit EmergencyWithdraw(msg.sender, position.poolId, amount, to, _heroId);
    }

    function withdrawAll(uint256 _heroId) public nonReentrant {
        _ensureValidPosition(_heroId);
        address to = ownerOf(_heroId);
        require(to == msg.sender, "you do not own this position");

        PositionInfo storage position = positionForId[_heroId];
        _updatePool(position.poolId);

        PoolInfo storage pool = poolInfo[position.poolId];
        int256 accumulatedPrestige = int256((position.amount * pool.accPrestigePerShare) / ACC_PRESTIGE_PRECISION);
        uint256 _pendingPrestige = (accumulatedPrestige - position.rewardDebt).toUInt256();
        uint256 _multipliedPrestige = _calculateEmissions(_pendingPrestige, _heroId);

        if (_multipliedPrestige != 0) {
            PRESTIGE.safeTransfer(to, _multipliedPrestige);
        }

        uint256 amount = position.amount;
        uint256 prestigeAmount = position.prestigeAmount;

        position.rewardDebt = 0;
        position.amount = 0;
        position.level = 0;
        totalPrestige[to] -= prestigeAmount;
        position.prestigeAmount = 0;

        IRewarder _rewarder = rewarder[position.poolId];
        if (address(_rewarder) != address(0)) {
            _rewarder.onPrestigeReward(position.poolId, msg.sender, to, _multipliedPrestige, position.amount);
        }

        lpToken[position.poolId].safeTransfer(to, amount);
        _vestPrestige(_heroId, prestigeAmount);
        if (position.amount == 0) {
            burn(_heroId);
            delete (positionForId[_heroId]);
        }

        emit Withdraw(msg.sender, position.poolId, amount, to, _heroId);
        emit Harvest(msg.sender, position.poolId, _multipliedPrestige, _heroId);
    }

    function multiplier(uint256 _level) public view returns (uint256 _multiplier) {
        _multiplier = ((_level * MULTIPLIER_PRECISION / maxLevel) * 3 / 2) + MULTIPLIER_PRECISION;
    }

    function _vestPrestige(uint256 _heroId, uint256 _amount) internal {
        VestingPrestige storage vest = vestingPrestige[_heroId];

        vest.amount += _amount;
        vest.vestingEnd = block.timestamp + (getLevel(_heroId) * levelUpCooldown);
        vest.startTime = block.timestamp;
    }

    function claimPrestige(uint256 _heroId) public nonReentrant returns (uint256) {
        _ensureValidPosition(_heroId);
        require(ownerOf(_heroId) == msg.sender, "not owner");
        VestingPrestige storage vest = vestingPrestige[_heroId];
        require(vest.amount > 0, "nothing vesting");
        
        uint256 amount = ((vest.vestingEnd - vest.vestingEnd.min(block.timestamp)) * vest.amount) / vest.startTime;
        vest.claimed += amount;
        if (vest.claimed == vest.amount) {
            vest.amount = 0;
            delete vestingPrestige[_heroId];
        }
        
        PRESTIGE.safeTransfer(msg.sender, amount);
        return amount;
    }

    function _calculateEmissions(uint256 amount, uint256 _heroId) internal view returns (uint256 emissions) {
        PositionInfo storage position = positionForId[_heroId];
        emissions = amount * multiplier(position.level) / MULTIPLIER_PRECISION;
    }

    function levelUp(uint256 _heroId) public nonReentrant {
        _ensureValidPosition(_heroId);
        address to = msg.sender;
        require(to == ownerOf(_heroId));
        PositionInfo storage position = positionForId[_heroId];
        require(block.timestamp >= position.cooldownTime, "level up cooldown not over");
        require(position.level < maxLevel, "max level reached");
        _updatePool(position.poolId);

        uint levelUpCost = calculateLevelUpCost(_heroId);
        PRESTIGE.safeTransferFrom(msg.sender, address(this), levelUpCost);
        
        position.cooldownTime += levelUpCooldown;
        position.prestigeAmount += levelUpCost;
        totalPrestige[to] += levelUpCost;
        position.level++;
    }

    function calculateLevelUpCost(uint256 _heroId) public view returns (uint _levelUpCost) {
        PositionInfo storage position = positionForId[_heroId];
        require(block.timestamp >= position.cooldownTime, "levelup on cooldown, use estimateLevelUpCost()");
        PoolInfo storage pool = poolInfo[position.poolId];
        uint rewardsMultiplier = multiplier(position.level);


        _levelUpCost =
            (pool.dailyAccPrestigePerShare[position.cooldownTime] - pool.dailyAccPrestigePerShare[position.cooldownTime - levelUpCooldown])
            * position.amount * rewardsMultiplier / MULTIPLIER_PRECISION / ACC_PRESTIGE_PRECISION;
    }

    function getLevel(uint256 _heroId) public view returns (uint level) {
        return positionForId[_heroId].level;
    }

    function estimateLevelUpCost(uint256 _heroId) external view returns (uint estimatedCost) {
        PositionInfo storage position = positionForId[_heroId];
        PoolInfo storage pool = poolInfo[position.poolId];
        uint lpSupply = _poolBalance(position.poolId);
        uint rewardsMultiplier = multiplier(position.level);
        
        estimatedCost = emissionsPerMillisecond * (position.cooldownTime - position.cooldownTime.min(_dayFromTimestamp())) * 1000 * rewardsMultiplier * pool.allocPoint * position.amount / lpSupply / totalAllocPoint / MULTIPLIER_PRECISION;
        estimatedCost += (pool.dailyAccPrestigePerShare[position.cooldownTime.min(_dayFromTimestamp())] - pool.dailyAccPrestigePerShare[position.cooldownTime - levelUpCooldown])
            * position.amount * rewardsMultiplier / MULTIPLIER_PRECISION / ACC_PRESTIGE_PRECISION;
    }

    function _poolBalance(uint256 pid) internal view returns (uint256 total) {
        total = IERC20(lpToken[pid]).balanceOf(address(this));
    }

    // Converting timestamp to miliseconds so precision isn't lost when we mutate the
    // user's entry time.

    function _timestamp() internal view returns (uint256 timestamp) {
        timestamp = block.timestamp * 1000;
    }

    function _ensureValidPosition(uint256 _heroId) internal view {
        PositionInfo storage position = positionForId[_heroId];
        require(position.amount != 0, "invalid position ID");
    }

    function _dayFromTimestamp() internal view returns (uint256 dayTimestamp) {
        dayTimestamp = block.timestamp - (block.timestamp % 1 days);
    }

    function totalPrestigeAmountForAccount(address _account) external view returns (uint256 amount) {
        amount = totalPrestige[_account];
    }
}