<script>
    import { page } from "$app/stores";
import Equipment from "$lib/components/Equipment.svelte";

    const id = $page.params.id
</script>

<Equipment {id} />