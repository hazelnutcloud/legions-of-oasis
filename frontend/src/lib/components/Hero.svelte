<script context="module">
  export const prerender = true;
</script>

<script lang="ts">
  import king from "/static/kingLg.gif";
  import bluepot from "/static/bluepot.png";
  import redpot from "/static/redpot.png";
  import greatsword from "/static/greatsword.png";
  import helmet from "/static/helmet.png";
  import { goto } from "$app/navigation"
</script>

<div class="flex flex-col">
  <div class="hero min-h-screen bg-base-200">
    <div class="hero-content flex-col lg:flex-row-reverse gap-10">
      <img src={king} class="max-h-48 sm:max-h-96" alt="king" />
      <div>
        <h1 class="text-5xl font-bold">ASSEMBLE YOUR <span class="text-primary">HEROES</span>,</h1>
        <h1 class="text-5xl font-bold">CONQUER <span class="text-secondary">OASIS</span>,</h1>
        <h1 class="text-5xl font-bold">CLAIM YOUR <span class="text-accent">SPOILS OF WAR</span>.</h1>
        <p class="py-6">Legions of Oasis is an MMORPG with an integrated DEX built on the Oasis Emerald blockchain. Utilising DeFi at its core, the game is built around its own decentralised exchange where playable NFT characters represent shares of liquidity pools.</p>
        <button class="btn btn-primary font-extrabold" on:click={() => goto("/summon")}>GET STARTED</button>
      </div>
    </div>
  </div>
  <div class="hero min-h-screen bg-base-900">
    <div class="hero-content flex-col lg:flex-row gap-10">
      <div class="flex items-center sm:pr-48">
        <img src={bluepot} class="max-h-48 sm:max-h-50 animate-oscillate-vertical" alt="bluepot" />
        <img src={redpot} class="max-h-48 sm:max-h-50 animate-[oscillate_1s_ease-in-out_0.5s_infinite_alternate]" alt="redpot" />
      </div>
      <div>
        <h1 class="text-5xl font-bold">PROVIDE <span class="text-primary">LIQUIDITY</span>,</h1>
        <h1 class="text-5xl font-bold">SUMMON <span class="text-secondary">HEROES</span>,</h1>
        <h1 class="text-5xl font-bold">EARN <span class="text-accent">REWARDS</span>.</h1>
        <p class="py-6">Providing liquidity to trading pools earn you the right to summon unique NFTs called Heroes. Your Heroes auto-magically earn and accrue rewards from their underlying liquidity pools every second. Use the rewards to level up your Heroes and increase your rewards multiplier, earning you even more rewards.</p>
        <button class="btn btn-primary font-extrabold" on:click={() => goto("/liquidity")}>ADD LIQUIDITY</button>
      </div>
    </div>
  </div>
  <div class="hero min-h-screen bg-base-200">
    <div class="hero-content flex-col lg:flex-row-reverse gap-10">
      <div class="flex items-center min-w-max">
        <img src={greatsword} class="max-h-40 animate-oscillate-vertical" alt="greatsword" />
        <img src={helmet} class="max-h-40 animate-[oscillate_1s_ease-in-out_0.5s_infinite_alternate]" alt="helmet" />
      </div>
      <div>
        <h1 class="text-5xl font-bold">LEVEL UP YOUR <span class="text-primary">HEROES</span>,</h1>
        <h1 class="text-5xl font-bold">EQUIP UNIQUE <span class="text-secondary">ITEMS & WEAPONS</span>,</h1>
        <h1 class="text-5xl font-bold">SEND THEM TO <span class="text-accent">BATTLE</span>.</h1>
        <p class="py-6">Legions of Oasis's core gameplay is revolved around Campaigns. Enlist your heroes in Campaigns to obtain precious resources and special NFTs which you can equip your heroes with to boost their stats. Increasing your Heroes' levels and stats enable them to join more difficult Campaigns and earn even higher tier loot.</p>
        <button class="btn btn-primary font-extrabold" on:click={() => goto("/campaigns")}>JOIN CAMPAIGN</button>
      </div>
    </div>
  </div>
</div>