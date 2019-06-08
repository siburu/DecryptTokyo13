pragma solidity 0.5.8;

contract Vunding {

	event ProjectRegistered(uint id);
	event Funded(uint projId, uint fundId, address owner, uint amount);

	struct Project {
		string title;
		uint fundingDeadline;
		uint fundingTarget;
		string desc;

		uint totalFund;
		uint[] fundIds;
	}

	struct Fund {
		address owner;
		uint amount;
	}

	uint nextProjectId = 0;
	mapping (uint => Project) public projects;

	uint nextFundId = 0;
	mapping (uint => Fund) public funds;

	modifier fundable(uint _projId) {
		require(projects[_projId].fundingDeadline > now);
		_;
	}

	function registerProject(string calldata _title, uint _fundingDeadline, uint _fundingTarget, string calldata _desc) external {
		uint id = nextProjectId;
		nextProjectId++;

		Project storage proj = projects[id];
		proj.title = _title;
		proj.fundingDeadline = _fundingDeadline;
		proj.fundingTarget = _fundingTarget;
		proj.desc = _desc;

		emit ProjectRegistered(id);
	}

	function fundProject(uint _projId) external payable fundable(_projId) {
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

}
