<script lang="ts">
	import { address, web3 } from '$lib/ethers';
	import { batchUpdateData, toFixed } from '$lib/helpers';
	import { allowances, balances, error } from '$lib/stores';
	import { BigNumber, ethers } from 'ethers';
	import { onMount } from 'svelte';
	import ConnectWallet from './ConnectWallet.svelte';

	let prstg: ethers.Contract;
	let rose: ethers.Contract;
	let prstgRose: ethers.Contract;
	let router: ethers.Contract;
	let desiredPrstg = '0';
	let desiredRose = '0';

	const updateBalances = async () => {
		await batchUpdateData([
			{
				store: balances,
				key: "prestige",
				callback: prstg.balanceOf,
				params: [$address]
			},
			{
				store: balances,
				key: "rose",
				callback: rose.balanceOf,
				params: [$address]
			},
			{
				store: balances,
				key: "prstgRose",
				callback: prstgRose.balanceOf,
				params: [$address]
			},
			{
				store: allowances,
				key: "prestige",
				callback: prstg.allowance,
				params: [$address, router.address]
			},
			{
				store: allowances,
				key: "rose",
				callback: rose.allowance,
				params: [$address, router.address]
			},
		])
	}

	const updateRoseIn = async () => {
		if ($address !== undefined) {
			try {
				const [prstgReserves, roseReserves] = await prstgRose.getReserves();
				if (prstgReserves.gt(0) || roseReserves.gt(0)) {
					const ratio = Number(ethers.utils.formatEther(roseReserves)) / Number(ethers.utils.formatEther(prstgReserves))
					desiredRose = (Number(desiredPrstg) * ratio).toString();
				}
			} catch (e) {
				$error.push(e);
			}
		}
	}

	const updatePrstgIn = async () => {
		if ($address !== undefined) {
			try {
				const [prstgReserves, roseReserves] = await prstgRose.getReserves();
				if (prstgReserves.gt(0) || roseReserves.gt(0)) {
					const ratio = Number(ethers.utils.formatEther(prstgReserves)) / Number(ethers.utils.formatEther(roseReserves))
					desiredPrstg = (Number(desiredRose) * ratio).toString();
				}
			} catch (e) {
				$error.push(e);
			}
		}
	}

	const approveRose = async () => {
		try {
			await rose.approve(router.address, ethers.constants.MaxUint256);
			$allowances.rose = ethers.constants.MaxUint256;
		} catch (e) {
			$error.push(e);
		}
	};

	const approvePrstg = async () => {
		try {
			await prstg.approve(router.address, ethers.constants.MaxUint256);
			$allowances.prestige = ethers.constants.MaxUint256;
		} catch (e) {
			$error.push(e);
		}
	};

	const addLiquidity = async () => {
		try {
			const tx = await router.addLiquidity(
				rose.address,
				prstg.address,
				ethers.utils.parseEther(desiredRose.toString()),
				ethers.utils.parseEther(desiredPrstg.toString()),
				ethers.utils.parseEther(desiredRose.toString()).mul('50').div('100'),
				ethers.utils.parseEther(desiredPrstg.toString()).mul('50').div('100'),
				$address,
				(Date.now() + 10).toString()
			);
			await tx.wait()
			updateBalances()
		} catch (e) {
			$error.push(e);
		}
	};

	const mintRose = async () => {
		try {
			const amount = ethers.utils.parseEther('100');
			await rose.mint($address, amount);
			$balances.rose = amount;
		} catch (e) {
			$error.push(e);
		}
	};

	const mintPrstg = async () => {
		try {
			const amount = ethers.utils.parseEther('100');
			await prstg.mint($address, amount);
			$balances.prestige = amount;
		} catch (e) {
			$error.push(e);
		}
	};

	$: if ($address !== undefined) {
		prstg = web3.contract('Prestige');
		rose = web3.contract('Rose');
		router = web3.contract('UniswapV2Router02');
		prstgRose = web3.contract('UniswapV2Pair');
		updateBalances();
	}

	$: prstgBalance = $balances.prestige ? ethers.utils.formatEther($balances.prestige) : '0';
	$: roseBalance = $balances.rose ? ethers.utils.formatEther($balances.rose) : '0';
	$: prstgRoseBalance = $balances.prstgRose ? ethers.utils.formatEther($balances.prstgRose) : '0';
	$: prstgAllowance = $allowances.prestige ? $allowances.prestige : BigNumber.from('0');
	$: roseAllowance = $allowances.rose ? $allowances.rose : BigNumber.from('0');
