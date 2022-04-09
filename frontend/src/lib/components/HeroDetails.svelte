<script lang="ts">
	import { address, getBlockTimestamp, web3 } from '$lib/ethers';
	import { attributeMap, generateCooldown, toFixed } from '$lib/helpers';
	import {
		allowances,
		balances,
		error,
		ethereum,
		hasError,
		heroInfos,
		type IHeroInfo
	} from '$lib/stores';
	import { BigNumber, ethers, utils } from 'ethers';
	import { formatEther } from 'ethers/lib/utils';
	import { onMount } from 'svelte';
	import { now } from 'svelte/internal';
	import { writable } from 'svelte/store';
	import AttributeLevel from './AttributeLevel.svelte';

	export let id: number;

	let legions: ethers.Contract;
	let heroManager: ethers.Contract;
	let prstg: ethers.Contract;
	let valor: ethers.Contract;
	let prstgRose: ethers.Contract;
	let attributeLevelBy = writable({
		Strength: 0,
		Intelligence: 0,
		Dexterity: 0,
		Faith: 0,
		Luck: 0
	});
	let lastAttributeLevelCost: ethers.BigNumber;
	let totalCost = '0';
	let owner;
	let pendingPrstg;
	let estimatedLevelUpCost = BigNumber.from(0);
	let desiredWithdraw: BigNumber;
	let desiredDeposit: BigNumber;
	let blockTimestamp = Date.now();
	let cooldown = '...';

	const levelUp = async (id) => {
		try {
			const tx = await legions.levelUp(id);
			await tx.wait();
			updateData();
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	const claimRewards = async () => {
		try {
			const tx = await legions.harvest(id);
			await tx.wait();
			const prstgBalance = await prstg.balanceOf($address);
			const _pendingPrestige = await legions.pendingPrestige(id);
			pendingPrstg = _pendingPrestige;
			$balances.prestige = prstgBalance;
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	const approvePrstg = async () => {
		try {
			const tx = await prstg.approve(legions.address, ethers.constants.MaxUint256);
			await tx.wait;
			$allowances.prestige = ethers.constants.MaxUint256;
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	const approvePrstgRose = async () => {
		try {
			const tx = await prstgRose.approve(legions.address, ethers.constants.MaxUint256);
			await tx.wait();
			$allowances.prstgRose = ethers.constants.MaxUint256;
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	const deposit = async () => {
		try {
			const tx = await legions.deposit(ethers.utils.parseEther(desiredDeposit.toString()), id);
			await tx.wait();
			updateData();
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	const withdraw = async () => {
		try {
			const tx = await legions.withdraw(ethers.utils.parseEther(desiredWithdraw.toString()), id);
			await tx.wait();
			updateData();
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	const withdrawAll = async () => {
		try {
			const tx = await legions.withdrawAll(id);
			await tx.wait();
			updateData();
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	const updateAllowance = async () => {
		const allowance = await prstgRose.allowance($address, legions.address);
		const prstgAllowance = await prstg.allowance($address, legions.address);
		$allowances.prstgRose = allowance;
		$allowances.prestige = prstgAllowance;
	};

	const updateData = async () => {
		const [
			positionInfo,
			attributes,
			equipments,
			prstgBalance,
			valorBalance,
			heroInfo,
			_pendingPrstg,
			estLevelUpCost
		] = await Promise.all([
			legions.positionForId(id),
			heroManager.getAttributesForHero(id),
			heroManager.getEquipmentsForHero(id),
			prstg.balanceOf($address),
			valor.balanceOf($address),
			heroManager.getHeroLastLevelAttributeCost(id),
			legions.pendingPrestige(id),
			legions.estimateLevelUpCost(id)
		]);

		const { name: lpName } = await legions.poolInfo(positionInfo.poolId);
		lastAttributeLevelCost = heroInfo;
		pendingPrstg = _pendingPrstg;
		estimatedLevelUpCost = estLevelUpCost;
		blockTimestamp = await getBlockTimestamp($ethereum);
		cooldown = await generateCooldown(positionInfo.cooldownTime, $ethereum);

		try {
			owner = (await legions.ownerOf(id)).toString().toLowerCase();
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}

		$heroInfos[id] = {
			prestigeAmount: positionInfo.prestigeAmount,
			prestigeLevel: positionInfo.level,
			lpAmount: positionInfo.amount,
			lpName,
			nextLevel: positionInfo.cooldownTime,
			strength: attributes[0],
			intelligence: attributes[1],
			dexterity: attributes[2],
			luck: attributes[3],
			faith: attributes[4],
			physAtk: attributes[5],
			fireAtk: attributes[6],
			iceAtk: attributes[7],
			bloodAtk: attributes[8],
			holyAtk: attributes[9],
			physRes: attributes[10],
			fireRes: attributes[11],
			iceRes: attributes[12],
			bloodRes: attributes[13],
			holyRes: attributes[14],
			maxHealth: attributes[15],
			maxMana: attributes[16],
			maxStamina: attributes[17],
			helmet: equipments[0],
			chest: equipments[1],
			gauntlets: equipments[2],
			legs: equipments[3],
			weapon: equipments[4],
			talisman: equipments[5],
			ring: equipments[6]
		};
		$balances.prestige = prstgBalance;
		$balances.valor = valorBalance;
	};

	const calculateLevelAttributeCost = (lastAttributeLevelCost, totalAttributeLevelBy) => {
		if (totalAttributeLevelBy === 0) {
			return '0';
		}
		let cost = lastAttributeLevelCost === 0 ? 100 : lastAttributeLevelCost;
		let totalCost = 0;
		for (let i = 0; i < totalAttributeLevelBy; i++) {
			cost *= 1100;
			cost /= 1000;
			totalCost += cost;
		}
		return totalCost.toFixed(2);
	};

	const mintValor = async () => {
		const amount = ethers.utils.parseEther('10000');
		const tx = await valor.mint($address, amount);
		await tx.wait();
		$balances.valor = $balances.valor.add(amount);
	};

	const levelAttributes = async () => {
		const chosenAttributes = Object.entries($attributeLevelBy).filter((entry) => {
			return entry[1] > 0;
		});
		const attributesToLevel = chosenAttributes.map((i) => {
			return attributeMap(i[0]);
		});
		const levelBy = chosenAttributes.map((i) => {
			return i[1];
		});

		try {
			const tx = await heroManager.levelAttributes(id, attributesToLevel, levelBy);
			await tx.wait();
		} catch (e) {
			$error.push(e);
			$hasError = true;
			return;
		}
		const [attributes, valorBalance, heroInfo] = await Promise.all([
			heroManager.getAttributesForHero(id),
			valor.balanceOf($address),
			heroManager.getHeroLastLevelAttributeCost(id)
		]);
		lastAttributeLevelCost = heroInfo;

		$heroInfos[id] = {
			...$heroInfos[id],
			strength: attributes[0],
			intelligence: attributes[1],
			dexterity: attributes[2],
			luck: attributes[3],
			faith: attributes[4]
		};
		$attributeLevelBy = {
			Strength: 0,
			Intelligence: 0,
			Dexterity: 0,
			Luck: 0,
			Faith: 0
		};
		$balances.valor = valorBalance;
	};

	$: if ($address !== undefined) {
		legions = web3.contract('Legions');
		heroManager = web3.contract('HeroManager');
		prstg = web3.contract('Prestige');
		valor = web3.contract('Valor');
		prstgRose = web3.contract('UniswapV2Pair');
		updateData();
		if (!$allowances.prstgRose || !$allowances.prestige) updateAllowance();
	}

	$: heroInfo = $heroInfos[id]
		? $heroInfos[id]
		: ({
				prestigeAmount: BigNumber.from(0),
				prestigeLevel: BigNumber.from(0),
				lpAmount: BigNumber.from(0),
				lpName: '?-?',
				nextLevel: BigNumber.from(Date.now()),
				strength: BigNumber.from(0),
				intelligence: BigNumber.from(0),
				dexterity: BigNumber.from(0),
				luck: BigNumber.from(0),
				faith: BigNumber.from(0),
				physAtk: BigNumber.from(0),
				fireAtk: BigNumber.from(0),
				iceAtk: BigNumber.from(0),
				bloodAtk: BigNumber.from(0),
				holyAtk: BigNumber.from(0),
				physRes: BigNumber.from(0),
				fireRes: BigNumber.from(0),
				iceRes: BigNumber.from(0),
				bloodRes: BigNumber.from(0),
				holyRes: BigNumber.from(0),
				maxHealth: BigNumber.from(0),
				maxMana: BigNumber.from(0),
				maxStamina: BigNumber.from(0),
				helmet: BigNumber.from(0),
				chest: BigNumber.from(0),
				gauntlets: BigNumber.from(0),
				legs: BigNumber.from(0),
				weapon: BigNumber.from(0),
				talisman: BigNumber.from(0),
				ring: BigNumber.from(0)
		  } as IHeroInfo);

	$: totalAttributeLevelBy =
		$attributeLevelBy.Strength +
		$attributeLevelBy.Intelligence +
		$attributeLevelBy.Dexterity +
		$attributeLevelBy.Faith +
		$attributeLevelBy.Luck;

	$: if (lastAttributeLevelCost !== undefined && totalAttributeLevelBy >= 0) {
		totalCost = calculateLevelAttributeCost(
			Number(ethers.utils.formatEther(lastAttributeLevelCost)),
			totalAttributeLevelBy
		);
	}
	$: isOwner = $address === owner;
	$: rewardsMultiplier = $heroInfos[id]
		? ($heroInfos[id].prestigeLevel.toNumber() / 100) * 1.5 + 1
		: 1;
	$: prstgRoseAllowance = $allowances.prstgRose ? $allowances.prstgRose : BigNumber.from(0);
	$: prstgAllowance = $allowances.prestige ? $allowances.prestige : BigNumber.from(0);
</script>

<div class="flex flex-col justify-start items-start h-full w-full gap-2">
	<!-- position info -->
	<div class="details">
		<div class="detail">
			<div>Prestige level</div>
			<div class="detail-value">{heroInfo.prestigeLevel.toNumber() + 1}</div>
		</div>
		<div class="detail">
			<div class="tooltip" data-tip="total amount of PRSTG used to level this hero up">
				Prestige value
			</div>
			<div class="detail-value">
				{toFixed(ethers.utils.formatEther(heroInfo.prestigeAmount))} PRSTG
			</div>
		</div>
		<div class="detail">
			<div>Estimated level up cost</div>
			<div class="detail-value">
				{toFixed(ethers.utils.formatEther(estimatedLevelUpCost))} PRSTG
			</div>
		</div>
		<div class="detail flex flex-col">
			<div>Next level up</div>
			<div class="detail-value">{cooldown}</div>
			{#if isOwner}
				{#if heroInfo.nextLevel.toNumber() > blockTimestamp}
					<button class="btn btn-disabled self-end mt-2" disabled>On cooldown</button>
				{:else if prstgAllowance.eq(0)}
					<button class="btn btn-primary self-end mt-2" on:click={() => approvePrstg()}
						>Approve PRSTG to level up</button
					>
				{:else}
					<button class="btn btn-primary self-end mt-2" on:click={() => levelUp(id)}
						>Level up!</button
					>
				{/if}
			{/if}
		</div>
		<div class="detail">
			<div>PRSTG rewards multiplier</div>
			<div class="detail-value">{rewardsMultiplier.toFixed(2)}x</div>
		</div>
		<div class="detail flex justify-between items-center flex-wrap gap-2">
			<div>
				<div>Pending PRSTG rewards</div>
				<div class="detail-value">
					{toFixed(ethers.utils.formatEther(pendingPrstg ? pendingPrstg : BigNumber.from(0)))}
				</div>
			</div>
			{#if isOwner}
				<button class="btn btn-primary" on:click={() => claimRewards()}>Claim rewards</button>
			{/if}
		</div>
		<div class="detail">
			<div>Underlying LP</div>
			<div class="detail-value">
				{toFixed(ethers.utils.formatEther(heroInfo.lpAmount))}{' '}{heroInfo.lpName}
			</div>
			{#if isOwner}
				<div
					class="form-control mt-2 tooltip w-full"
					data-tip="this will reduce your Prestige level!"
				>
					<div class="input-group input-group-sm">
						<input
							type="number"
							class="input input-bordered w-full input-sm"
							min="0"
							placeholder="deposit more LP"
							bind:value={desiredDeposit}
						/>
						{#if prstgRoseAllowance.eq(0)}
							<button class="btn btn-warning btn-sm" on:click={() => approvePrstgRose()}
								>Approve LP</button
							>
						{:else}
							<button class="btn btn-warning btn-sm" on:click={() => deposit()}>Deposit LP</button>
						{/if}
					</div>
				</div>
				<div
					class="flex flex-col items-end gap-2 tooltip"
					data-tip="this will reduce your Prestige level!"
				>
					<div class="form-control mt-2 w-full">
						<div class="input-group input-group-sm">
							<input
								type="number"
								class="input input-bordered input-sm w-full"
								min="0"
								placeholder="withdraw LP"
								bind:value={desiredWithdraw}
							/>
							<button class="btn btn-warning btn-sm" on:click={() => withdraw()}>Withdraw LP</button
							>
						</div>
					</div>
					<button class="btn btn-error btn-sm" on:click={() => withdrawAll()}>withdraw ALL</button>
				</div>
			{/if}
		</div>
	</div>

	<!-- attributes -->
	<div class="flex flex-col p-4 justify-center items-center rounded-lg border-2 w-full">
		<p class="font-semibold txt-lg -my-2 lg:my-0">Attributes</p>
		<div class="divider" />
		<AttributeLevel
			attributeName="Strength"
			attributeValue={heroInfo.strength.toNumber()}
			{attributeLevelBy}
			{isOwner}
		/>
		<AttributeLevel
			attributeName="Intelligence"
			attributeValue={heroInfo.intelligence.toNumber()}
			{attributeLevelBy}
			{isOwner}
		/>
		<AttributeLevel
			attributeName="Dexterity"
			attributeValue={heroInfo.dexterity.toNumber()}
			{attributeLevelBy}
			{isOwner}
		/>
		<AttributeLevel
			attributeName="Faith"
			attributeValue={heroInfo.faith.toNumber()}
			{attributeLevelBy}
			{isOwner}
		/>
		<AttributeLevel
			attributeName="Luck"
			attributeValue={heroInfo.luck.toNumber()}
			{attributeLevelBy}
			{isOwner}
		/>
		{#if isOwner}
			<div class="divider" />
			<div
				class="w-full text-right"
				class:text-red-500={ethers.utils
					.parseEther(totalCost)
					.gt($balances.valor ? $balances.valor : 0)}
			>
				VALOR required to level: {totalCost}
			</div>
			<div class="w-full text-right">
				VALOR in wallet: {toFixed(
					ethers.utils.formatEther($balances.valor ? $balances.valor : BigNumber.from(0))
				)}
			</div>
			<div class="flex justify-end flex-wrap items-center w-full gap-4 pt-4">
				<button
					class="btn btn-primary btn-sm text-sm lg:btn-md lg:text-md"
					on:click={() => mintValor()}>mint VALOR</button
				>
				<button
					class="btn btn-primary btn-sm text-sm lg:btn-md lg:text-md"
					class:btn-disabled={totalAttributeLevelBy === 0}
					disabled={totalAttributeLevelBy === 0}
					on:click={() => levelAttributes()}
					>{totalAttributeLevelBy === 0 ? 'choose attributes to level' : 'level attributes'}</button
				>
			</div>
		{/if}
	</div>
</div>

<style>
	.detail {
		@apply leading-4 p-4 rounded-md border-2 flex-grow;
	}
	.detail-value {
		@apply font-bold text-lg;
	}
	.details {
		@apply flex flex-wrap justify-start items-center gap-2 w-full;
	}
	.divider {
		@apply my-2;
	}
</style>
