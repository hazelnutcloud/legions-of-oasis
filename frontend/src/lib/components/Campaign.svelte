<script>
	import campaignList from '$lib/campaignList.json';
	import { imgSrc } from '$lib/constants';
	import equipmentList from '$lib/equipmentList.json';
	import { address, web3 } from '$lib/ethers';
	import { secondsToReadable } from '$lib/helpers';
	import { balances, error, hasError } from '$lib/stores';
	import { onMount } from 'svelte';
	import ConnectWallet from './ConnectWallet.svelte';

	export let id;

	const campaign = campaignList[id];

	let legions;
	let chosenHero;
	let chosenDelistHero;
	let chosenClaimHero;
	let campaignContract;
	let campaignApproval;
	let heroesEnlisted = [];
	let heroesFinished = [];

	const enlist = async () => {
		try {
			const tx = await campaignContract.enlist(chosenHero);
			await tx.wait();
			updateData();
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	const delist = async () => {
		try {
			const tx = await campaignContract.delist(chosenDelistHero);
			await tx.wait();
			updateData();
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	const claim = async () => {
		try {
			const tx = await campaignContract.delistAndClaimRewards(chosenClaimHero);
			await tx.wait();
			updateData();
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	const approve = async () => {
		try {
			const tx = await legions.setApprovalForAll(campaignContract.address, true);
			await tx.wait();
			campaignApproval = true;
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	const updateData = async () => {
		$balances.hero = await legions.balanceOf($address);
		const queries = [];
		try {
			for (let i = 0; i < $balances.hero.toNumber(); i++) {
				const query = legions.tokenOfOwnerByIndex($address, i);
				queries.push(query);
			}
			const result = await Promise.all(queries);
			$balances.heroIds = result.map((r) => r.toNumber());
			const _heroesEnlisted = (await campaignContract.getAllEnlistedHeroes($address)).map((n) =>
				n.toNumber()
			);
			heroesFinished = (await campaignContract.getAllFinishedHeroes($address)).map((n) =>
				n.toNumber()
			);
			heroesEnlisted = _heroesEnlisted.filter((h) => {
				return !heroesFinished.includes(h);
			});
			campaignApproval = await legions.isApprovedForAll($address, campaignContract.address);
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	onMount(() => {
		if ($address !== undefined) {
			legions = web3.contract('Legions');
			campaignContract = web3.contract(campaign.contractName);
			updateData();
		}
	});

	$: if ($address !== undefined) {
		legions = web3.contract('Legions');
		campaignContract = web3.contract(campaign.contractName);
		updateData();
	}

	$: heroIds = $balances.heroIds ? $balances.heroIds : [];
</script>

<div class="flex flex-col p-4 justify-center items-center bg-base-200 gap-4">
	<h1 class="font-bold text-5xl text-center">CAMPAIGN #{id}: "{campaign.name.toUpperCase()}"</h1>
	<div
		class="container max-w-5xl rounded-xl bg-base-100 border-2 p-4 shadow-lg min-h-screen flex flex-col md:flex-row justify-center items-center gap-4"
		class:md:flex-col={$address === undefined}
	>
		<div>
			<h2 class="font-semibold text-xl text-center pb-4">Rewards</h2>
			<div class="flex flex-wrap justify-center items-start gap-4">
				{#each campaign.equipmentRewards as equipmentId}
					<div class="w-20 md:w-28">
						<a href="/equipment/{equipmentId}">
							<div class="shadow-md bg-base-300 p-4 w-20 h-20 md:w-28 md:h-28 rounded-xl">
								<img
									src={`${imgSrc}equipments/${equipmentId}.png`}
									class="pixelated w-full"
									alt="equipment reward"
								/>
							</div>
						</a>
						<p class="text-center text-wrap mt-2">{equipmentList[equipmentId].name}</p>
					</div>
				{/each}
			</div>
		</div>
		{#if $address === undefined}
			<ConnectWallet />
		{:else}
			<div class="w-full flex flex-col gap-4">
				<div
					class="w-full border-2 p-4 rounded-xl flex flex-col gap-6 justify-center items-stretch"
				>
					<h2 class="font-semibold text-center">Enlist your Hero</h2>
					<div class="input-group">
						<select class="select select-bordered flex-grow" bind:value={chosenHero}>
							<option disabled selected>Choose your hero</option>
							{#each heroIds as heroId}
								<option value={heroId}>{heroId}</option>
							{/each}
						</select>
						{#if !campaignApproval}
							<button class="btn btn-primary" on:click={() => approve()}>Approve Hero</button>
						{:else}
							<button class="btn btn-primary" on:click={() => enlist()}>Enlist</button>
						{/if}
					</div>
					<div class="flex justify-between items-start flex-wrap">
						<p>minimum Prestige level required:</p>
						<p class="font-semibold">{campaign.minLevel}</p>
					</div>
					<div class="flex justify-between items-start flex-wrap">
						<p>minimum PRSTG amount required:</p>
						<p class="font-semibold">{campaign.minPrestige} PRSTG</p>
					</div>
					<div class="flex justify-between items-start flex-wrap">
						<p>campaign time:</p>
						<p class="font-semibold">{secondsToReadable(campaign.campaignTime)}</p>
					</div>
				</div>
				<div
					class="w-full border-2 p-4 rounded-xl flex flex-col gap-6 justify-center items-stretch"
				>
					<h2 class="font-semibold text-center">Manage your enlisted Heroes</h2>
					<div class="flex justify-between items-start flex-wrap">
						<p>your heroes enlisted:</p>
						<p class="font-semibold">{heroesEnlisted.length}</p>
					</div>
					<div class="input-group">
						<select class="select select-bordered flex-grow" bind:value={chosenDelistHero}>
							<option disabled selected>Choose a hero to delist</option>
							{#each heroesEnlisted as heroId}
								<option value={heroId}>{heroId}</option>
							{/each}
						</select>
						<button class="btn btn-warning" on:click={() => delist()}>Delist</button>
					</div>
					<div class="flex justify-between items-start flex-wrap">
						<p>your heroes finished campaigning:</p>
						<p class="font-semibold">{heroesFinished.length}</p>
					</div>
					<div class="input-group input-group-vertical">
						<select class="select select-bordered flex-grow" bind:value={chosenClaimHero}>
							<option disabled selected>Choose a hero to delist and claim rewards</option>
							{#each heroesFinished as heroId}
								<option value={heroId}>{heroId}</option>
							{/each}
						</select>
						<button class="btn btn-primary" on:click={() => claim()}
							>delist and claim rewards</button
						>
					</div>
				</div>
			</div>
		{/if}
	</div>
</div>
