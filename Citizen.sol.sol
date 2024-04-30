// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./MARS.sol";
// Define an interface for the ERC20 token
interface ERC20Token {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
// Define the main contract
contract CitizenshipCertificate is ERC721 {
    // State variables
    uint256 private _citizenIds;
    uint public CitizenshipPrice = 49;
    uint public Claim_Token_Reward=28;
    ERC20Token private token;
    MARS public marsContract;
    address public admin;
    address public tokenAddress;
    string public baseURI;
    mapping(uint256 => bool) private _certificateExists;
    mapping(uint256 => uint256) private _plotCertificates;
    mapping(uint256 => bool) private _tokensClaimed;
    mapping(address => bool) private _addressHasCertificate;
    mapping(address => uint256) private _userCitizenshipIds;
    // Events
    event CitizenshipBought(address indexed buyer, uint256 indexed plotId, uint256 indexed citizenshipId);
    event CitizenshipSold(address indexed seller, address indexed buyer, uint256 indexed citizenshipId, uint256 price);
    event PlotDataUpdated(uint256 indexed plotId, string plotData);
    event CertificateBurnt(uint256 indexed citizenshipId);
    event TokenAddressUpdated(address newTokenAddress);
    event TokensClaimed(address indexed claimer, uint256 indexed certificateId);
    

    // Modifier to restrict access to only the admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }
    // Constructor
    constructor(address marAddress) ERC721("Citizenship Certificate", "CITIZEN") {
        marsContract = MARS(marAddress);
        admin = msg.sender; // Set the deployer address as the admin
    }


function buyCitizenship(uint plotId) external {
    // Check if the caller owns the plot on Mars and if the plot already has a certificate
    require(marsContract.isPlotOwner(msg.sender, plotId), "You do not own this plot on Mars");
    require(marsContract.getUserBalance(msg.sender, plotId) > 0, "You do not own this plot on Mars");
    require(_plotCertificates[plotId] == 0, "This plot already has a certificate");

    // Ensure that the caller has not already purchased a certificate
    require(!_addressHasCertificate[msg.sender], "You have already purchased a certificate");

    // Ensure that the CitizenshipPrice is greater than zero
    require(CitizenshipPrice > 0, "Citizenship price must be greater than zero");

    // Generate unique citizenship ID with plot ID included
    uint256 certificateId = _generateCitizenshipId(plotId);

    // Mint citizenship certificate
    _mint(msg.sender, certificateId);
    _certificateExists[certificateId] = true; // Update certificate existence mapping
    _plotCertificates[plotId] = certificateId;
    _addressHasCertificate[msg.sender] = true; // Mark the address as having purchased a certificate

    // Save citizenship ID for the caller's address
    _userCitizenshipIds[msg.sender] = certificateId;

    // Update plot data within CitizenshipCertificate contract
    _updatePlotData(plotId, "Citizenship Granted");

    // Emit events
    emit CitizenshipBought(msg.sender, plotId, certificateId);
    emit PlotDataUpdated(plotId, "Citizenship Granted");
}

function _generateCitizenshipId(uint256 plotId) private view returns (uint256) {
    require(plotId <= 999, "Plot ID must be a 3-digit number");

    bytes32 randomHash = keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), _citizenIds));
    uint256 randomId1 = uint256(randomHash) % 1000; // First random number
    uint256 randomId2 = uint256(keccak256(abi.encode(randomHash, plotId))) % 1000; // Second random number

    uint256 citizenshipId;
    if (plotId < 10) {
        citizenshipId = (randomId1 * 100000) + (plotId * 10000) + randomId2;
    }
    else if (plotId < 100) {
        citizenshipId = (randomId1 * 1000000) + (plotId * 10000) + randomId2;
    }
    else {
        citizenshipId = (randomId1 * 10000000) + (plotId * 1000) + randomId2;
    }

    return citizenshipId;
}

// Function to update plot data within CitizenshipCertificate contract
function _updatePlotData(uint256 plotId, string memory newData) private {
    require(bytes(newData).length > 0, "New data must not be empty");
    emit PlotDataUpdated(plotId, newData);
}
    // Function to sell citizenship
    function sellCitizenship(address buyer, uint256 certificateId, uint256 price) external {
        require(_certificateExists[certificateId], "Certificate does not exist");
        require(ownerOf(certificateId) == msg.sender, "You do not own this citizenship certificate");
        // Transfer citizenship to the buyer
        _safeTransfer(msg.sender, buyer, certificateId, "");
        // Burn the citizenship certificate
        _burn(certificateId);
        emit CitizenshipSold(msg.sender, buyer, certificateId, price);
        emit CertificateBurnt(certificateId);
    }
    // Function to set citizenship price, accessible only by the admin
    function setCitizenshipPrice(uint newPrice) external onlyAdmin {
        CitizenshipPrice = newPrice;
    }
    // Function to set the token contract address
    function setTokenAddress(address newTokenAddress) external  {
        require(newTokenAddress != address(0), "Invalid token address");
        tokenAddress = newTokenAddress;
        token = ERC20Token(newTokenAddress); // Update the ERC20 token contract
        emit TokenAddressUpdated(newTokenAddress);
    }
    // Function to check if a given token ID has a citizenship certificate
    function hasCertificate(uint256 tokenId) external view returns (bool) {
        return _certificateExists[tokenId];
    }
    // Function to set the base URI, accessible only by the admin
    function setBaseURI(string memory _baseURI) external onlyAdmin {
        baseURI = _baseURI;
    }
    // Function to get the URI for a given token ID
    function uri(uint256 tokenId) public view returns (string memory) {
        require(bytes(baseURI).length > 0, "Base URI not set");
        require(_certificateExists[tokenId], "Certificate does not exist");
        string memory tokenIdStr = uint256ToString(tokenId);
        return string(abi.encodePacked(baseURI, tokenIdStr));
    }
    // Helper function to convert uint256 to string
    function uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
function claimTokens(uint256 certificateId) external {
    require(_certificateExists[certificateId], "Certificate does not exist");
    require(ownerOf(certificateId) == msg.sender, "You do not own this citizenship certificate");
    require(!_tokensClaimed[certificateId], "Tokens already claimed for this certificate");
    // Check allowance before transfer
    uint256 allowance = token.allowance(msg.sender, address(this));
    require(allowance >= Claim_Token_Reward, "Insufficient allowance for tokens. Please approve the contract first.");
    // Attempt token transfer with error handling
    bool success = token.transferFrom(msg.sender, address(this),Claim_Token_Reward);
    require(success, "Token transfer failed. Please check contract balance or token approval.");
    _tokensClaimed[certificateId] = true;
    emit TokensClaimed(msg.sender, certificateId);
}
function getCitizenshipIdByAddress(address userAddress) external view returns (uint256) {
        return _userCitizenshipIds[userAddress];
    }

}
