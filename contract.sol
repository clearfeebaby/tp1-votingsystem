// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

/**
 * @title SampleERC20
 * @dev Create a sample ERC20 standard token
 */

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    struct Proposal {
        string description;
        uint voteCount;
    }
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    // Voter[] voters;
    mapping (address => Voter) public voters;
    WorkflowStatus public workflowStatus;
    Proposal[] public proposals;
    address[] whitelist = [0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2];
    uint public winningProposalId;


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    event theWinnerIs(uint winner);

    modifier onlyVoters(address _voterAddr){
        require(voters[_voterAddr].isRegistered == true, "You are not allowed to vote");
        _;
    }

    constructor() {
        workflowStatus = WorkflowStatus.RegisteringVoters;
        RegisteringVoters(whitelist);
    }

    function RegisteringVoters(address[] memory _whitelist) private {
      uint i;
      for (i=0; i < _whitelist.length; i++) {
        voters[_whitelist[i]] = Voter(true, false, 0);
      }
    }

    function startProposalsRegistration() public onlyOwner {
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function endProposalsRegistration() public onlyOwner {
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVotingSession() public onlyOwner {
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function endVotingSession() public onlyOwner {
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    function sendProposal(string calldata _description) public onlyVoters(address (msg.sender)){
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "This isn't time for proposal.");
        proposals.push(Proposal(_description, 0));
        uint proposalId = proposals.length - 1;
        emit ProposalRegistered(proposalId);
    }

    function voteForProposal(uint proposalId) public onlyVoters(address (msg.sender)) {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "This isn't time for voting.");
        require(voters[msg.sender].hasVoted == false, "You already vote for a proposition.");
        proposals[proposalId].voteCount++;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;
    }

    function tailledVote() public onlyOwner {
        uint i;
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Voting period hasn't stopped yet !");
        for (i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > proposals[winningProposalId].voteCount) {
                winningProposalId = i;
            }
        }
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        emit theWinnerIs(winningProposalId);
    }

    function displayWinner() public view returns (Proposal memory) {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Voting period hasn't stopped yet !");
        return proposals[winningProposalId];
    }
}