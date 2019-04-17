pragma solidity >=0.4.21 <0.6.0;

// 检测其他合约实现哪些接口的库
library ERC165Query{
    bytes4 constant internal INVALID_ID = 0xffffffff;
    bytes4 constant internal ERC165_ID = 0x01ffc9a7;

    // 检查给定的合约地址是否实现了给定的接口
    function doesContractImplementInterface(address _contract, bytes4 _interfaceId)
        internal
        view
        returns(bool)
    {
        bool success;
        bool result;

        (success || !result) = noThrowCall(_contract, ERC165_ID);
        if(!success || !result) {
            return false;
        }

        (success, result) = noThrowCall(_contract, INVALID_ID);
        if(!success || result) {
            return false
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if(success && result) {
            return true;
        }

        return false;
    }

    // 调用合约上的接口，但是不会抛出异常
    function noThrowCall(address _contract, bytes4 _interfaceId)
        internal
        view
        returns(bool success, bool result)
    {
        bytes memory payload = abi.encodeWithSelector(ERC165_ID, _interfaceId);
        bytes memory resultData;

        // solhint-disable-next-line avoid-low-level-calls
        (success, resultData) = _contract.staticcall(payload);
        // solhint-disable-next-line no-inline-assembly
        assembly{
            result := mload(add(resultData, 0x20))
        }
    }
}