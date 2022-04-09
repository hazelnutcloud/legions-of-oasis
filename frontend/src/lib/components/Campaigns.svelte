<script>
	import { address } from '$lib/ethers';

	import ConnectWallet from './ConnectWallet.svelte';
    import campaignList from '$lib/campaignList.json';
import CampaignCard from './CampaignCard.svelte';
</script>

<div class="flex flex-col bg-base-200 justify-center items-center p-4 gap-4">
	<h1 class="font-bold text-5xl">THE CAMPAIGNS</h1>
	<div
		class="flex flex-wrap gap-10 p-10 justify-center items-center min-h-screen container max-w-5xl bg-base-100 border-2 rounded-xl shadow-lg"
	>
		{#if $address === undefined}
			<ConnectWallet />
		{:else}
            {#each campaignList as campaign}
                <CampaignCard {campaign} />
            {/each}
		{/if}
	</div>
</div>
