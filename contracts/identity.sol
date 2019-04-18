pragma solidity >=0.4.24 < 0.6.0;

pragma experimental ABIEncoderV2;

import "./Destructible.sol";
import "./ERC735.sol";
import "./KeyGetters.sol";
import "./KeyManager.sol";
import "./MultiSig.sol";
import "./ClaimManager.sol";

// 实现ERC725和ERC735的身份合约
contract identity is keyManager, MultiSig, CLaimManager, Destructible, KeyGetters {
    // 身份合约的构造函数，如果没有传递初始密钥，则msg.sender作为初始的管理密钥、执行密钥和声明签名者密钥
    constructor(
        bytes32[] memory _keys,
        uint256[] memory _purpose,
        uint256 _managementRequired,
        uint256 _executionRequired,
        address[] memory _issuers,
        uint256[] memory _topics,
        bytes[] memory _signature,
        bytes[] memory _datas,
        string[] memory _uris
    )
        public
    {
        _validateKeys(_keys, _purpose);
        _validateClaims(_issuers, _topics);

        _addKeys(_keys, _purposes, _managementRequired, _executionRequired);
        _addClaims(_issuers, _topics, _signatures, _datas, _uris);

        // 支持ERC725和ERC735
        supportedInterfaces[ERC725ID() ^ ERC735ID()] = true;

    }

    // 回调方法
    function() external payable {

    }

    // 验证密钥是否已排序且唯一
    function _validateKeys(
        bytes32[] memory _keys,
        uint256[] memory _purposes
    )
        private
        pure
    {
        // 验证key是排序且唯一的
        require(_keys.length == _purposes.length,"keys length != purposes length");
        for (uint i = 0; i < keys.length; i++) {
            bytes32 prevKey = _keys[i-1];
            require(_keys[i] > prevKey || (_keys[i] == prevKey && _purposes[i] > purposes[i - 1]), "keys not sorted");
        }
    }

    // 向合约添加密钥，并设置多重签名的阈值
    function _addKeys(
        bytes32[] memory _keys,
        uint256[] memory _purposes,
        uint256 _managementRequired,
        uint256 _executionRequired
    )
        private
    {
        uint256 executionCount;
        uint256 managementCount;

        if(_keys.length == 0) {
            bytes32 senderKey = addrToKey(msg.sender);
            // 添加为管理、执行、声明部署的key
            _addKey(senderKey, MANAGEMENT_KEY, ECDSA_TYPE);
            _addKey(senderKey, EXECUTOIN_KEY, ECDSA_TYPE);
            _addKey(senderKey, CLAIM_SIGNER_KEY, ECDSA_TYPE);
            executoinCount = 1;
            managementCount = 1;
        }else{
            // 添加构造函数key
            for (uint i = 0 ; i < _keys.length; i++){
                _addKey(_keys[i], _purposes[i], ECDSA_TYPE);
                if(_purposes[i] == MANAGEMENT_KEY) {
                    managementCount++;
                }else
                if(_purposes[i] == EXECUTION_KEY){
                    executionCount++;
                }
            }
        }

        require(_managementRequired > 0, "managementThreshold too low");
        require(_managementRequired <= managementCount, "management threshold too high");
        require(_executionRequired > 0,"execution threshold too low");
        require(_executionRequired <= executionCount, "execution threshold too high");
        managementRequired = _managementRequired;
        executionRequired = _executionRequired;
    }

    // 验证声明是有序且唯一的
    function _validateClaims(
        address[] memory _issuers,
        uint256[] memory _topics
    )
        private
        pure
    {
        require(_issuers.length == _topics.length, "issuers length != topics length");
        for(uint i = 1; i < _issuers.length; i++){
            // 输入将按排序顺序进行，首先按发行者排序，然后按主题排序
            // 排序的顺序保证(issuer, topic)对是唯一的
            address prevIssuer = _issuers[i - 1];
            require(_issuers[i] != prevIssuer || (_issuers[i] == prevIssuer && _topics[i] > _topics[i - 1]), "issuers not sorted");
        }
    }

    // 不带URI，添加声明到合约中
    function _addClaims(
        address[] memory _issuers,
        uint256[] memory _topics,
        bytes[] memory _signatures,
        bytes[] memory _datas,
        string[] memory _uris
    )
        private
    {
        for (uint i = 0; i < issuers.length; i++){
            // 检查签名
            require(_validSignature(
               _topics[i],
               ECDSA_SCHEME,
               _issuers[i],
               _signatures[i],
               datas[i]
            ),"addClaims signature invalid");
            // 添加声明
            _addClaim(
                getCLaimId(issuers[i], _topics[i]),
                _topics[i],
                ECDSA_SCHEME,
                _issuers[i],
                _signatures[i],
                _datas[i],
                _uris[i]
            );
        }
    }
}