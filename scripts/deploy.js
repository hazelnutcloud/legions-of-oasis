// This is a script for deploying your contracts. You can adapt it to deploy

const { ethers } = require("hardhat");

// yours, or create new ones.
async function main() {
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  // ethers is available in the global scope
  const [deployer] = await ethers.getSigners();

  const deployerAddress = await deployer.getAddress();
  console.log(
    "Deploying the contracts with the account:",
    deployerAddress
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Prestige = await ethers.getContractFactory("Prestige");
  const prestige = await Prestige.deploy();
  await prestige.deployed();
  await prestige.mint("0x08d6A1d7f3715f442e8e9dbe80CB6f0139c2735e", ethers.utils.parseEther("1000000000"))

  const Rose = await ethers.getContractFactory("Rose");
  const rose = await Rose.deploy();
  await rose.deployed();
  await rose.mint("0x08d6A1d7f3715f442e8e9dbe80CB6f0139c2735e", ethers.utils.parseEther("1000000000"))

  const UniV2Factory = await ethers.getContractFactory('UniswapV2Factory')
  const uniV2Factory = await UniV2Factory.deploy('0x0000000000000000000000000000000000000000');
  await uniV2Factory.deployed()

  let tx = await uniV2Factory.createPair(prestige.address, rose.address)
  await tx.wait()
  const pairAddress = await uniV2Factory.getPair(prestige.address, rose.address)
  const Pair = await ethers.getContractFactory('UniswapV2Pair')
  const pair = Pair.attach(pairAddress)

  const UniV2Router = await ethers.getContractFactory("UniswapV2Router02")
  const uniV2Router = await UniV2Router.deploy(uniV2Factory.address, '0x0000000000000000000000000000000000000000')
  await uniV2Router.deployed()

  const Legions = await ethers.getContractFactory("Legions");
  const legions = await Legions.deploy(prestige.address, '0x0000000000000000000000000000000000000000');
  await legions.deployed();

  await prestige.mint(legions.address, ethers.utils.parseEther("1000000000"))

  const operatorRole = legions.OPERATOR()
  await legions.grantRole(operatorRole, deployerAddress)
  await legions.addPool(
    500,
    pair.address,
    '0x0000000000000000000000000000000000000000',
    'PRSTG-ROSE',
    true
  )

  const CampaignManager = await ethers.getContractFactory("CampaignManager");
  const campaignManager = await CampaignManager.deploy();
  await campaignManager.deployed();

  const Valor = await ethers.getContractFactory("contracts/Valor.sol:Valor");
  const valor = await Valor.deploy();
  await valor.deployed();

  const HeroManager = await ethers.getContractFactory("HeroManager");
  const heroManager = await HeroManager.deploy("testUri", valor.address, legions.address, campaignManager.address);
  await heroManager.deployed();

  await campaignManager.grantRole(operatorRole, deployerAddress)
  await campaignManager.setValor(valor.address)
  await campaignManager.setHeroManager(heroManager.address)

  const CampaignMock = await ethers.getContractFactory("CampaignMock")
  const campaignMock = await CampaignMock.deploy(campaignManager.address, legions.address, 1, ethers.utils.parseEther("10"))
  await campaignMock.deployed()

  await campaignManager.addCampaign(campaignMock.address);

  const equipmentMasterRole = await heroManager.EQUIPMENT_MASTER();
  const heroManagerOperatorRole = await heroManager.OPERATOR();
  const minterRole = await heroManager.MINTER();
  await heroManager.grantRole(equipmentMasterRole, deployerAddress)
  await heroManager.grantRole(heroManagerOperatorRole, deployerAddress)
  await heroManager.grantRole(minterRole, deployerAddress)

  await heroManager.setEquipmentInfo(
    1, //equipment ID
    [
      0, //equipment slot
      [0], //required attributes
      [1], //required attribute values
      [10], //boosted attributes
      [5] //boosted attribute values
    ]
  )
  await heroManager.setEquipmentInfo(
    2, //equipment ID
    [
      1, //equipment slot
      [0], //required attributes
      [1], //required attribute values
      [10], //boosted attributes
      [10] //boosted attribute values
    ]
  )
  await heroManager.setEquipmentInfo(
    3, //equipment ID
    [
      2, //equipment slot
      [0], //required attributes
      [1], //required attribute values
      [10], //boosted attributes
      [4] //boosted attribute values
    ]
  )
  await heroManager.setEquipmentInfo(
    4, //equipment ID
    [
      3, //equipment slot
      [0], //required attributes
      [1], //required attribute values
      [10], //boosted attributes
      [8] //boosted attribute values
    ]
  )
  await heroManager.setEquipmentInfo(
    5, //equipment ID
    [
      4, //equipment slot
      [0], //required attributes
      [1], //required attribute values
      [5], //boosted attributes
      [10] //boosted attribute values
    ]
  )
  await heroManager.setEquipmentInfo(
    6, //equipment ID
    [
      5, //equipment slot
      [], //required attributes
      [], //required attribute values
      [0], //boosted attributes
      [1] //boosted attribute values
    ]
  )
  await heroManager.setEquipmentInfo(
    7, //equipment ID
    [
      6, //equipment slot
      [0], //required attributes
      [1], //required attribute values
      [15, 17], //boosted attributes
      [20, 10] //boosted attribute values
    ]
  )

  // await prestige.approve(uniV2Router.address, ethers.constants.MaxUint256)
  // await rose.approve(uniV2Router.address, ethers.constants.MaxUint256)
  // await uniV2Router.addLiquidity(
  //   prestige.address,
  //   rose.address,
  //   ethers.utils.parseEther("100"),
  //   ethers.utils.parseEther("100"),
  //   ethers.utils.parseEther("10"),
  //   ethers.utils.parseEther("10"),
  //   deployerAddress,
  //   ethers.constants.MaxUint256
  // )

  console.log("Prestige address: ", prestige.address);
  console.log("Rose address: ", rose.address);
  console.log("PSTG-ROSE LPT address: ", pair.address)
  console.log("Legions address: ", legions.address);
  console.log("Swap router address: ", uniV2Router.address);
  console.log("Uni factory address: ", uniV2Factory.address)
  console.log("Campaign manager address: ", campaignManager.address);
  console.log("Mock campaign address: ", campaignMock.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(prestige.address, "Prestige");
  saveFrontendFiles(rose.address, "Rose")
  saveFrontendFiles(pair.address, "UniswapV2Pair")
  saveFrontendFiles(legions.address, "Legions");
  saveFrontendFiles(uniV2Router.address, "UniswapV2Router02");
  saveFrontendFiles(uniV2Factory.address, "UniswapV2Factory")
  saveFrontendFiles(valor.address, "Valor")
  saveFrontendFiles(heroManager.address, "HeroManager")
  saveFrontendFiles(campaignManager.address, "CampaignManager")
  saveFrontendFiles(campaignMock.address, "CampaignMock")
}

function saveFrontendFiles(address, name) {
  const fs = require("fs");
  const contractsDir = __dirname + "/../frontend/src/lib/contracts";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  let addressesJSON = undefined
  if (fs.existsSync(contractsDir + "/addresses.json")) {
    const addresses = fs.readFileSync(contractsDir + "/addresses.json")
    addressesJSON = JSON.parse(addresses)
    addressesJSON[name] = address
  } else {
    addressesJSON = {}
    addressesJSON[name] = address
  }

  fs.writeFileSync(
    contractsDir + `/addresses.json`,
    JSON.stringify(addressesJSON, undefined, 2),
  );

  const contractArtifact = artifacts.readArtifactSync(name);

  let abisJSON = undefined
  if (fs.existsSync(contractsDir + "/abis.json")) {
    const abis = fs.readFileSync(contractsDir + "/abis.json")
    abisJSON = JSON.parse(abis)
    abisJSON[name] = contractArtifact.abi
  } else {
    abisJSON = {}
    abisJSON[name] = contractArtifact.abi
  }

  fs.writeFileSync(
    contractsDir + `/abis.json`,
    JSON.stringify(abisJSON, null, 2),
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
