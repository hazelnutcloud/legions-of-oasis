<script>
	import { address, web3 } from '$lib/ethers';
	import { toFixed, batchUpdateData } from '$lib/helpers';
	import { allowances, balances, error, hasError } from '$lib/stores';
	import { BigNumber, ethers } from 'ethers';
	import { onMount } from 'svelte';
	import ConnectWallet from './ConnectWallet.svelte';
	import hero from '/static/warrior.gif';

	let prstgRose;
	let legions;
	let lpAmount;

	const updateData = async () => {
		await batchUpdateData([
			{
				store: balances,
				key: 'prstgRose',
				callback: prstgRose.balanceOf,
				params: [$address]
			},
			{
				store: balances,
				key: 'hero',
				callback: legions.balanceOf,
				params: [$address]
			},
			{
				store: allowances,
				key: 'prstgRose',
				callback: prstgRose.allowance,
				params: [$address, legions.address]
			}
		]);
	};

	const summon = async () => {
		try {
			const amount = ethers.utils.parseEther(lpAmount.toString());
			const tx = await legions.createHeroAndDeposit($address, '0', amount);
			await tx.wait();
			$balances.hero = $balances.hero.add(1);
			$balances.prstgRose = $balances.prstgRose.sub(amount);
			const queries = [];
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

	const approvePrstgRose = async () => {
		try {
			const tx = await prstgRose.approve(legions.address, ethers.constants.MaxUint256);
			$allowances.prstgRose = ethers.constants.MaxUint256;
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	$: if ($address !== undefined) {
		prstgRose = web3.contract('UniswapV2Pair');
		legions = web3.contract('Legions');
		updateData();
	}

	$: lpBalance = $balances.prstgRose ? ethers.utils.formatEther($balances.prstgRose) : '0';
	$: heroBalance = $balances.hero ? $balances.hero.toString() : '0';
	$: prstgRoseAllowance = $allowances.prstgRose ? $allowances.prstgRose : BigNumber.from('0');
</script>

<div class="flex flex-col justify-center items-center bg-base-200 p-4">
	<h1 class="font-bold text-5xl pb-4 text-center">THE SUMMONING</h1>
	<div
		class="flex flex-col justify-center items-center min-h-screen p-4 bg-base-100 container max-w-5xl rounded-xl border-2 shadow-lg"
	>
		<img src={hero} alt="hero" class="lg:max-h-96 max-h-60 mb-10" />
		<div class="container max-w-lg flex flex-col gap-4 justify-center items-center ">
			<a href="/heroes" class="font-semibold link link-hover">heroes in inventory: {heroBalance}</a>
			<label class="input-group">
				<span class="whitespace-nowrap text-xs sm:text-base">PRSTG-ROSE</span>
				<input
					type="number"
					placeholder="0"
					class="input input-bordered w-full"
					bind:value={lpAmount}
				/>
				<span
					on:click={() => {
						lpAmount = lpBalance;
					}}
					class="cursor-pointer whitespace-nowrap text-xs sm:text-base"
					>balance: {toFixed(lpBalance)}</span
				>
			</label>
			{#if $address !== undefined}
				<button
					class="btn btn-primary"
					on:click={() => {
						prstgRoseAllowance.gt(0) ? (lpAmount > 0 ? summon() : {}) : approvePrstgRose();
					}}
					>{prstgRoseAllowance.gt(0)
						? lpAmount > 0
							? 'summon!'
							: 'enter an amount'
						: 'approve PRSTG-ROSE LP'}</button
				>
			{:else}
				<ConnectWallet />
			{/if}
			<a href="/liquidity" class="link text-sm">get more LP</a>
		</div>
	</div>
</div>
