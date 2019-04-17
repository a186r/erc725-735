pragma solidity >= 0.5.7 < 0.6.0;

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
}