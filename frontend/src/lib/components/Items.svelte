<script>
	import { address, web3 } from '$lib/ethers';
	import { balances } from '$lib/stores';
	import { onMount } from 'svelte';
	import ConnectWallet from './ConnectWallet.svelte';
	import Inventory from './Inventory.svelte';
	import equipmentList from '$lib/equipmentList.json';
import EquipmentCard from './EquipmentCard.svelte';

	let heroManager;

	const updateData = async () => {
		const equipments = Object.keys(equipmentList);
		const _balances = await heroManager.balanceOfBatch(Array(7).fill($address), equipments);

		$balances.equipments = _balances
			.map((b, i) => ({
				id: equipments[i],
				balance: b,
				name: equipmentList[equipments[i]].name
			}))
			.filter((b) => {
				return b.balance.gt(0);
			});
	};

	$: if ($address !== undefined) {
		heroManager = web3.contract('HeroManager');
		updateData();
	}
	$: equipments = $balances.equipments ? $balances.equipments : [];
</script>

<Inventory isHeroes={false}>
	{#if $address === undefined}
		<div class="min-h-screen flex flex-col justify-center items-center">
			<ConnectWallet />
		</div>
	{:else if equipments.length === 0}
		<div class="text-center min-h-screen flex flex-col justify-center items-center">
			<p>you don't have any equipments :(</p>
			<a href="/campaigns" class="link"
				>you can earn them through campaigns or buy them on marketplaces!</a
			>
		</div>
	{:else}
		<div class="flex justify-center items-start gap-1 md:gap-4 flex-wrap p-10 min-h-screen">
			{#each equipments as equipment}
				{#each Array(equipment.balance.toNumber()) as _}
					<EquipmentCard {equipment} />
				{/each}
			{/each}
		</div>
	{/if}
</Inventory>
