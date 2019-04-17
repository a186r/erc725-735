pragma solidity >=0.4.21 <0.6.0;

import "../node_modules/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./Pausable.sol";
import "./ERC725.sol";
import "./ERC735.sol";
import "./ERC165Query.sol";

// 执行ERC735规范中的功能
contract ClaimManager is Pausable, ERC725, ERC735{
    using ECDSA for bytes32;
    using ERC165Query for address;

    // 以太坊签名前缀
    bytes constant internal ETH_PREFIX = "\x19Ethereum Signed Message:\n32";

    struct Claim{
        uint256 topic;
        uint256 scheme;
        address issuer; //msg.sender
        bytes signature;//this.address + topic + data
        bytes data;
        string uri;
    }

    mapping(bytes32 => Claim) internal claims;
    mapping(uint256 => bytes32[]) internal claimsByTopic;
    uint public numClaims;

    // 修饰符，只允许purpose1，身份本身，或者签发者
    modifier onlyManagementOrSelfOrIssuer(bytes32 _claimId){
        address issuer = claims[_claimId].issuer;
        // 必须存在
        require(issuer != address(0), "issuer must exist");

        // 可以对凭证执行操作
        if(_managementOrSelf()){
            // 有效
        }else
        if (msg.sender == issuer) {
            // 必须仅由凭证的签发者完成
        }else
        if(issuer.doesContractImplementInterface(ERC725ID())){
            require(ERC725(issuer).keyHasPurpose(addrToKey(msg.sender), EXECUTION_KEY),"issuer contract missing execution key");
        }else{
            // 无效
            revert();
        }
        _;
    }

    // 请求签发者增加或者修改凭证
    // 任何人都可以请求增加凭证，包括凭证持有人自身(自行签发)
    // 返回claimRequestId,可以将claimRequestId发送到批准功能，以批准或者拒绝此凭证
    function addClaim(
        uint256 _topic,
        uint256 _scheme,
        address issuer,
        bytes memory _signature,
        bytes memory _data,
        string memory _uri
    )
        public
        whenNotPaused
        returns(uint256 claimRequestId)
    {
        // check signature
        require(_validSignature(_topic,_scheme, issuer, _signature, _data), "addClaim invalid signature");
        // Check we can perform action
        bool noApproval = _managementOrSelf();

        if(!noApproval) {
            claimRequestId = this.execute(address(this),0,msg.data);
            emit ClaimRequested(claimRequestId, _topic, _scheme, issuer, _signature, _data, _uri);
            return claimRequestId;
        }

        bytes32 claimId = getClaimId(issuer, _topic);

        if (claims[claimId].issuer == address(0)) {
            _addClaim(claimId, _topic, _scheme, issuer, _signature, _data, _uri);
        }else{
            // 已存在凭证
            Claim storage c = claim[claimId];
            c.scheme = _scheme;
            c.signature = _signature;
            c.data = _data;
            c.uri = _uri;
            // 你不能在不影响claimId的情况下改变issuer或者topic，所以我们不需要更新这两个字段
            emit ClaimChange(claimId, _topic, _scheme, issuer, _signature, _data, _uri);
        }
    }

    // 删除凭证，只能由凭证发行人或者凭证持有人自己删除
    function removeClaim(bytes32 _claimId)
        public
        whenNotPaused
        onlyManagementOrSelfIssuer(_claimId)
        returns(bool success)
    {
        Claim memory c = claims[_claimId];
        // 必须存在
        require(c.issuer != address(0), "issuer must exist");
        // 从mapping中移除
        delete claims[_claimId];
        // 从type array中移除
        bytes32[] storage topics = claimByTopic[c.topic];
        for(uint i = 0; i < topic.length; i++){
            if(topics[i] == _claimId){
                topics[i] = topics[topics.length - 1];
                delete topics[topics.length - 1];
                topics.length--;
                break;
            }
        }
        // claims数量减少
        numClaims--;
        // 事件
        emit ClaimRemoved(_claimId, c.topic, c.scheme, c.issuer, c.signature, c.data, c.uri);
        return true;
    }

    // 根据ID查询claim
    function getClaim(bytes32 _claimId)
        public
        view
        returns(
            uint256 topic,
            uint256 scheme,
            address issuer,
            bytes memory signature,
            bytes memory data,
            string memory uri
        )
    {
        Claim memory c = claims[_claimId];
        require(c.issuer != address(0), "issuer must exist");
        topic = c.topic;
        scheme = c.scheme;
        issuer = c.issuer;
        signature = c.signature;
        data = c.data;
        uri = c.uri;
    }

    // 根据类型返回凭证
    function getClaimIdsByType(uint256 _topic)
        public
        view
        returns(bytes32[] memory claimIds)
    {
        claimIds = claimByTopic[_topic];
    }

    // 刷新一个给定的凭证，如果不再有效，则直接删除
    function refreshClaim(bytes32 _claimId)
        public
        whenNotPaused
        onlyManagementOrSelfOrIssuer(_claimId)
        returns(bool)
    {
        // 必须是存在的
        Claim memory c = claims[_claimId];
        require(c.issuer != address(0), "issuer must exist");
        // 检查凭证依旧是有效的
        if(!_validSignature(c.topic, c.scheme,s.issuer, c.signature, c.data)){
            // 移除凭证
            removeClaim(_claimId);
            return false;
        }
    }

    // 生成凭证id，在测试中非常有用
    function getClaimId(address issuer, uint256 topic)
        public
        pure
        returns(bytes32)
    {
        // TODO 同一个签发者只能签发同一类型的一个凭证
        // 这对于自我声明不方便
        return keccak256(abi.encodePacked(issuer, topic));
    }

    // 生成凭证签名
    // 返回签发者要签名的hash
    function claimTosign(address subject, uint256 topic, bytes memory data)
        public
        pure
        returns(bytes32)
    {
        return keccak256(abi.encodePacked(subject,topic,data));
    }

    // 恢复用于签署凭证的签发者地址
    function getSignatureAddress(bytes32 toSign, bytes memory signature)
        public
        pure
        returns(address)
    {
        return keccak256(abi.encodePacked(ETH_PREFIX,toSign)).recover(signature);
    }

    // 检查给定的声明是否是有效的
    function _validSignature(
        uint256 _topic,
        uint256 _scheme,
        address issuer,
        bytes memory _signature,
        bytes memory _data
    )
        internal
        view
        returns(bool)
    {
        if(_scheme == ECDSA_SCHEME) {
            address signedBy = getSignatureAddress(claimToSign(address(this),_topic,_data),_signature);
            if(issuer == signedBy) {
                return true;
            }else
            if(issuer == address(this)){
                return allKeys.find(addrToKey(signedBy), CLAIM_SIGNER_KEY);
            }else{
                if(issuer.doesContractImplementInterface(ERC725ID())){
                    // 签发人是身份合约
                    // 它应该保存签署上述消息的密钥
                    // 如果这个密钥不再存在，声明应该被视为无效
                    return ERC725(issuer).keyHasPurpose(addrToKey(signedBy), CLAIM_SIGNER_KEY);
                }
            }
            // 无效
            return false;
        }else{
            return false;
        }
    }

    // 将key data天机道身份中，而不检查身份是否存在
    function _addClaim(
        bytes32 _claimId,
        uint256 _topic,
        uint256 _scheme,
        address issuer,
        bytes memory _signature,
        bytes memory _data,
        string memory _uri
    )
        internal
    {
        // 新的凭证
        claims[_claimId] = Claim(_topic, _scheme, issuer, _data, _uri);
        claimsByTopic[_topic].push(_claimId);
        numClaims++;
        emit ClaimAdded(_claimId, _topic, _scheme, issuer, _signature, _data, _uri);
    }

    // 无需任何检查，即可更新现有的uri
    function _updateClaimUri(
        uint256 _topic,
        address issuer,
        string memory _uri
    )
        internal
    {
        claims[getClaimId(issuer,_topic)].uri = _uri;
    }
}