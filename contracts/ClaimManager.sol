pragma solidity >=0.4.21 <0.6.0;

import "../node_modules/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./Pausable.sol";
import "./ERC725.sol";
import "./ERC735.sol";
import "./ERC165Query.sol";

// 执行ERC735规范中的功能
contract ClaimManager{
    using ECDSA for bytes32;
    using ERC165Query for address;
}