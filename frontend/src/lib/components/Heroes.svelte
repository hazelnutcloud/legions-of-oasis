<script lang="ts">
	import { address, web3 } from '$lib/ethers';
	import { balances, error, hasError } from '$lib/stores';
	import ConnectWallet from './ConnectWallet.svelte';
	import HeroCard from './HeroCard.svelte';
	import Inventory from './Inventory.svelte';

	let legions;

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
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	$: if ($address !== undefined) {
		legions = web3.contract('Legions');
		updateData();
	}
</script>

<Inventory isHeroes={true}>
	{#if $address === undefined}
		<div class="min-h-screen flex flex-col justify-center items-center">
			<ConnectWallet />
		</div>
	{:else if $balances.heroIds.length === 0}
		<div class="text-center min-h-screen flex flex-col justify-center items-center">
			<p>you don't have any heroes :(</p>
			<a href="/summon" class="link">you can summon your first one here!</a>
		</div>
	{:else}
		<div class="flex justify-center items-center gap-20 flex-wrap p-10 gap-y-4 min-h-screen">
			{#each $balances.heroIds as heroId}
				<a href="/hero/{heroId}" sveltekit:prefetch>
					<HeroCard id={heroId} />
				</a>
			{/each}
		</div>
	{/if}
</Inventory>
