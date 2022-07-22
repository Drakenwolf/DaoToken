// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DaoToken is
    Governor,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    AccessControl
{
    ///@notice that this mapping will track the role asigned to a proposal.
    mapping(uint256 => bytes32) public rolesPeerProposal;

    ///@notice that this mapping will track if a proposal has a role assigned
    mapping(uint256 => bool) public proposalHasRoleAssigned;

    ///@notice that this mapping will track if a proposal is open to all members
    mapping(uint256 => bool) public proposalIsForAllMembers;

    event assingRoleToProposalEvent(
        bool isOpenForAll,
        bytes32 role,
        uint256 _proposalId
    );

    constructor(IVotes _token)
        Governor("DaoToken")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
    {
        ///@notice that we grant anm admin role for the msg.sender
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        return 45818; // 1 week
    }

    function assingRoleToProposal(
        bool isOpenForAll,
        bytes32 role,
        uint256 _proposalId
    ) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Error: only the admin can assign a role"
        );
        if (isOpenForAll) {
            proposalIsForAllMembers[_proposalId] = true;
        } else {
            proposalHasRoleAssigned[_proposalId] = true;
            rolesPeerProposal[_proposalId] = role;
        }

        emit assingRoleToProposalEvent(isOpenForAll, role, _proposalId);
    }

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason,
        bytes memory params
    ) internal override returns (uint256) {
        require(
            proposalHasRoleAssigned[proposalId] ||
                proposalIsForAllMembers[proposalId],
            "Error: this proposal doesnt has a roled assigned nor is open to all members"
        );

        require(
            hasRole(rolesPeerProposal[proposalId], msg.sender),
            "Error: This proposal doesnt match your current role"
        );
        return super._castVote(proposalId, account, support, reason, params);
    }

    // The following functions are overrides required by Solidity.

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(Governor, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
