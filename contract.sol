// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }
    struct Proposal {
        string description;
        uint256 voteCount;
    }
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    mapping(address => Voter) public voters;
    WorkflowStatus public workflowStatus;
    Proposal[] public proposals;
    address[] whitelist = [
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
        0x617F2E2fD72FD9D5503197092aC168c91465E7f2
    ];
    uint256 public winningProposalId;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);
    event theWinnerIs(uint256 winner);

    modifier onlyVoters(address _voterAddr) {
        require(
            voters[_voterAddr].isRegistered == true,
            "You are not allowed to vote"
        );
        _;
    }

    constructor() {
        workflowStatus = WorkflowStatus.RegisteringVoters;
        RegisteringVoters(whitelist);
        // Blank vote
        proposals.push(Proposal("Blank vote", 0));
    }

    function RegisteringVoters(address[] memory _whitelist) private {
        uint256 i;
        for (i = 0; i < _whitelist.length; i++) {
            voters[_whitelist[i]] = Voter(true, false, 0);
        }
    }

    function startProposalsRegistration() public onlyOwner {
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            WorkflowStatus.ProposalsRegistrationStarted
        );
    }

    function endProposalsRegistration() public onlyOwner {
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            WorkflowStatus.ProposalsRegistrationEnded
        );
    }

    function startVotingSession() public onlyOwner {
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VotingSessionStarted
        );
    }

    function endVotingSession() public onlyOwner {
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
    }

    function sendProposal(string calldata _description)
        public
        onlyVoters(address(msg.sender))
    {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "This isn't time for proposal."
        );
        proposals.push(Proposal(_description, 0));
        uint256 proposalId = proposals.length - 1;
        emit ProposalRegistered(proposalId);
    }

    function voteForProposal(uint256 proposalId)
        public
        onlyVoters(address(msg.sender))
    {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "This isn't voting time."
        );
        require(
            voters[msg.sender].hasVoted == false,
            "You already vote for a proposition."
        );
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;
        proposals[proposalId].voteCount++;
    }

    function tailledVote() public onlyOwner {
        uint256 i;
        // Usefull to reduce gas cost
        uint256 tmpWinningProposalId = 1;
        require(
            workflowStatus == WorkflowStatus.VotingSessionEnded,
            "Voting period hasn't stopped yet !"
        );
        // We don't consider that blank vote can win so i start at 1
        for (i = 1; i < proposals.length; i++) {
            if (
                proposals[i].voteCount >
                proposals[tmpWinningProposalId].voteCount
            ) {
                tmpWinningProposalId = i;
            }
        }
        workflowStatus = WorkflowStatus.VotesTallied;
        winningProposalId = tmpWinningProposalId;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
        emit theWinnerIs(winningProposalId);
    }

    // Voters can retract their vote during the voting period
    function retractVote() public onlyVoters(address(msg.sender)) {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "This isn't voting time."
        );
        require(
            voters[msg.sender].hasVoted == true,
            "You didn't vote for a proposition yet."
        );
        proposals[voters[msg.sender].votedProposalId].voteCount--;
        voters[msg.sender].hasVoted = false;
        voters[msg.sender].votedProposalId = 0;
    }

    // Admin can reset the entire vote
    function resetElection() public onlyOwner {
        uint256 i;
        RegisteringVoters(whitelist);
        for (i = proposals.length - 1; i > 0; i--) {
            proposals.pop();
        }
        emit WorkflowStatusChange(
            workflowStatus,
            WorkflowStatus.RegisteringVoters
        );
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    function displayWinner() public view returns (Proposal memory) {
        require(
            workflowStatus == WorkflowStatus.VotesTallied,
            "Votes hasn't been tailled yet !"
        );
        return proposals[winningProposalId];
    }
}
