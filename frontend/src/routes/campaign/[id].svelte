<script>
import { page } from "$app/stores";
import Campaign from "$lib/components/Campaign.svelte";


    const id = Number($page.params.id)
</script>

    <Campaign {id} />