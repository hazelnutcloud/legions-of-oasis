<script>
    import equipmentList from '$lib/equipmentList.json'
    export let campaign;
</script>
<div class="card w-96 bg-base-300 shadow-xl border-2">
    <figure class="bg-base-200"><img class="pixelated w-32" src="https://raw.githubusercontent.com/hazelnutcloud/legions-of-oasis-v1/master/sveltekit/static/equipments/{campaign.equipmentRewards[0]}.png" alt="equipment reward"></figure>
    <div class="card-body">
        <h2 class="card-title">#{campaign.id}: "{campaign.name.toUpperCase()}"</h2>
        <p class="font-semibold">Minimum Prestige level:</p>
        <p>{campaign.minLevel}</p>
        <p class="font-semibold">Minimum PRSTG amount:</p>
        <p>{campaign.minPrestige} PRSTG</p>
        <p class="font-semibold">Rewards:</p>
        <ul>
            <li>✨ {campaign.valorRewards} VALOR</li>
            {#each campaign.equipmentRewards as equipment}
                <li>✨ {equipmentList[equipment].name}</li>
            {/each}
        </ul>
        <div class="card-actions justify-end">
            <a href="/campaign/{campaign.id}"><button class="btn btn-primary">Enlist</button></a>
        </div>
    </div>
</div>