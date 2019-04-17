pragma solidity >=0.4.21 <0.6.0;

import "./KeyBase.sol";
// 可以被管理密钥或者身份本身销毁的基本合约
contract Destructible is KeyBase {

    function destoryAndSend(address _recipient)
        public
        onlyManagementOrSelf
    {
        require(_recipient != address(0), "recipient must exist");
        selfdestruct(address(uint160(_recipient)));
    }
}