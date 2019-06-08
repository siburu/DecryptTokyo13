pragma solidity 0.5.8;

contract Vunding {

	event ProjectRegistered(uint id, string title, uint fundingDeadline, uint fundingTarget);
	event ProjectAborted(uint id, string title, uint fundingDeadline, uint fundingTarget);

	event Funded(uint projId, uint fundId, address owner, uint amount);
	event Refunded(uint projId, uint fundId, address owner, uint amount);

	struct Project {
		address owner;

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

	modifier abortable(uint _projId) {
		Project storage proj = projects[_projId];
		require(now > proj.fundingDeadline);
		require(proj.totalFund < proj.fundingTarget);
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

	function abortProject(uint _projId) external abortable(_projId) {
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

}
