pragma solidity >= 0.5.7 < 0.6.0;

import "./KeyStore.sol";

contract KeyBase {

    uint256 public constant MANAGEMENT_KEY = 1;

    // 用于多签
    uint256 public managementRequired = 1;
    uint256 public executionRequired = 1;

    // 密钥存储
    using keyStore for KeyStore.Keys;
    KeyStore.Keys internal allKeys;

    // 合约管理的密钥数
    function numKeys()
        external
        view
        returns(uint)
    {
        return allKeys.numKeys;
    }

    // 将以太坊地址转换成一个ERC725的key
    // 这是一个简单的类型转换，但是在测试中很有用
    function addrToKey(address addr)
        public
        pure
        returns (bytes32)
    {
        return bytes32(uint256(addr));
    }

    // 检查sender是身份合约还是管理密钥
    // 如果管理密钥的多重签名阈值大于1， 将会抛出一个错误
    // 如果sender是身份合约或者管理密钥，则返回true
    function _managementOrSelf()
        internal
        view
        returns(bool found)
    {
        if(msg.sender == address(this)) {
            return true;
        }

        require(managementRequired == 1, "management threshold >1");
        return allKeys.find(addrToKey(msg.sender), MANAGEMENT_KEY);
    }

    // 只允许purpose为1的key或者身份本身
    modifier onlyManagementOrSelf {
        require(_managementOrSelf(), "only management or self");
        _;
    }
}