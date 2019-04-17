pragma solidity >=0.4.21 <0.6.0;

import "./ERC165.sol";

contract ERC725 is ERC165{
    
    // 构造函数，将ERC725添加为一个被支持的接口
    constructor() internal {
        supportedInterfaces[ERC725ID()] = true;
    }

    function ERC725ID() public pure returns (bytes4) {
        return (
            this.getKey.selector ^ this.keyHasPurpose.selector ^
            this.getKeysByPurpose.selector ^
            this.addKey.selector ^ this.removeKey.selector ^
            this.execute.selector ^ this.approve.selector ^
            this.changeKeysRequired.selector ^ this.getKeysRequired.selector
        )
    }

    // purpose
    // 管理密钥，可以用来管理这个identity
    uint256 public constant MANAGEMENT_KEY = 1;
    // 执行密钥，以此身份执行操作
    uint256 public constant EXECUTION_KEY = 2;
    // 声明签名者密钥，用于对其他需要撤销的身份进行签名
    uint256 public constant CLAIM_SIGNER_KEY = 3;
    // 加密密钥，用于加密数据，比如保存在声明中
    uint256 public constant ENCRYPTION_KEY = 4;

    // keyType
    uint256 public constant ECDSA_TYPE = 1;
    uint256 public constant RSA_TYPE = 2;

    // Events
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);
    event KeysRequiredChanged(uint256 indexed purpose, uint256 indexed number);
    // 额外的event，不属于标准的一部分
    event EcecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    // Functions
    function getKey(bytes32 _key) public view returns(uint256[] memory purposes, uint256 keyType, bytes32 key);
    function keyHasPurpose(bytes32 _key, uint256 purpose) public view returns(bool exists);
    function getKeysByPurpose(uint256 _purpose) public view returns(bytes32[] memory keys);
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool success);
    function removeKey(bytes32 _key, uint256 _purpose) public returns(bool success);
    function changeKeysRequired(uint256 purpose, uint256 number) external;
    function getKeysRequired(uint256 purpose) external view returns(uint256);
    function execute(address _to, uint256 _value, bytes memory _data) public returns(uint256 executionId);
    function approve(uint256 _id, bool _approve) public returns (bool success);
}