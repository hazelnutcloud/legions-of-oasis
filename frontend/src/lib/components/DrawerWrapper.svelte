<script lang="ts">
  import NavBar from "./NavBar.svelte";
</script>

<div class="drawer">
  <input type="checkbox" id="my-drawer-3" class="drawer-toggle">
  <div class="drawer-content flex flex-col">
    <NavBar />
    <slot />
  </div>
  <div class="drawer-side">
    <label for="my-drawer-3" class="drawer-overlay"></label>
    <ul class="menu p-4 overflow-y-auto w-60 md:w-80 bg-base-300 font-semibold">
      <li class="border-b-2"><a href="/swap">EXCHANGE</a></li>
      <li class="border-b-2"><a href="/summon">SUMMON</a></li>
      <li class="border-b-2"><a href="/heroes">INVENTORY</a></li>
      <li class="border-b-2"><a href="/campaigns">CAMPAIGNS</a></li>
    </ul>
  </div>
</div>

