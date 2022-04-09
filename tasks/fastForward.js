task("fastForward", "forwards the blockchain a given amount of time and mines a new block")
  .addPositionalParam("time", "amount of time to fast forward by")
  .setAction(async ({time},{ethers}) => {
    await network.provider.send('evm_increaseTime', [parseInt(time)]);
    await network.provider.send('evm_mine');
  })