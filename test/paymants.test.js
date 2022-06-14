const { expect } = require("chai");
const { ethers } = require("hardhat");


describe('TestTask', function () {
  let owner
  let proposal
  let ballots
  const duration = 3*24*3600 //3 day

  beforeEach(async function() {
    [owner, proposal] = await ethers.getSigners()
    const TestTask = await ethers.getContractFactory('TestTask', owner)
    ballots = await TestTask.deploy()
    ballots.deployed()
  })

  async function getTimestamp(bn) {
    return (
      await ethers.provider.getBlock(bn)
    ).timestamp
  }

  it('should be deployed', async function() {
    expect(ballots.address).to.be.properAddress
  })

  it("sets owner", async function() {
    const currentOwner = await ballots.owner()
    expect(currentOwner).to.eq(owner.address)
  })

  it('create a vote with the owner', async function() {
    const tx = ballots.createBallot([proposal.address])
    const cBallot = await ballots.ballots(0)
    const cProposal = await ballots.getProposals(0)
    const ts = await getTimestamp(tx.blockNumber)
    expect(cBallot.endsAt).to.eq(ts + duration)
    expect(cBallot.startAt).to.eq(ts)
    expect(cBallot.balance).to.eq(0)
    expect(cProposal[0].name).to.eq(proposal.address)
  })

  it('can\'t create another vote', async function() {
    await expect(ballots.connect(proposal).createBallot([proposal.address]))
  .to.be.revertedWith('Only owner can create ballot!')
  })

  it('can vote', async function() {
    ballots.createBallot([proposal.address])
    await expect(ballots.connect(proposal).vote(0,0, {value: ethers.utils.parseEther("0.01")}))
  .to.be.revertedWith('voting requires 0.1 ETH')
    await expect(ballots.connect(proposal).vote(0,0, {value: ethers.utils.parseEther("0.1")}))
  .to.be.revertedWith('Already voted.')
  })
})
