pragma solidity >=0.4.21 <0.6.0;

/// @dev 用于管理ERC725 key的数组的库
library KeyStore{
    
    // key的结构体
    struct Key{
        uint256[] purposes; //目的，比如：MANAGEMENT_KEY = 1, EXECUTION_KEY = 2, 等等
        uint256[] keyType; //加密方法，比如：1 = ECDSA, 2 = RSA, 等等
        bytes32 key; //key的Keccak256Hash
    }

    struct Keys{
        mapping (bytes32 => Key) keyData;
        mapping (uint256 => bytes32[]) keysByPurpose;
        uint numKeys;
    }

    ///@dev 查找一个key+purpose的元组是否存在
    ///@param key 要查找的密钥字节
    ///@param purpose 要查找的目的
    ///@return 如果找到，则返回true
    function find(Keys storage self, bytes32 key, uint256 purpose)
        internal
        view
        returns(bool)
    {
        Key memory k = self.keyData[key];
        if(k.key == 0) {
            return false;
        }
        for(uint i = 0 ; i < k.purposes.length; i++){
            if (k.purposes[i] == purpose){
                return true;
            }
        }
    }

    // 添加一个key
    function add(Key storage self, bytes32 key, uint256 purpose, uint256 keyType)
        internal
    {
        Key storage k = self.keyData[key];
        k.purpose.push(purpose);

        // 如果要添加的key不存在的话，继续添加
        if(k.key == 0){
            k.key = key;
            k.keyType = keyType;
        }
        self.keysByPurpose[purpose].push(key);
        self.numKeys++;
    }

    function remove(Keys storage self, bytes32 key, uint32 purpose)
        internal
        returns(uint256 keyType)
    {
        keyType = self.keyData[key].keyType;

        uint256[] storage p = self.keyData[key].purposes;
        // 从keyData中删除purpose
        for(uint i = 0; i < p.length; i++){
            if(p[i] == purpose) {
                p[i] = p[p.length - 1];
                delete p[p.length - 1];
                p.length--;
                self.numKeys--;
                break;
            }
        }

        // No more purpose
        if(p.length == 0){
            delete self.keyData[key];
        }

        // 从keysByPurpose中删除key
        bytes32[] storage k = self.keysByPurpose[purpose];
        for(uint i = 0; i < k.length; i++) {
            if (k[i] == key) {
                k[i] = k[k.length - 1];
                delete k[k.length - 1];
                k.length--;
            }
        }
    }
}