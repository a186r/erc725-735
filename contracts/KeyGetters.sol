pragma solidity >=0.4.21 <0.6.0;

import "./KeyBase.sol";
// 根据ERC725规范实现getter功能
// key data使用KeyStore库

contract KeyGetters is KeyBase {

    // 查找key data，如果身份持有
    // _key 表示要查找的key
    // 如果key存在则返回key里面的全部数据
    function getKey(
        bytes32 _key
    )
        public
        view
        returns(uint256[] memory purposes, uint256 keyType, bytes32 key)
    {
        KeyStore.Key memory k = allKeys.keyData[_key];
        purposes = k.purposes;
        keyType = k.keyType;
        key = k.key;
    }

    // 查找密钥是否存在，并具有给定的目的
    function keyHasPurpose(
        bytes32 _key,
        uint256 purpose
    )
        public
        view
        returns(bool exists)
    {
        return allKeys.find(_key,purpose);
    }

    // 为指定purpose查询该身份持有的所有密钥
    function getKeysByPurpose(uint256 _purpose)
        public
        view
        returns(bytes32[] memory keys)
    {
        return allKeys.keysByPurpose[_purpose];
    }

}