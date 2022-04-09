<script>
	export let attributeName;
	export let attributeValue;
	export let attributeLevelBy;
	export let isOwner;
</script>

<div class="flex justify-between items-center w-full pb-4">
	<div class="detail">
		<div>{attributeName}</div>
		<div class="detail-value" class:text-green-500={$attributeLevelBy[attributeName] > 0}>
			{attributeValue + 1 + $attributeLevelBy[attributeName]}
		</div>
	</div>
	{#if isOwner}
		<div class="input-group max-w-max">
			<button
				class="btn btn-primary btn-sm font-bold"
				on:click={() => {
					if ($attributeLevelBy[attributeName] === 0) {
						return;
					} else {
						$attributeLevelBy[attributeName] -= 1;
					}
				}}>-</button
			>
			<input
				bind:value={$attributeLevelBy[attributeName]}
				type="number"
				min="0"
				placeholder="0"
				class="w-10 text-center"
			/><button
				class="btn btn-primary btn-sm font-bold"
				on:click={() => {
					$attributeLevelBy[attributeName] += 1;
				}}>+</button
			>
		</div>
	{/if}
</div>

<style>
	.detail {
		@apply w-full text-base;
	}
	.detail-value {
		@apply font-bold text-xl;
	}
</style>
