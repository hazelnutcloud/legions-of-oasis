<script>
	import { page } from '$app/stores';
	import ConnectWallet from '$lib/components/ConnectWallet.svelte';
	import HeroCard from '$lib/components/HeroCard.svelte';
	import HeroDetails from '$lib/components/HeroDetails.svelte';
	import { address } from '$lib/ethers';

	const id = Number($page.params.id);
</script>

<div class="flex flex-col justify-center items-center p-4 bg-base-200">
	<h1 class="font-bold text-5xl pb-4">HERO #{id}</h1>
	<div
		class="flex flex-col md:flex-row justify-center items-center gap-4 p-10 container border-2 rounded-xl bg-base-100 max-w-5xl shadow-lg"
	>
		{#if $address !== undefined}
			<div class="h-full w-full">
				<HeroCard {id} />
			</div>
			<div class="divider divider-horizontal" />
			<HeroDetails {id} />
		{:else}
			<div class="h-screen w-full flex justify-center items-center"><ConnectWallet /></div>
		{/if}
	</div>
</div>
