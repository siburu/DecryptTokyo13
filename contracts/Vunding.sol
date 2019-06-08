pragma solidity 0.5.8;

contract Vunding {

	event ProjectRegistered(uint id);

	struct Project {
		string title;
		uint fundingDeadline;
		uint fundingTarget;
		string desc;
	}

	uint nextProjectId = 0;
	mapping (uint => Project) public projects;

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

}
