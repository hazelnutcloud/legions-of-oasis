<script lang="ts">
	import { web3, address, correctNetwork } from '$lib/ethers';
	import { onMount } from 'svelte';
	import { truncateAddress } from '$lib/helpers';
	import detectEthereumProvider from '@metamask/detect-provider';
	import { ethereum } from '$lib/stores';

	onMount(async () => {
		if ($address === undefined) {
			const provider = await detectEthereumProvider({ mustBeMetaMask: true });
			if (provider) {
				$ethereum = provider;
				if ($ethereum.selectedAddress) {
					web3.connect($ethereum);
				}
			}
		}
	});
</script>

{#if $ethereum == undefined}
	<button class="btn btn-disabled text-white btn-xs sm:btn-md" disabled>no wallet detected</button>
{:else if $correctNetwork == false}
	<button
		class="btn btn-warning text-white btn-xs sm:btn-md"
		on:click={() => web3.changeNetwork($ethereum)}
	>
		switch network
	</button>
{:else if $address === undefined}
	<button
		class="btn btn-primary text-white btn-xs sm:btn-md"
		on:click={() => web3.connect($ethereum)}
	>
		connect wallet
	</button>
{:else}
	<button class="btn btn-primary no-animation text-white btn-xs sm:btn-md">
		{truncateAddress($address)}
	</button>
{/if}
