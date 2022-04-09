<script>
	import { imgSrc } from '$lib/constants';

	import equipmentList from '$lib/equipmentList.json';
	import { address, web3 } from '$lib/ethers';
	import { balances, error } from '$lib/stores';
	import { BigNumber } from 'ethers';

	export let id;
	const equipment = equipmentList[id];
	let heroManager;
	let legions;
	let balance = BigNumber.from(0);
	let selectedHero;
	let allowance = false;

	const equip = async () => {
		try {
			const tx = await heroManager.equipItem(selectedHero, id);
			await tx.wait();
			updateData();
		} catch (e) {
			$error.push(e);
		}
	};

	const approve = async () => {
		try {
			const tx = await heroManager.setApprovalForAll(heroManager.address, true);
			await tx.wait();
			allowance = true;
		} catch (e) {
			$error.push(e);
		}
	};

	const updateData = async () => {
		$balances.hero = await legions.balanceOf($address);
		if ($balances.hero.gt(0)) {
			const queries = [];
			for (let i = 0; i < $balances.hero.toNumber(); i++) {
				const query = legions.tokenOfOwnerByIndex($address, i);
				queries.push(query);
			}
			const result = await Promise.all(queries);
			$balances.heroIds = result.map((r) => r.toNumber());
		}
		allowance = await heroManager.isApprovedForAll($address, heroManager.address);
		balance = await heroManager.balanceOf($address, id);
	};

	$: if ($address !== undefined) {
		heroManager = web3.contract('HeroManager');
		legions = web3.contract('Legions');
		updateData();
	}
	$: heros = $balances.heroIds ? $balances.heroIds : [];
</script>

<div class="flex flex-col justify-center items-center bg-base-200 p-4 gap-4">
	<h1 class="text-5xl font-bold">{equipment.name.toUpperCase()}</h1>
	<div
		class="container max-w-5xl border-2 bg-base-100 flex flex-col justify-center items-center p-4 gap-4 min-h-screen rounded-xl shadow-lg"
	>
		<div class="p-4 rounded-lg border-2 bg-base-300 w-40 h-40 shadow-md">
			<img src={`${imgSrc}equipments/${id}.png`} alt="item" class="w-full pixelated" />
		</div>
		<div
			class="border-2 rounded-xl w-full max-w-xl p-4 flex flex-col justify-start items-center gap-4 shadow-lg"
		>
			<h2 class="font-semibold text-center">Attribute requirements</h2>
			{#each equipment.requiredAttributes as attribute, index}
				<div class="w-full flex justify-between items-start max-w-sm">
					<p>{attribute}</p>
					<p class="font-semibold">{equipment.requiredAttributeValues[index]}</p>
				</div>
			{/each}
			<div class="divider" />
			<h2 class="font-semibold  text-center">Boosted stats</h2>
			{#each equipment.boostedAttributes as attribute, index}
				<div class="w-full flex justify-between items-start max-w-sm">
					<p>{attribute}</p>
					<p class="font-semibold">+{equipment.boostedAttributeValues[index]}</p>
				</div>
			{/each}
			<div class="divider" />
			{#if $address !== undefined}
				{#if balance.gt(0)}
					<h2 class="font-semibold text-center">Equip on your hero</h2>
					<div class="input-group max-w-max">
						<select class="select select-bordered" bind:value={selectedHero}>
							<option disabled selected>Choose a Hero</option>
							{#each heros as hero}
								<option value={hero}>{hero}</option>
							{/each}
						</select>
						{#if !allowance}
							<button class="btn btn-primary" on:click={() => approve()}
								>Approve {equipment.name}</button
							>
						{:else}
							<button class="btn btn-primary" on:click={() => equip()}>Equip</button>
						{/if}
					</div>
				{/if}
				{equipment.name}'s in your inventory: {balance.toString()}
			{/if}
		</div>
	</div>
</div>
