pragma solidity >= 0.5.7 < 0.6.0;

import "./KeyBase.sol";

// 允许实施紧急停止机制的基础合约
contract Pausable is KeyBase {
    event LogPause();
    event LogUnpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "contract paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "contract not paused");
    }

    // 由管理密钥或者身份本身调用暂停，触发停止状态
    function pause()
        public
        onlyManagementOrSelf
        whenNotPause
    {
        paused = true;
        emit LogPause();
    }

    // 由管理者或者身份本身调用以解除暂停，恢复正常状态
    functio unpause()
        public
        onlyManagementOrSelf
        whenNotPause
    {
        paused = false;
        emit LogUnpause();
    }

}