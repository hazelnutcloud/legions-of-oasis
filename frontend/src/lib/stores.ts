import type { BigNumber } from "ethers";
import { writable, type Writable } from "svelte/store";

interface IBalances {
  rose?: BigNumber;
  prestige?: BigNumber;
  valor?: BigNumber;
  prstgRose?: BigNumber;
  hero?: BigNumber;
  heroIds?: number[];
  equipments?: IEquipmentBalance[];
}

interface IAllowances {
  rose?: BigNumber;
  prestige?: BigNumber;
  valor?: BigNumber;
  prstgRose?: BigNumber;
  hero?: BigNumber;
}

export interface IEquipmentBalance {
  id: number;
  balance: BigNumber;
}

export interface IHeroInfo {
  prestigeLevel: BigNumber;
  prestigeAmount: BigNumber;
  lpAmount: BigNumber;
  lpName: string;
  nextLevel: BigNumber;
  helmet: BigNumber;
  chest: BigNumber;
  gauntlets: BigNumber;
  legs: BigNumber;
  weapon: BigNumber;
  talisman: BigNumber;
  ring: BigNumber;
  maxHealth: BigNumber;
  maxMana: BigNumber;
  maxStamina: BigNumber;
  strength: BigNumber;
  intelligence: BigNumber;
  dexterity: BigNumber;
  luck: BigNumber;
  faith: BigNumber;
  physAtk: BigNumber;
  fireAtk: BigNumber;
  iceAtk: BigNumber;
  bloodAtk: BigNumber;
  holyAtk: BigNumber;
  physRes: BigNumber;
  fireRes: BigNumber;
  iceRes: BigNumber;
  bloodRes: BigNumber;
  holyRes: BigNumber;
}

export const error: Writable<any> = writable([])
export const hasError: Writable<boolean> = writable(false)
export const balances: Writable<IBalances> = writable({
  rose: undefined,
  prestige: undefined,
  valor: undefined,
  prstgRose: undefined,
  hero: undefined,
  heroIds: [],
  equipments: undefined
})
export const allowances: Writable<IAllowances> = writable({
  rose: undefined,
  prestige: undefined,
  valor: undefined,
  prstgRose: undefined,
  hero: undefined,
})
export const ethereum: Writable<any> = writable()
export const heroInfos: Writable<IHeroInfo[]> = writable([])