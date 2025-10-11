// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ToDoList {
    address assigner;
    ToDo[] toDos;
    mapping (address => uint) addressToTaskCount;

    struct ToDo {
        uint taskId;
        address assignee;
        string task;
        uint32 deadline;
        STATUS status;
    }

    enum STATUS {
        INCOMPLETE,
        COMPLETED,
        FAILED
    }

    event TaskAdded(ToDo);
    event TaskReassigned(ToDo);
    event LogCurrentUnixTime(uint unixTime);

    constructor() {
        assigner = msg.sender;
        addressToTaskCount[msg.sender] = 1;
    }

    function assignTask(address _assignee, string calldata _task, uint32 _deadline) external onlyAssigner {
        ToDo memory newTask = ToDo(
            uint(toDos.length),
            _assignee,
            _task,
            _deadline,
            STATUS.INCOMPLETE
        );
        toDos.push(newTask);

        addressToTaskCount[_assignee]++;

        emit TaskAdded(newTask);
    }

    function reassignTask(uint32 _taskId, address _assignee) external onlyAssigner {
        // Status tasknya harus belum selesai
        require(toDos[_taskId].status == STATUS.INCOMPLETE, "This task is already completed.");
        // Address assignee tidak boleh previous assignee
        require(toDos[_taskId].assignee != _assignee, "Task can't be assigned to same address");

        // Kurangin jumlah task address ini
        addressToTaskCount[toDos[_taskId].assignee]--;
        // Ubah address assignne task ini menjadi address assignne yang baru
        toDos[_taskId].assignee = _assignee;
        // Tambah jumlah task assignee baru
        addressToTaskCount[_assignee]++;

        emit TaskReassigned(toDos[_taskId]);
    }

    function checkDeadlineValid(uint _deadline, uint _curentUnixTime) public pure returns(bool) {
        if (_deadline > _curentUnixTime) {
            return true;
        }

        return false;
    }

    function refreshTask() external onlyAssigner {
        emit LogCurrentUnixTime(block.timestamp);

        for (uint i = 0; i < toDos.length; i++) {
            if (toDos[i].status == STATUS.INCOMPLETE && !checkDeadlineValid(toDos[i].deadline, block.timestamp)) {
                toDos[i].status = STATUS.FAILED;
            }
        }
    }

    function completeTask(uint32 _taskId) external onlyMembers {
        // Cek apakah address assignee task adalah address pemanggil
        require(toDos[_taskId].assignee == msg.sender, "Address is not the assignee of the task.");
        // Cek status harus belum selesai
        require(toDos[_taskId].status == STATUS.INCOMPLETE, "Task is already completed.");

        // Kalau sudah lewat deadline ubah status ke failed
        bool isDeadlineValid = checkDeadlineValid(toDos[_taskId].deadline, block.timestamp);
        if(!isDeadlineValid) {
            toDos[_taskId].status = STATUS.FAILED;
        }

        // Kalau sudah valid ubah status ke complete
        require(isDeadlineValid, "Task has passed the deadline.");
        toDos[_taskId].status = STATUS.COMPLETED;
    }

    function viewAllTask() public view onlyMembers returns (ToDo[] memory) {
        return toDos;
    }

    modifier onlyAssigner() {
        require(msg.sender == assigner, "This function is can be only execute by Assigner, address is not assigner.");
        _;
    }

    modifier onlyMembers() {
        require(addressToTaskCount[msg.sender] > 0, "This function s can be only execute by Member, address is not Member.");
        _;
    }
}