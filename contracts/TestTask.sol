// SPDX-License-Identifier: GPL-3.0
//["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]
pragma solidity >=0.7.0 <0.9.0;

contract TestTask{

    struct Voter {
        mapping(uint=>uint) vote;
        mapping(uint=>bool) voted;
    }

    struct Proposal {
        address name;
        uint voteCount;
    }

    struct Ballots {
        Proposal[] proposals;
        uint startAt;
        uint endsAt;
        uint balance;
    }
    
    Ballots[] public ballots;
    mapping (address => Voter) voters;
    address public owner;  
    uint constant DURATION = 3 days;
    uint constant FEE = 10;
    
    constructor(){
        owner = msg.sender;
    }

    function vote(uint _ballot, uint _proposal) public payable{
        require(msg.value >= 0.1 ether, "voting requires 0.1 ETH");
        require(block.timestamp < ballots[_ballot].endsAt, "ended!");
        ballots[_ballot].balance += 0.1 ether;
        uint refund = msg.value - 0.1 ether;
        if(refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        require(voters[msg.sender].voted[_ballot], "Already voted.");
        voters[msg.sender].voted[_ballot] = true;
        voters[msg.sender].vote[_ballot] = _proposal;
        ballots[_ballot].proposals[_proposal].voteCount++;
    }

    Ballots newBallots;
    function createBallot(address[] memory _proposalNames) public {
        //Ballots memory newBallots; // swears at memory[] memory
        newBallots.startAt = block.timestamp;
        newBallots.endsAt = block.timestamp + DURATION;
        newBallots.balance = 0 ether;
        for (uint i = 0; i < _proposalNames.length; i++){
            newBallots.proposals.push(Proposal(
                {
                    name: _proposalNames[i],
                    voteCount: 0
                }
            ));
        }
        ballots.push(newBallots); 
        require(msg.sender == owner,"Only owner can create ballot!");
    }

    function getProposals (uint _ballot) public view returns (Proposal[] memory ) {
        return ballots[_ballot].proposals;
    }

    function winningProposal(uint _ballot) public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < ballots[_ballot].proposals.length; p++) {
            if (ballots[_ballot].proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = ballots[_ballot].proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function endVoting(uint _ballot) public payable {
        address winnerName_ = ballots[_ballot].proposals[winningProposal(_ballot)].name;
        if (block.timestamp > ballots[_ballot].endsAt) {
            payable(owner).transfer(
                (ballots[_ballot].balance * FEE) / 100
            );
            payable(winnerName_).transfer(
                ballots[_ballot].balance - ((ballots[_ballot].balance * FEE) / 100)
            );
        }
    }
}