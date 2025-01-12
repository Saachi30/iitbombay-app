// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedDataSharing is ERC721, Ownable {
    struct File {
        string ipfsHash;
        string metadata;
        string encryptedKey;
        address owner;
        bool isNFT;
        bool isUniversalAccess;
        mapping(address => Access) accessControl;
        AccessLog[] accessLogs;
    }

    struct Access {
        bool hasAccess;
        uint256 expiration;
    }

    struct AccessLog {
        address accessor;
        uint256 timestamp;
        string action;
    }

    struct Company {
        string name;
        bool isAuthorized;
    }

    mapping(string => File) private files;
    mapping(address => Company) public companies;
    mapping(address => string[]) public userFiles;

    uint256 public nextTokenId;
    address public admin;

    event NFTMinted(uint256 tokenId, string ipfsHash, address owner);
    event FileUploaded(string ipfsHash, address owner);
    event AccessGranted(string ipfsHash, address recipient, uint256 expiration);
    event AccessRevoked(string ipfsHash, address recipient);
    event OwnershipTransferred(string ipfsHash, address newOwner);
    event NFTBurned(uint256 tokenId, address owner);
    event UniversalAccessSet(string ipfsHash, bool isUniversal);
    event AccessRequested(string ipfsHash, address requester);

    modifier onlyOwnerOfFile(string memory ipfsHash) {
        require(msg.sender == files[ipfsHash].owner, "Not the owner.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin.");
        _;
    }

    constructor(address initialOwner) ERC721("AbhyudayaToken", "ABH") Ownable(initialOwner) {
        admin = initialOwner;
        nextTokenId = 1;
    }

    function mintNFT(string memory ipfsHash, string memory metadata, string memory encryptedKey) public {
        require(bytes(ipfsHash).length > 0, "IPFS hash required.");
        require(files[ipfsHash].owner == address(0), "File exists.");

        uint256 tokenId = nextTokenId++;
        _mint(msg.sender, tokenId);

        File storage newFile = files[ipfsHash];
        newFile.ipfsHash = ipfsHash;
        newFile.metadata = metadata;
        newFile.encryptedKey = encryptedKey;
        newFile.owner = msg.sender;
        newFile.isNFT = true;

        userFiles[msg.sender].push(ipfsHash);
        emit NFTMinted(tokenId, ipfsHash, msg.sender);
    }

    function burnNFT(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner.");
        _burn(tokenId);
        emit NFTBurned(tokenId, msg.sender);
    }

    function uploadData(string memory ipfsHash, string memory metadata, string memory encryptedKey) public {
        require(bytes(ipfsHash).length > 0, "IPFS hash required.");
        require(files[ipfsHash].owner == address(0), "File exists.");

        File storage newFile = files[ipfsHash];
        newFile.ipfsHash = ipfsHash;
        newFile.metadata = metadata;
        newFile.encryptedKey = encryptedKey;
        newFile.owner = msg.sender;

        userFiles[msg.sender].push(ipfsHash);
        emit FileUploaded(ipfsHash, msg.sender);
    }

    function grantAccess(string memory ipfsHash, address recipient, uint256 expiration) public onlyOwnerOfFile(ipfsHash) {
        files[ipfsHash].accessControl[recipient] = Access(true, expiration);
        files[ipfsHash].accessLogs.push(AccessLog(recipient, block.timestamp, "granted"));
        emit AccessGranted(ipfsHash, recipient, expiration);
    }

    function revokeAccess(string memory ipfsHash, address recipient) public onlyOwnerOfFile(ipfsHash) {
        files[ipfsHash].accessControl[recipient].hasAccess = false;
        files[ipfsHash].accessLogs.push(AccessLog(recipient, block.timestamp, "revoked"));
        emit AccessRevoked(ipfsHash, recipient);
    }

    function transferOwnership(string memory ipfsHash, address newOwner) public onlyOwnerOfFile(ipfsHash) {
        files[ipfsHash].owner = newOwner;
        emit OwnershipTransferred(ipfsHash, newOwner);
    }

    function registerCompany(address companyAddress, string memory name) public onlyAdmin {
        require(bytes(name).length > 0, "Name required.");
        companies[companyAddress] = Company(name, false);
    }

    function authorizeCompany(address companyAddress) public onlyAdmin {
        companies[companyAddress].isAuthorized = true;
    }

    function revokeCompanyAuthorization(address companyAddress) public onlyAdmin {
        companies[companyAddress].isAuthorized = false;
    }

    function uploadCompanyData(string memory ipfsHash, string memory metadata, string memory encryptedKey, bool isUniversalAccess) public {
        require(companies[msg.sender].isAuthorized, "Company not authorized.");
        require(bytes(ipfsHash).length > 0, "IPFS hash required.");
        require(files[ipfsHash].owner == address(0), "File exists.");

        File storage newFile = files[ipfsHash];
        newFile.ipfsHash = ipfsHash;
        newFile.metadata = metadata;
        newFile.encryptedKey = encryptedKey;
        newFile.owner = msg.sender;
        newFile.isUniversalAccess = isUniversalAccess;

        userFiles[msg.sender].push(ipfsHash);
        emit FileUploaded(ipfsHash, msg.sender);
        if (isUniversalAccess) emit UniversalAccessSet(ipfsHash, true);
    }

    function setUniversalAccess(string memory ipfsHash, bool status) public onlyOwnerOfFile(ipfsHash) {
        files[ipfsHash].isUniversalAccess = status;
        emit UniversalAccessSet(ipfsHash, status);
    }

    function getAccessLogs(string memory ipfsHash) public view onlyOwnerOfFile(ipfsHash) returns (AccessLog[] memory) {
        return files[ipfsHash].accessLogs;
    }

    function getAccessRequests(string memory ipfsHash) public view onlyOwnerOfFile(ipfsHash) returns (AccessLog[] memory) {
        AccessLog[] memory allLogs = files[ipfsHash].accessLogs;
        uint256 count;
        for (uint256 i = 0; i < allLogs.length; i++) {
            if (keccak256(bytes(allLogs[i].action)) == keccak256("requested")) count++;
        }

        AccessLog[] memory requests = new AccessLog[](count);
        uint256 index;
        for (uint256 i = 0; i < allLogs.length; i++) {
            if (keccak256(bytes(allLogs[i].action)) == keccak256("requested")) {
                requests[index++] = allLogs[i];
            }
        }
        return requests;
    }

    function getUserUploadedData(address user) public view returns (string[] memory, string[] memory, bool[] memory, bool[] memory) {
        string[] memory userFilesList = userFiles[user];
        uint256 length = userFilesList.length;

        string[] memory metadataList = new string[](length);
        bool[] memory isNFTList = new bool[](length);
        bool[] memory isUniversalList = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            File storage file = files[userFilesList[i]];
            metadataList[i] = file.metadata;
            isNFTList[i] = file.isNFT;
            isUniversalList[i] = file.isUniversalAccess;
        }

        return (userFilesList, metadataList, isNFTList, isUniversalList);
    }

    function getUserNFTs(address user) public view returns (uint256[] memory, string[] memory, string[] memory) {
        uint256 balance = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](balance);
        string[] memory ipfsHashes = new string[](balance);
        string[] memory metadataList = new string[](balance);

        uint256 index;
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (ownerOf(i) == user) tokenIds[index++] = i;
        }

        return (tokenIds, ipfsHashes, metadataList);
    }
    function getEncryptedKey(string memory ipfsHash) public view returns (string memory) {
    require(bytes(ipfsHash).length > 0, "IPFS hash required.");
    File storage file = files[ipfsHash];
    require(file.accessControl[msg.sender].hasAccess, "Access not granted.");
    require(block.timestamp <= file.accessControl[msg.sender].expiration, "Access expired.");
    
    return file.encryptedKey;
}

function getSharedFile(string memory ipfsHash) public view returns (string memory, string memory, bool) {
    require(bytes(ipfsHash).length > 0, "IPFS hash required.");
    File storage file = files[ipfsHash];
    require(file.accessControl[msg.sender].hasAccess, "Access not granted.");
    require(block.timestamp <= file.accessControl[msg.sender].expiration, "Access expired.");

    return (file.ipfsHash, file.metadata, file.isUniversalAccess);
}

}