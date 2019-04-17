pragma solidity >= 0.5.7 < 0.6.0

/// @dev Based on https://github.com/ethereum/EIPs/pull/881

contract ERC165 {
    
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() internal {
        supportedInterfaces[ERC165ID()] = true;
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return supportedInterfaces[interfaceID];
    }

    function ERC165ID() public pure returns(bytes4) {
        return this.supportsInterface.selector;
    }
}