import type { BigNumber } from "ethers";
import type { Writable } from "svelte/store";
import { getBlockTimestamp } from "./ethers";
import { error } from "./stores";

export function truncateAddress(address: string): string {
  return `${address.slice(0, 6)}...${address.slice(address.length - 5)}`
}

export function toFixed(num: string, decimalPlaces: number = 3): string {
  return num.slice(0, num.indexOf(".") + decimalPlaces + 1)
}

interface IBatchUpdateDataParams {
  store: Writable<any>;
  key: string;
  callback: any;
  params: any[];
}

export async function batchUpdateData(params: IBatchUpdateDataParams[]): Promise<void> {
  const res = await Promise.allSettled(
    params.map(p => {
      return p.callback(...p.params)
    })
  )
  res.forEach((r, i) => {
    if (r.status === "fulfilled") {
      params[i].store.update(s => {
        s[params[i].key] = r.value
        return s
      })
    } else {
      error.set(r.reason)
    }
  })
}

export function attributeMap(attribute: string) {
  const map = {
    "strength" : 0,
    "intelligence": 1,
    "dexterity": 2,
    "luck": 3,
    "faith": 4
  }
  return map[attribute.toLowerCase()];
}

export async function generateCooldown(cooldown: BigNumber, ethereum: any): Promise<string>  {
  const timestamp = cooldown.toNumber() - await getBlockTimestamp(ethereum)
  
  const days =  Math.floor(timestamp / 86400)
  const hours = Math.floor((timestamp % 86400) / 3600)
  const minutes = Math.floor((timestamp % 3600) / 60)
  const seconds = Math.floor(timestamp % 60)
  return `${days > 0 ? days + " days : " : ''}${timestamp / 3600 > 0 ? hours + " hours : " : ''}${timestamp / 3600 > 0 ? minutes + " minutes : " : ''}${seconds + " seconds"}`
}

export function secondsToReadable(time: number) {
  const days =  Math.floor(time / 86400)
  const hours = Math.floor((time % 86400) / 3600)
  const minutes = Math.floor((time % 3600) / 60)
  const seconds = Math.floor(time % 60)
  return `${days > 0 ? days + " days : " : ''}${time / 3600 > 0 ? hours + " hours : " : ''}${time / 3600 > 0 ? minutes + " minutes : " : ''}${seconds + " seconds"}`
}