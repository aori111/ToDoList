// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ToDoList {
    // Address owner
    address assigner;

    enum STATUS {
        PENDING,
        COMPLETED,
        OVERDUE
    }

    struct Task {
        string title;
        string task;
        uint256 createdAt;
        uint256 deadline;
        STATUS status;
    }

    mapping (address => Task[]) private tasks;

    event TaskAdded(address indexed  assignee, uint256 indexed taskId);
    event TaskCompleted(address indexed assignee, uint256 indexed taskId);
    event TaskOverdue(address indexed assignee, uint256 indexed taskId);
    event TaskDeleted(address indexed assignee, uint256 indexed taskId);

    // Pakai calldata untuk hemat gas external function
    function addTask(string calldata _title, string calldata _task, uint256 _deadline) external {
        require(bytes(_title).length > 0, "Title must be provided");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        tasks[msg.sender].push(Task({
            title: _title,
            task: _task,
            createdAt: block.timestamp,
            deadline: _deadline,
            status: STATUS.PENDING
        }));

        uint256 taskId = tasks[msg.sender].length - 1;
        emit TaskAdded(msg.sender, taskId);
    }

    function completeTask(uint256 _taskId) external validTaskId(_taskId) {

        Task storage task = tasks[msg.sender][_taskId];

        require(task.status == STATUS.PENDING, "Task must be Pending");
        
        if (block.timestamp > task.deadline) {
            task.status = STATUS.OVERDUE;
            emit TaskOverdue(msg.sender, _taskId);
        }

        task.status = STATUS.COMPLETED;
        emit TaskCompleted(msg.sender, _taskId);
    }

        // Fungsi untuk menandai tugas sebagai overdue (jika deadline telah lewat)
    // - Validasi status masih pending
    // - Validasi block.timestamp > deadline
    // - Ubah status ke Overdue
    // - Emit TaskOverdue

    function setOverdueTask(uint256 _taskId) external validTaskId(_taskId) {
        Task storage task = tasks[msg.sender][_taskId];

        require(task.status == STATUS.PENDING, "Task must be Pending");
        require(task.deadline < block.timestamp, "Task is not overdue yet");

        task.status = STATUS.OVERDUE;
        emit TaskOverdue(msg.sender, _taskId);
    }


    function deleteTask(uint256 _taskId) external validTaskId(_taskId) {
        uint256 taskCount = tasks[msg.sender].length;

        if (_taskId != taskCount - 1) {
            tasks[msg.sender][_taskId] = tasks[msg.sender][taskCount - 1];
        }

        tasks[msg.sender].pop();

        emit TaskDeleted(msg.sender, _taskId);
    }

    function getTasks() public view returns (Task[] memory) {
        return tasks[msg.sender];
    }

    // Fungsi untuk mendapatkan jumlah tugas user (optional untuk front-end)
    
    function getTaskCount() public view returns (uint) {
        return tasks[msg.sender].length;
    }

    modifier validTaskId(uint256 _taskId) {
        require(_taskId < tasks[msg.sender].length, "Invalide task ID");
        _;
    }
}