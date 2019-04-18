pragma solidity >=0.4.24 < 0.6.0;

import "./Pausable.sol";
import "./ERC725.sol";

// 实现ERC725中的添加/移除功能

contract KeyManager is Pausable, ERC725 {
    
    function addKey(
        bytes32 _key,
        uint256 _purpose,
        uint256 _keyType
    )
        public
        onlyManagementOrSelf
        whenNotPaused
        returns(bool success)
    {
        if(allKeys.find(_key, _purpose)){
            return false;
        }
        _addKey(_key, _purpose, _keyType);
        return true;
    }

    // 从身份中移除key data
    function removeKey(
        bytes32 _key,
        uint256 _purpose
    )
        public
        onlyManagementOrSelf
        whenNotPaused
        returns(bool success)
    {
        if(!allKeys.find(_key, _purpose)) {
            return false;
        }
        uint256 keyType = allKeys.remove(_key, _purpose);
        emit KeyRemoved(_key, _purpose, keyType);
        return true;
    }

    // 添加key data到身份，不用检查是否存在
    function _addKey(
        bytes32 _key,
        uint256 _purpose,
        uint256 _keyType
    )
        internal
    {
        allKeys.add(_key,_purpose,_keyType);
        emit KeyAdded(_key, _purpose, _keyType);
    }
}