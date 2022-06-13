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
    mapping (address => Voter) voters;
    WorkflowStatus public workflowStatus;
    Proposal[] proposals;
    uint winningProposalId;


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    event theWinnerIs(uint winner);
    event showWinner(Proposal proposal);

    modifier onlyVoters(address _voterAddr){
        require(voters[_voterAddr].isRegistered == true, "You are not allowed to vote");
        _;
    }

    constructor() {
        voters[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = Voter(true, false, 0);
        voters[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = Voter(true, false, 0);
        workflowStatus = WorkflowStatus.RegisteringVoters;
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

    function sendProposal(string memory _description) public onlyVoters(address (msg.sender)){
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

    function debugTest() public {
        uint i;
        for (i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > proposals[winningProposalId].voteCount) {
                winningProposalId = i;
            }
        }
        emit theWinnerIs(winningProposalId);
    }

    function showWinnerDetails() public {
        emit showWinner(proposals[winningProposalId]);
    }
}