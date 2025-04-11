// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract QuantumStorage {

    struct File {
        string cid;
        address owner;
        address uploader;
        uint timestamp;
        mapping(address => bool) accessList;
        address[] accessHistory;
    }

    mapping(uint => File) private files;
    uint private fileCounter;

    event FileStored(uint indexed fileId, address indexed uploader, string cid, uint timestamp);
    event AccessGranted(uint indexed fileId, address indexed grantee);
    event AccessRevoked(uint indexed fileId, address indexed revokedUser);
    event OwnershipTransferred(uint indexed fileId, address indexed oldOwner, address indexed newOwner);

    /// @notice Upload a new file with CID and save metadata
    function uploadFile(string calldata cid) external {
        require(bytes(cid).length > 0, "CID cannot be empty");

        fileCounter++;
        File storage newFile = files[fileCounter];
        newFile.cid = cid;
        newFile.owner = msg.sender;
        newFile.uploader = msg.sender;
        newFile.timestamp = block.timestamp;
        newFile.accessList[msg.sender] = true;
        newFile.accessHistory.push(msg.sender);

        emit FileStored(fileCounter, msg.sender, cid, block.timestamp);
    }

    /// @notice Grant access to a file
    function grantAccess(uint fileId, address user) external {
        require(files[fileId].owner == msg.sender, "Not the owner");
        require(user != address(0), "Invalid address");

        if (!files[fileId].accessList[user]) {
            files[fileId].accessList[user] = true;
            files[fileId].accessHistory.push(user);
            emit AccessGranted(fileId, user);
        }
    }

    /// @notice Revoke a user's access
    function revokeAccess(uint fileId, address user) external {
        require(files[fileId].owner == msg.sender, "Not the owner");
        require(user != msg.sender, "Owner cannot revoke self");
        require(files[fileId].accessList[user], "User doesn't have access");

        files[fileId].accessList[user] = false;
        emit AccessRevoked(fileId, user);
    }

    /// @notice Retrieve CID if access is granted
    function getCID(uint fileId) external view returns (string memory) {
        require(files[fileId].accessList[msg.sender], "Access denied");
        return files[fileId].cid;
    }

    /// @notice Check if a user has access
    function hasAccess(uint fileId, address user) external view returns (bool) {
        return files[fileId].accessList[user];
    }

    /// @notice Transfer ownership of the file
    function transferOwnership(uint fileId, address newOwner) external {
        require(files[fileId].owner == msg.sender, "Not the owner");
        require(newOwner != address(0), "Invalid new owner");

        address oldOwner = files[fileId].owner;
        files[fileId].owner = newOwner;
        files[fileId].accessList[newOwner] = true;
        files[fileId].accessHistory.push(newOwner);

        emit OwnershipTransferred(fileId, oldOwner, newOwner);
    }

    /// @notice Get file info (public metadata)
    function getFileInfo(uint fileId) external view returns (
        address owner,
        address uploader,
        string memory cid,
        uint timestamp,
        address[] memory accessUsers
    ) {
        require(files[fileId].accessList[msg.sender], "Access denied");

        File storage file = files[fileId];
        owner = file.owner;
        uploader = file.uploader;
        cid = file.cid;
        timestamp = file.timestamp;

        uint count;
        for (uint i = 0; i < file.accessHistory.length; i++) {
            if (file.accessList[file.accessHistory[i]]) {
                count++;
            }
        }

        accessUsers = new address[](count);
        uint index = 0;
        for (uint i = 0; i < file.accessHistory.length; i++) {
            address user = file.accessHistory[i];
            if (file.accessList[user]) {
                accessUsers[index++] = user;
            }
        }
    }

    /// @notice Total number of stored files
    function getTotalFiles() external view returns (uint) {
        return fileCounter;
    }
}
