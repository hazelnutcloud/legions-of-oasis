<script>
	import { imgSrc } from '$lib/constants';
	export let equipment;
</script>

<a href="/equipment/{equipment.id}">
    <div class="flex flex-col justify-start items-center gap-2 w-28">
        <div class="w-20 h-20 rounded-xl border-2 p-2 bg-base-300 flex justify-center items-center shadow-md">
            <img src={`${imgSrc}equipments/${equipment.id}.png`} class="w-full pixelated" alt="equipment" />
        </div>
        <p class="text-center">{equipment.name}</p>
    </div>
</a>
