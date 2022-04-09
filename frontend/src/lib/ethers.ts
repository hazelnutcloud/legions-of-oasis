import { ethers } from 'ethers';
import addresses from '$lib/contracts/addresses.json';
import abis from '$lib/contracts/abis.json';
import { writable, type Writable } from 'svelte/store';
import { balances, error } from './stores';

const targetId = '0x7a69';

export const address = writable() as Writable<string>
export const correctNetwork = writable()

export let signer: ethers.Signer
export let provider: ethers.providers.JsonRpcProvider

let polledIntervals = []

export const web3 = {
	async connect(ethereum: any): Promise<void> {
		const [selectedAddress] = await ethereum.request({ method: 'eth_requestAccounts' });

		if (!(await this.checkNetwork(ethereum))) {
			return
		}

		this.initializeEthers(ethereum);
		address.set(selectedAddress)

		ethereum.on('accountsChanged', ([newAddress]) => {
			if (newAddress == undefined) {
				address.set(undefined)
				return;
			}
			balances.set({
				rose: undefined,
				prestige: undefined,
				valor: undefined
			})
			address.set(newAddress);
		});

		ethereum.on('chainChanged', async (_) => {
			this.stopPollingData();
			const chainId = await ethereum.request({ method: 'eth_chainId' });
			if (chainId !== targetId) {
				correctNetwork.set(false)
			} else {
				correctNetwork.set(true)
			}
		});
		return;
	},

	async changeNetwork(ethereum: any) {
		try {
			await ethereum.request({
				method: 'wallet_switchEthereumChain',
				params: [{ chainId: targetId }]
			});
			correctNetwork.set(true)
			this.connect(ethereum)
		} catch (switchError) {
			if (switchError.code === 4902 || switchError.message.startsWith("Unrecognized chain ID")) {
				try {
					await ethereum.request({
						method: 'wallet_addEthereumChain',
						params: [
							{
								chainId: targetId,
								chainName: 'Oasis Emerald Testnet',
								rpcUrls: ['https://testnet.emerald.oasis.dev']
							}
						]
					});
					correctNetwork.set(true)
					this.connect(ethereum)
				} catch (addError) {
					error.set(addError)
				}
			} else {
				error.set(switchError)
			}
		}
	},

	stopPollingData() {
		polledIntervals.forEach((interval) => {
			clearInterval(interval);
		});
		polledIntervals = []
	},

	addPollingData(callback) {
		const interval = setInterval(callback)
		polledIntervals.push(interval)
	},

	contract(name: string) {
		return new ethers.Contract(addresses[name], abis[name], signer);
	},

	async checkNetwork(ethereum): Promise<boolean> {
		const chainId = await ethereum.request({ method: 'eth_chainId' });
		if (chainId !== targetId) {
			correctNetwork.set(false)
			return false;
		}
		return true;
	},

	initializeEthers(ethereum: any) {
		provider = new ethers.providers.Web3Provider(ethereum)
		signer = provider.getSigner(0)
	}
}

export async function getBlockTimestamp(ethereum: any) {
	const blockNumber = await ethereum.request({ method: "eth_blockNumber" })
	const block = await ethereum.request({
		method: "eth_getBlockByNumber",
		params: [blockNumber, false]
	})
	const blockTimestamp = block.timestamp
	return Number(blockTimestamp)
}
