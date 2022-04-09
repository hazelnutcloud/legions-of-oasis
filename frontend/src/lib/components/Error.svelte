<script>
	import { error, hasError } from '$lib/stores';

	function closeError(index) {
		$error = $error.slice(0,index).concat($error.slice(index + 1))
		if ($error.length === 0) {
			$hasError = false
		}
	}
</script>

{#if $hasError}
	<div class="absolute bottom-4 lg:right-8 max-w-xs flex flex-col-reverse gap-4 w-full">
		{#each $error as _error, index}
			<div class="alert alert-error shadow-lg w-full">
				<div>
					<svg
						xmlns="http://www.w3.org/2000/svg"
						on:click={() => closeError(index)}
						class="stroke-current flex-shrink-0 h-6 w-6 cursor-pointer"
						fill="none"
						viewBox="0 0 24 24"
						><path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
						/></svg
					>
					<span class="max-w-full"
						>Error {`${_error.code}: ${_error.message} ${
							_error.data ? (_error.data.message ? ': ' + _error.data.message : '') : ''
						}`}</span
					>
				</div>
			</div>
		{/each}
	</div>
{/if}
