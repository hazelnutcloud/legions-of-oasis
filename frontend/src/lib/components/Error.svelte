<script>
	import { error } from '$lib/stores';
</script>

{#if $error.length !== 0}
	<div class="absolute bottom-4 right-8 max-w-xs flex flex-col-reverse gap-4">
		{#each $error as error}
			<div class="alert alert-error shadow-lg absolute bottom-4 right-8 w-full">
				<div>
					<svg
						xmlns="http://www.w3.org/2000/svg"
						on:click={() => (error = undefined)}
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
					<span class="truncate max-w-full"
						>Error {`${error.code}: ${error.message} ${
							error.data ? (error.data.message ? ': ' + error.data.message : '') : ''
						}`}</span
					>
				</div>
			</div>
		{/each}
	</div>
{/if}
