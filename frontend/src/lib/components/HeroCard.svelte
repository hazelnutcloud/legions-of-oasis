<script lang="ts">
	import { address, web3 } from '$lib/ethers';
	import { toFixed } from '$lib/helpers';
	import { heroInfos, type IHeroInfo } from '$lib/stores';
	import { BigNumber, ethers } from 'ethers';
	import { onMount } from 'svelte';
	import { imgSrc } from '$lib/constants';

	import card from '/static/hero/card.png';
	import hero from '/static/hero/hero1.gif';

	export let id;

	let legions;
	let heroManager;
	let heroInfo: IHeroInfo;
	let loading = true;

	const updateData = async () => {
		const [positionInfo, attributes, equipments] = await Promise.all([
			legions.positionForId(id),
			heroManager.getAttributesForHero(id),
			heroManager.getEquipmentsForHero(id)
		]);
		const { name: lpName } = await legions.poolInfo(positionInfo.poolId);

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
		loading = false;
	};

	$: if ($address !== undefined) {
		legions = web3.contract('Legions');
		heroManager = web3.contract('HeroManager');
		updateData();
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
</script>

{#if !loading}
	<svg
		width="398"
		height="800"
		viewBox="0 0 199 400"
		xmlns="http://www.w3.org/2000/svg"
		class="h-full w-full"
	>
		<style>
			@import url('https://fonts.googleapis.com/css2?family=Press+Start+2P&amp;display=swap');
			.img {
				image-rendering: pixelated;
			}
			.text {
				dominant-baseline: middle;
				font-family: 'Press Start 2P', 'Courier New', Courier, monospace;
			}
			.text-center {
				text-anchor: middle;
			}
			.text-right {
				text-anchor: end;
			}
			.descr {
				word-spacing: -0.3rem;
				font-size: 0.6rem;
			}
		</style>
		<image href={card} height="400" width="199" class="img" />
		<text class="text text-center" x="50%" y="80" font-size="5" fill="white">
			#{id.toString()} PRESTIGE LEVEL {heroInfo.prestigeLevel.toNumber() + 1}
		</text>
		<text class="text text-center" x="50%" y="89" font-size="3" fill="#AAA">
			TOTAL PRSTG: {toFixed(ethers.utils.formatEther(heroInfo.prestigeAmount))}
		</text>
		<text class="text text-center" x="50%" y="95" font-size="3" fill="#AAA">
			UNDERLYING LP: {toFixed(ethers.utils.formatEther(heroInfo.lpAmount))}
			{heroInfo.lpName}
		</text>
		<text class="text text-center" x="50%" y="101" font-size="3" fill="#AAA">
			NEXT LEVEL UP: {new Date(heroInfo.nextLevel.toNumber() * 1000).toLocaleDateString('en-UK')}
		</text>
		<image x="81" y="134" width="38" height="57.5" href={hero} />
		{#if heroInfo.helmet.toString() !== '0'}
			<a href="/equipment/{heroInfo.helmet.toString()}">
				<image
					x="37.4"
					y="136.4"
					width="16"
					height="16"
					href={`${imgSrc}/equipments/${heroInfo.helmet.toString()}.png`}
				/>
			</a>
		{/if}
		{#if heroInfo.chest.toString() !== '0'}
			<a href="/equipment/{heroInfo.chest.toString()}">
				<image
					x="37.4"
					y="175.4"
					width="16"
					height="16"
					href={`${imgSrc}/equipments/${heroInfo.chest.toString()}.png`}
				/>
			</a>
		{/if}
		{#if heroInfo.ring.toString() !== '0'}
			<a href="/equipment/{heroInfo.ring.toString()}">
				<image
					x="37.6"
					y="213.4"
					width="16"
					height="16"
					href={`${imgSrc}/equipments/${heroInfo.ring.toString()}.png`}
				/>
			</a>
		{/if}
		{#if heroInfo.weapon.toString() !== '0'}
			<a href="/equipment/{heroInfo.weapon.toString()}">
				<image
					x="92.3"
					y="213.4"
					width="16"
					height="16"
					href={`${imgSrc}/equipments/${heroInfo.weapon.toString()}.png`}
				/>
			</a>
		{/if}
		{#if heroInfo.talisman.toString() !== '0'}
			<a href="/equipment/{heroInfo.talisman.toString()}">
				<image
					x="145.8"
					y="213.4"
					width="16"
					height="16"
					href={`${imgSrc}/equipments/${heroInfo.talisman.toString()}.png`}
				/>
			</a>
		{/if}
		{#if heroInfo.legs.toString() !== '0'}
			<a href="/equipment/{heroInfo.legs.toString()}">
				<image
					x="145.8"
					y="175.1"
					width="16"
					height="16"
					href={`${imgSrc}/equipments/${heroInfo.legs.toString()}.png`}
				/>
			</a>
		{/if}
		{#if heroInfo.gauntlets.toString() !== '0'}
			<a href="/equipment/{heroInfo.gauntlets.toString()}">
				<image
					x="145.8"
					y="135.8"
					width="16"
					height="16"
					href={`${imgSrc}/equipments/${heroInfo.gauntlets.toString()}.png`}
				/>
			</a>
		{/if}
		<text x="101" y="255.7" class="text text-right" font-size="4" fill="white">
			{heroInfo.maxHealth.toNumber() + 100}
		</text>
		<text x="101" y="267.4" class="text text-right" font-size="4" fill="white">
			{heroInfo.maxStamina.toNumber() + 80}
		</text>
		<text x="101" y="279.4" class="text text-right" font-size="4" fill="white">
			{heroInfo.intelligence.toNumber() + 1}
		</text>
		<text x="101" y="291.4" class="text text-right" font-size="4" fill="white">
			{heroInfo.luck.toNumber() + 1}
		</text>
		<text x="168" y="255.7" class="text text-right" font-size="4" fill="white">
			{heroInfo.maxMana.toNumber() + 50}
		</text>
		<text x="168" y="267.4" class="text text-right" font-size="4" fill="white">
			{heroInfo.strength.toNumber() + 1}
		</text>
		<text x="168" y="279.4" class="text text-right" font-size="4" fill="white">
			{heroInfo.dexterity.toNumber() + 1}
		</text>
		<text x="168" y="291.4" class="text text-right" font-size="4" fill="white">
			{heroInfo.faith.toNumber() + 1}
		</text>
		<text x="168" y="311" class="text text-right" font-size="4" fill="white">
			{heroInfo.physAtk.toNumber()}/{heroInfo.physRes.toNumber()}
		</text>
		<text x="168" y="325" class="text text-right" font-size="4" fill="white">
			{heroInfo.fireAtk.toNumber()}/{heroInfo.fireRes.toNumber()}
		</text>
		<text x="168" y="339" class="text text-right" font-size="4" fill="white">
			{heroInfo.iceAtk.toNumber()}/{heroInfo.iceRes.toNumber()}
		</text>
		<text x="168" y="353" class="text text-right" font-size="4" fill="white">
			{heroInfo.bloodAtk.toNumber()}/{heroInfo.bloodRes.toNumber()}
		</text>
		<text x="168" y="367" class="text text-right" font-size="4" fill="white">
			{heroInfo.holyAtk.toNumber()}/{heroInfo.holyRes.toNumber()}
		</text>
	</svg>
{:else}
	<div class="h-full w-full flex justify-center items-center">loading...</div>
{/if}
