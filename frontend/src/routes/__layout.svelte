<script>
  import "../app.css";
  import DrawerWrapper from "$lib/components/DrawerWrapper.svelte"
  import { onMount } from 'svelte'
  import { themeChange } from 'theme-change'
  import Footer from "$lib/components/Footer.svelte";
  import Error from "$lib/components/Error.svelte";

  onMount(() => {
    themeChange(false)
  })  
</script>

<DrawerWrapper>
  <slot />
  <Error />
  <Footer />
</DrawerWrapper>