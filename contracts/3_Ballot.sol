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

    function reassignTask(uint _taskId, address _assignee) external onlyAssigner {
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
    }

    modifier onlyAssigner() {
        require(msg.sender == assigner, "This function can be only execute by Assigner, address is not assigner.");
        _;
    }
}