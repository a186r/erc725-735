pragma solidity >=0.4.24 < 0.6.0;

import "./Pausable.sol";
import "./ERC725.sol";
// 根据ERC725规范实现执行和多签方法

contract MultiSig is Pausable, ERC725 {
    
    // 防止重放攻击
    uint256 private nonce = 1;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        uint256 needsApprove;
    }

    mapping(uint256 => Execution) public execution;
    mapping(uint256 => address[]) public approved;

    // 为执行请求生成唯一的标示
    function execute(
        address _to,
        uint256 _value,
        bytes memory _data
    )
        public
        whenNotPaused
        returns(uint256 executionId)
    {
        // TODO:在每次执行的时候使用threshold
        uint threshold;
        if(_to == address(this)) {
            if (msg.sender == address(this)){
                // 合约自己执行
                threshold = managementRequired;
            }else{
                // 只有管理密钥可以操作这个合约
                require(allKeys.find(addrToKey(msg.sender), MANAGEMENT_KEY), "need management key for execute");
                threshold = managementRequired - 1;
            }
        }else{
            require(_to != address(0), "null execute to");
            if (msg.sender == address(this)){
                // 合约调用自己去操作其他合约
                threshold = executionRequired;
            }else{
                // Execution keys 可以在其他地址上操作
                require(allKeys.find(addrToKey(msg.sender), EXECUTION_KEY), "need execution key for execute");
                threshold = executionRequired - 1;
            }
        }

        // 生成执行id并且增加nonce
        executionId = getExecutionId(address(this), _to, _data, threshold);
        emit ExecutionRequested(executionId, _to, _value, _data);
        nonce++;

        Execution memory e = Execution(_to, _value, _data, threshold);
        if(threshold == 0){
            // 一个批准就够了，直接执行
            _execute(executionId, e, false);
        }else {
            execution[executionId] = e;
            approved[executionId].push(msg.sender);
        }

        return executionId;
    }

    // 批准一个execution, 如果execution被批准多次，可能会出现错误。多次不赞成是可行的，即什么都不做
    // 批准可能会触发执行(如果达到阈值)
    fucntion approve(
        uint256 _id,
        bool _approve
    )
        public
        whenNotPaused
        returns(bool success)
    {
        require(_id != 0, "null execution ID");
        Execution storage e = execution[_id];
        // 必须存在
        require(e.to != address(0), "null approve to");

        // 必须用正确的密钥批准
        if(e.to == address(this)) {
            require(allKeys.find(addrToKey(msg.sender), MANAGEMENT_KEY), "need management key for approve");
        }else{
            require(allKeys.find(addrToKey(msg.sender),EXECUTION_KEY), "need execution key for approve");
        }

        emit Approved(_id, _approve);

        address[] storage approvals = approved[_id]; 
        if(!approve) {
            // 在批准中查找
            for (uint i = 0; i < approvals.length; i++){
                if(approvals[i] == msg.sender) {
                    // 撤销批准
                    approvals[i] = approvals[approvals.length - 1];
                    delete approvals[approvals.length - 1];
                    approvals.length-- ;
                    e.needsApprove += 1;
                    return true;
                }
            }
            return false;
        }else {
            // 只批准一次
            for (uint i = 0; i< approvals.length; i++){
                require(approvals[i] != msg.sender, "already approved");
            }

            // 批准
            approvals.push(msg.sender);
            e.needsApprove -= 1;

            // 需要更多的批准吗
            if (e.needsApprove == 0){
                return _execute(_id, e, true);
            }
            return true;
        }
    }

    // 更改多签阈值
    function changeKeysRequired(uint256 purpose, uint256 number)
        external
        whenNotPaused
        onlyManagementOrSelf
    {
        require(purpose == MANAGEMENT_KEY || purpose == EXECUTION_KEY, "unknown purpose");
        require(number >0 , "keys required too low");
        uint numKyes = getKeysNyPurpose(purpose).length;
        require(number <= numKeys, "keys require too high");
        if(purpose == MANAGEMENT_KEY) {
            managementRequired = number;
        }else {
            executionRequired = number;
        }
        emit KeysRequiredChanged(purpose, number);
    }

    // 返回多重签名阈值
    function getKeysRequired(uint256 purpose)
        external
        view
        returns(uint256)
    {
        require(purpose == MANAGEMENT_KEY || purpose == EXECUTION_KEY, "unknow purpose");
        if(purpose == MANAGEMENT_KEY) {
            return managementRequired;
        }
        return executionRequired;
    }

    // 为执行请求生成唯一标识
    function getExecutionId{
        address self,
        address _to,
        uint256 _value,
        bytes memory _data,
        uint _nonce
    }
        private
        pure
        returns(uint256)
    {
        return uint(keccak256(abi.encodePacked(self, _to, _value, _data, _nonce)));
    }

    // 对其他合约、合约本身、或者转账等执行操作
    function _execute(
        uint256 _id,
        Execution memory e,
        bool clean
    )
        private
        returns(bool)
    {
        // 必须存在
        require(e.to != address(0), "null execute to");
        // 调用
        // solhint-disable-next-line avoid-call-value
        (bool success, ) = e.to.call.value(e.value)(e.data);
        if (!success) {
            emit ExecutionFailed(_id, e.to, e.value, e.data);
            return false;
        }
        emit Executed(_id, e.to, e.value, e.data);
        // Clean up
        if(!clean) {
            return true;
        }
        delete execution[_id];
        delete approved[_id];
        return true;
    }

}