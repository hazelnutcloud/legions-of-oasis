<script>
	export let isHeroes;
</script>

<h1 class="text-center font-bold text-5xl ">THE INVENTORY</h1>
<div
	class="container bg-base-100 flex flex-col justify-center items-center max-w-5xl rounded-xl border shadow-lg"
>
	<div class="container bg-base-100 tabs flex justify-around max-w-5xl rounded-xl rounded-b-none">
		<a class="tab tab-bordered tab-lg font-semibold text-lg w-1/2" class:tab-active={isHeroes} href="/heroes">HEROES</a>
		<a class="tab tab-bordered tab-lg font-semibold text-lg w-1/2" class:tab-active={!isHeroes} href="/equipments">EQUIPMENTS</a>
	</div>
	<slot />
</div>
