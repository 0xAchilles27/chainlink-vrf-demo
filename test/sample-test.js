const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers, deployments } = require("hardhat");

describe("OurNFTContract", function () {
  let owner;
  let hardhatOurNFTContract, hardhatVrfCoordinatorV2Mock;

  beforeEach(async () => {
    [owner] = await ethers.getSigners();
    let ourNFTContract = await ethers.getContractFactory("OurNFTContract");
    let vrfCoordinatorV2Mock = await ethers.getContractFactory("VRFCoordinatorV2Mock");
    // let vrfMock = await ethers.getContractFactory("VRFMock");

    hardhatVrfCoordinatorV2Mock = await vrfCoordinatorV2Mock.deploy(0, 0);
    // hardhatVrfCoordinatorV2Mock = await vrfMock.deploy();

    await hardhatVrfCoordinatorV2Mock.createSubscription();

    await hardhatVrfCoordinatorV2Mock.fundSubscription(1, ethers.utils.parseEther("7"))

    hardhatOurNFTContract = await ourNFTContract.deploy(1, hardhatVrfCoordinatorV2Mock.address);
  })

  it("Contract should request Random numbers successfully", async () => {
    await expect(hardhatOurNFTContract.safeMint("Halley")).to.emit(
      hardhatOurNFTContract,
      "RequestedRandomness"
    ).withArgs( BigNumber.from(1), owner.address, "Halley");
  });
  
  it("Coordinator should successfully receive the request", async function () {
    await expect(hardhatOurNFTContract.safeMint("Halley")).to.emit(
      hardhatVrfCoordinatorV2Mock,
      "RandomWordsRequested"
    );
  })

  it("Coordinator should fulfill Random Number request", async () => {
    let tx = await hardhatOurNFTContract.safeMint("Halley");
    let { events } = await tx.wait();

    let [reqId, invoker] = events.filter( x => x.event === 'RequestedRandomness')[0].args;

    await expect(
      hardhatVrfCoordinatorV2Mock.fulfillRandomWords(reqId, hardhatOurNFTContract.address)
    ).to.emit(hardhatVrfCoordinatorV2Mock, "RandomWordsFulfilled")

  });

  it("Contract should receive Random Numbers", async () => {

    let tx = await hardhatOurNFTContract.safeMint("Halley");
    let { events } = await tx.wait();

    let [reqId] = events.filter( x => x.event === 'RequestedRandomness')[0].args;

    await expect(
      hardhatVrfCoordinatorV2Mock.fulfillRandomWords(reqId, hardhatOurNFTContract.address)
    ).to.emit(hardhatOurNFTContract, "ReceivedRandomness")


    expect(await hardhatOurNFTContract.getCharacter(0))
    .to.include(owner.address.toString(), "Halley");

  });
});
