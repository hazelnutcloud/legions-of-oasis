<script lang="ts">
	import { address, web3 } from '$lib/ethers';
	import { batchUpdateData, toFixed } from '$lib/helpers';
	import { allowances, balances, error, hasError } from '$lib/stores';
	import { BigNumber, ethers } from 'ethers';
	import { onMount } from 'svelte';
	import ConnectWallet from './ConnectWallet.svelte';

	let choice = true;
	let prstg: ethers.Contract;
	let rose: ethers.Contract;
	let router: ethers.Contract;
	let pair: ethers.Contract;
	let desiredFrom = '0';
	let desiredTo = '0';
	let insufficientLiquidity = false;

	const updateBalances = async () => {
		await batchUpdateData([
			{
				store: balances,
				key: 'prestige',
				callback: prstg.balanceOf,
				params: [$address]
			},
			{
				store: balances,
				key: 'rose',
				callback: rose.balanceOf,
				params: [$address]
			},
			{
				store: allowances,
				key: 'prestige',
				callback: prstg.allowance,
				params: [$address, router.address]
			},
			{
				store: allowances,
				key: 'rose',
				callback: rose.allowance,
				params: [$address, router.address]
			}
		]);
	};

	const getAmountOut = async () => {
		if ($address !== undefined) {
			const [prstgReserves, roseReserves] = await pair.getReserves();
			try {
				desiredTo = ethers.utils.formatEther(
					await router.getAmountOut(
						ethers.utils.parseEther(desiredFrom.toString()),
						choice ? roseReserves : prstgReserves,
						choice ? prstgReserves : roseReserves
					)
				);
			} catch (e) {
				insufficientLiquidity = true;
				$error.push(e);
				$hasError = true;
			}
		}
	};

	const approveFrom = async () => {
		if (choice) {
			try {
				await rose.approve(router.address, ethers.constants.MaxUint256);
				$allowances.rose = ethers.constants.MaxUint256;
			} catch (e) {
				$error.push(e);
				$hasError = true;
			}
		} else {
			try {
				await prstg.approve(router.address, ethers.constants.MaxUint256);
				$allowances.prestige = ethers.constants.MaxUint256;
			} catch (e) {
				$error.push(e);
				$hasError = true;
			}
		}
	};

	const swap = async () => {
		try {
			const tx = await router.swapExactTokensForTokens(
				ethers.utils.parseEther(desiredFrom.toString()),
				ethers.utils.parseEther(desiredTo.toString()).mul('90').div('100'),
				[choice ? rose.address : prstg.address, choice ? prstg.address : rose.address],
				$address,
				(Date.now() + 10).toString()
			);
			await tx.wait();
			updateBalances();
		} catch (e) {
			$error.push(e);
			$hasError = true;
		}
	};

	$: if ($address !== undefined) {
		prstg = web3.contract('Prestige');
		rose = web3.contract('Rose');
		router = web3.contract('UniswapV2Router02');
		pair = web3.contract('UniswapV2Pair');
		updateBalances();
	}

	$: from = choice ? 'ROSE' : 'PRSTG';
	$: to = choice ? 'PRSTG' : 'ROSE';
	$: fromBalance = choice
		? $balances.rose
			? ethers.utils.formatEther($balances.rose)
			: '0'
		: $balances.prestige
		? ethers.utils.formatEther($balances.prestige)
		: '0';
	$: toBalance = choice
		? $balances.prestige
			? ethers.utils.formatEther($balances.prestige)
			: '0'
		: $balances.rose
		? ethers.utils.formatEther($balances.rose)
		: '0';
	$: currentAllowance = choice
		? $allowances.rose
			? $allowances.rose
			: BigNumber.from('0')
		: $allowances.prestige
		? $allowances.prestige
		: BigNumber.from('0');
</script>

<div class="p-10 flex flex-col justify-center items-center shadow-xl">
	<div class="form-control">
		<label class="input-group">
			<span class="whitespace-nowrap text-xs sm:text-base">{from}</span>
			<input
				type="number"
				placeholder="0"
				class="input input-bordered w-full"
				bind:value={desiredFrom}
				on:change={() => getAmountOut()}
			/>
			<span
				on:click={() => {
					desiredFrom = fromBalance;
					getAmountOut();
				}}
				class="cursor-pointer whitespace-nowrap text-xs sm:text-base"
				>balance: {toFixed(fromBalance)}</span
			>
		</label>
	</div>
	<label class="swap swap-rotate py-4">
		<input type="checkbox" on:change={() => (choice = !choice)} />
		<svg
			xmlns="http://www.w3.org/2000/svg"
			viewBox="0 0 16 16"
			width="16px"
			height="16px"
			class="fill-current swap-on"
			><path
				transform="scale(0.03125 0.03125)"
				d="M374.6 310.6l-160 160C208.4 476.9 200.2 480 192 480s-16.38-3.125-22.62-9.375l-160-160c-12.5-12.5-12.5-32.75 0-45.25s32.75-12.5 45.25 0L160 370.8V64c0-17.69 14.33-31.1 31.1-31.1S224 46.31 224 64v306.8l105.4-105.4c12.5-12.5 32.75-12.5 45.25 0S387.1 298.1 374.6 310.6z"
			/></svg
		>
		<svg
			xmlns="http://www.w3.org/2000/svg"
			viewBox="0 0 16 16"
			width="16px"
			height="16px"
			class="fill-current swap-off"
			><path
				transform="scale(0.03125 0.03125)"
				d="M374.6 310.6l-160 160C208.4 476.9 200.2 480 192 480s-16.38-3.125-22.62-9.375l-160-160c-12.5-12.5-12.5-32.75 0-45.25s32.75-12.5 45.25 0L160 370.8V64c0-17.69 14.33-31.1 31.1-31.1S224 46.31 224 64v306.8l105.4-105.4c12.5-12.5 32.75-12.5 45.25 0S387.1 298.1 374.6 310.6z"
			/></svg
		>
	</label>
	<div class="form-control">
		<label class="input-group">
			<span class="whitespace-nowrap text-xs sm:text-base">{to}</span>
			<input
				type="number"
				placeholder="0"
				class="input input-bordered w-full"
				bind:value={desiredTo}
			/>
			<span class="whitespace-nowrap text-xs sm:text-base">balance: {toFixed(toBalance)}</span>
		</label>
	</div>
	{#if $address !== undefined}
		{#if insufficientLiquidity}
			<button class="btn btn-disabled mt-4" disabled>insufficient liquidity</button>
		{:else if currentAllowance.eq(0)}
			<button class="btn btn-primary mt-4" on:click={() => approveFrom()}>approve {from}</button>
		{:else}
			<button class="btn btn-primary mt-4" on:click={() => swap()}>swap</button>
		{/if}
	{:else}
		<div class="mt-4">
			<ConnectWallet />
		</div>
	{/if}
</div>