</script>

<div class="p-10 w-full flex flex-col justify-center items-center shadow-xl">
	{#if $address !== undefined}
		{#if Number(prstgBalance) === 0 || Number(roseBalance) === 0}
			<p class="text-center pb-4">since this is a demo, get some free tokens!</p>
			<div class="flex items-center justify-between pb-4 gap-4">
				{#if Number(roseBalance) < 10}
					<button class="btn btn-primary" on:click={() => mintRose()}>mint ROSE</button>
				{/if}
				{#if Number(prstgBalance) < 10}
					<button class="btn btn-primary" on:click={() => mintPrstg()}>mint PRSTG</button>
				{/if}
			</div>
		{/if}
	{/if}
	<div class="form-control pb-4">
		<label class="input-group">
			<span class="whitespace-nowrap text-xs sm:text-base">PRSTG</span>
			<input
				type="number"
				placeholder="0"
				class="input input-bordered w-full"
				bind:value={desiredPrstg}
				on:change={() => updateRoseIn()}
			/>
			<span
				on:click={() => {desiredPrstg = prstgBalance; updateRoseIn()}}
				class="cursor-pointer whitespace-nowrap text-xs sm:text-base"
				>balance: {toFixed(prstgBalance)}</span
			>
		</label>
	</div>
	<svg
		xmlns="http://www.w3.org/2000/svg"
		class="fill-current"
		viewBox="0 0 16 16"
		width="16px"
		height="16px"
		><path
			transform="scale(0.03125 0.03125)"
			d="M0 256C0 114.6 114.6 0 256 0C397.4 0 512 114.6 512 256C512 397.4 397.4 512 256 512C114.6 512 0 397.4 0 256zM256 368C269.3 368 280 357.3 280 344V280H344C357.3 280 368 269.3 368 256C368 242.7 357.3 232 344 232H280V168C280 154.7 269.3 144 256 144C242.7 144 232 154.7 232 168V232H168C154.7 232 144 242.7 144 256C144 269.3 154.7 280 168 280H232V344C232 357.3 242.7 368 256 368z"
		/></svg
	>
	<div class="form-control pt-4">
		<label class="input-group">
			<span class="whitespace-nowrap text-xs sm:text-base">ROSE</span>
			<input
				type="number"
				placeholder="0"
				class="input input-bordered w-full"
				on:change={() => updatePrstgIn()}
				bind:value={desiredRose}
			/>
			<span
				on:click={() => {desiredRose = roseBalance; updatePrstgIn()}}
				class="cursor-pointer whitespace-nowrap text-xs sm:text-base"
				>balance: {toFixed(roseBalance)}</span
			>
		</label>
	</div>
	{#if $address !== undefined}
		<div class="flex items-center justify-between pt-4 gap-4">
			{#if roseAllowance.gt(0) && prstgAllowance.gt(0)}
				{#if Number(desiredPrstg) === 0 || Number(desiredRose) === 0}
					<button class="btn btn-disabled" disabled>enter amount</button>
				{:else}
					<button class="btn btn-primary" on:click={() => addLiquidity()}>add liquidity</button>
				{/if}
			{:else}
				{#if roseAllowance.eq(0)}
					<button class="btn btn-primary" on:click={() => approveRose()}>approve ROSE</button>
				{/if}
				{#if prstgAllowance.eq(0)}
					<button class="btn btn-primary" on:click={() => approvePrstg()}>approve PRSTG</button>
				{/if}
			{/if}
		</div>
		<p class="pt-4">PRSTG-ROSE LP balance: {toFixed(prstgRoseBalance)}</p>
		{#if Number(prstgRoseBalance) > 0}
			<p class="pt-4">next step: <a href="/summon" class="link">summon a hero</a>!</p>
		{/if}
	{:else}
		<div class="pt-4">
			<ConnectWallet />
		</div>
	{/if}
</div>
