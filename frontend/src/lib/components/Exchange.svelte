<script lang="ts">
	import { page } from "$app/stores"
	$: isSwap = $page.url.pathname.endsWith("swap")
</script>

<div class="min-h-screen bg-base-200 flex flex-col items-center justify-center p-4">
	<h1 class="text-center font-bold text-5xl pb-6">THE EXCHANGE</h1>
	<div class="container bg-base-100 border max-w-lg rounded-lg">
		<div class="tabs w-full">
			<a href="/swap" class="tab tab-bordered tab-lg w-1/2 font-semibold" class:tab-active={isSwap}>TRADE</a>
			<a href="/liquidity" class="tab tab-bordered tab-lg w-1/2 font-semibold" class:tab-active={!isSwap}>LIQUIDITY</a>
		</div>
    <slot />
	</div>
</div>
