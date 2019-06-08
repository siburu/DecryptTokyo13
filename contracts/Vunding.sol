pragma solidity 0.5.8;

contract Vunding {

	event ProjectRegistered(uint projId, string title, uint fundingDeadline, uint fundingTarget);
	event ProjectAborted(uint projId, string title, uint fundingDeadline, uint fundingTarget);

	event Funded(uint projId, uint fundId, address owner, uint amount);
	event Refunded(uint projId, uint fundId, address owner, uint amount);

	event CandidateRegistered(uint projId, uint candId, string name);
	event CandidateVoted(uint projId, uint candId);

	struct Project {
		address owner;

		string title;
		uint fundingDeadline;
		uint fundingTarget;
		string desc;

		uint totalFund;
		uint[] fundIds;

		uint[] candIds;
	}

	struct Fund {
		address owner;
		uint amount;
	}

	struct Candidate {
		address owner;
		string name;
		string profile;
		string appeal;
		address[] voters;
	}

	uint constant candidacyPeriod = 1 days;
	uint constant votingPeriod = 1 days;

	uint nextProjectId = 0;
	mapping (uint => Project) public projects;

	uint nextFundId = 0;
	mapping (uint => Fund) public funds;

	uint nextCandidateId = 0;
	mapping (uint => Candidate) public candidates;

	modifier fundableProject(uint _projId) {
		require(projects[_projId].fundingDeadline > now);
		_;
	}

	modifier abortableProject(uint _projId) {
		Project storage proj = projects[_projId];
		require(now > proj.fundingDeadline);
		require(proj.totalFund < proj.fundingTarget);
		_;
	}

	modifier applyableProject(uint _projId) {
		Project storage proj = projects[_projId];
		require(now > proj.fundingDeadline);
		require(now <= proj.fundingDeadline + candidacyPeriod);
		require(proj.totalFund >= proj.fundingTarget);
		_;
	}

	modifier votableProject(uint _projId) {
		Project storage proj = projects[_projId];
		require(now > proj.fundingDeadline + candidacyPeriod);
		require(now <= proj.fundingDeadline + candidacyPeriod + votingPeriod);
		require(proj.totalFund >= proj.fundingTarget);
		_;
	}

	function registerProject(string calldata _title, uint _fundingDeadline, uint _fundingTarget, string calldata _desc) external {
		uint id = nextProjectId;
		nextProjectId++;

		Project storage proj = projects[id];
		proj.owner = msg.sender;
		proj.title = _title;
		proj.fundingDeadline = _fundingDeadline;
		proj.fundingTarget = _fundingTarget;
		proj.desc = _desc;

		emit ProjectRegistered(id, _title, _fundingDeadline, _fundingTarget);
	}

	function fundProject(uint _projId) external payable fundableProject(_projId) {
		uint fundId = nextFundId;
		nextFundId++;

		Fund storage fund = funds[fundId];
		fund.owner = msg.sender;
		fund.amount = msg.value;

		Project storage proj = projects[_projId];
		proj.fundIds.push(fundId);
		proj.totalFund += msg.value;

		emit Funded(_projId, fundId, msg.sender, msg.value);
	}

	function abortProject(uint _projId) external abortableProject(_projId) {
		Project storage proj = projects[_projId];

		for (uint i = 0; i < proj.fundIds.length; i++) {
			uint fundId = proj.fundIds[i];
			Fund storage fund = funds[fundId];
			address payable fundOwner = address(uint160(fund.owner));
			fundOwner.transfer(fund.amount);
			emit Refunded(_projId, fundId, fund.owner, fund.amount);
			delete funds[fundId];
		}

		emit ProjectRegistered(_projId, proj.title, proj.fundingDeadline, proj.fundingTarget);
		delete projects[_projId];
	}

	function applyProject(uint _projId, string calldata _name, string calldata _profile, string calldata _appeal) external applyableProject(_projId) {
		uint candId = nextCandidateId;
		nextCandidateId++;

		Candidate storage cand = candidates[candId];
		cand.owner = msg.sender;
		cand.name = _name;
		cand.profile = _profile;
		cand.appeal = _appeal;

		Project storage proj = projects[_projId];
		proj.candIds.push(candId);

		emit CandidateRegistered(_projId, candId, _name);
	}

	function voteProject(uint _projId, uint _candId) external votableProject(_projId) {
		Project storage proj = projects[_projId];
		bool found = false;
		for (uint i = 0; i < proj.candIds.length; i++) {
			uint candId = proj.candIds[i];
			if (candId == _candId) {
				found = true;
				break;
			}
		}
		require(found);

		Candidate storage cand = candidates[_candId];
		for (uint i = 0; i < cand.voters.length; i++) {
			address voter = cand.voters[i];
			require(voter != msg.sender);
		}

		cand.voters.push(msg.sender);

		emit CandidateVoted(_projId, _candId);
	}

}
