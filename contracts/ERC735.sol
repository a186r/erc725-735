pragma solidity >= 0.5.7 < 0.6.0;

import "./ERC165.sol";

contract ERC735 is ERC165 {

    constructor() internal {
        supportedInterfaces[ERC735ID()] = true;
    }

    function ERC735ID() public pure returns (bytes4) {
        return (
            this.getClaim.selector ^ this.getClaimIdsByType.selector ^
            this.addClaim.selector ^ this.removeClaim.selector
        )
    }

    // Topic
    uint256 public constant BIOMETRIC_TOPIC = 1; //你是个人，不是公司
    uint256 public constant RESIDENCE_TOPIC = 2; //你有一个物理地址，或者参考点
    uint256 public constant REGISTRY_TOPIC = 3;
    uint256 public constant ROFILE_TOPIC = 4; //社交媒体档案，例如博客等等
    uint256 public constant LABEL_TOPIC = 5; //真实姓名、企业名称、昵称、别名等等

    // Scheme
    uint256 public constant ECDSA_SCHEME = 1;
    uint256 public constant RSA_SCHEME = 2;
    // 3是合约验证，其中的数据将是调用数据，发行者将调用一个合约地址
    uint256 public constant CONTRACT_CHEME = 3;

    // Events
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    // Functions
    function getClaim(bytes32 _claimId) public view returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);
    function getClaimIdsByType(uint256 _topic) public view returns(bytes32[] memory claimIds);
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes memory _signature, bytes memory _data, string memory _uri) public returns (uint256 claimRequestId);
    function removeClaim(bytes32 _claimId) public returns (bool success);

}