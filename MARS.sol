// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Importing OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MARS is ERC1155, ReentrancyGuard {
    // State variable
    string public name;
    string public symbol;
    uint256 public price;
    string public baseURI;
    address public tokenAddress; // Address of the USDT token contract
    uint256 private _tokenIds; // Counter for generating unique token IDs
    mapping(uint256 => string) public plots;
    mapping(uint256 => address) private _plotOwners;
    mapping(address => mapping(uint256 => uint256)) private _userBalances;
    mapping(uint256 => uint256) private _totalSupply; // Total supply of minted tokens for each ID
    uint256 private constant MAX_TOKEN_ID = 450; // Maximum token ID allowed

    // Events
    event TokenMinted(address indexed to, uint256 indexed tokenId, uint256 amount);
    event BaseURIUpdated(string newBaseURI);
    event PlotDataUpdated(uint256 indexed tokenId, string plotData);
    event PriceUpdated(uint256 newPrice);
    event TokenAddressUpdated(address newTokenAddress);

    // Constructor
    constructor() ERC1155(" ") {
        name = "Interstellar";
        symbol = "IINTR";
        price = 29; // $29(token)
        emit PriceUpdated(price);
    }

    // Mint function to create new tokens
function mint(uint256 tokenId, uint256 amount, string calldata plotData) external nonReentrant {
    // Check if the token ID is within the allowed range
    require(tokenId >= 0 && tokenId <= 450, "Invalid token ID");
    // Check if the requested amount does not exceed the maximum supply
    require(amount <= 321777780, "Exceeds maximum supply");
    // Check if the total balance after minting doesn't exceed the maximum supply
    require(balanceOf(msg.sender, tokenId) + amount <= 321777780, "Exceeds remaining supply");
    // Check if the user has sufficient USDT balance for the minting
    require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), price * amount), "USDT transfer failed");

    // Mint new tokens with the specified supply
    _mint(msg.sender, tokenId, amount, "");
    // Update user balance
    _userBalances[msg.sender][tokenId] += amount;
    // Set plot data for the token
    plots[tokenId] = plotData;
    // Set plot owner
    if (_plotOwners[tokenId] == address(0)) {
        _plotOwners[tokenId] = msg.sender;
    }
    // Update total supply
    _totalSupply[tokenId] += amount;
    // Emit token minted event
    emit TokenMinted(msg.sender, tokenId, amount);
    // Emit plot data updated event
    emit PlotDataUpdated(tokenId, plotData);
}



    // Function to set the base URI for token metadata
    function setBaseURI(string calldata newBaseURI) external {
        baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    // Function to set the address of the USDT token contract
    function setTokenAddress(address newTokenAddress) external {
        require(newTokenAddress != address(0), "Invalid token address");
        tokenAddress = newTokenAddress;
        emit TokenAddressUpdated(newTokenAddress);
    }

    // In the MARS contract
    function updatePlotData(uint256 plotId, string memory newData) external {
        require(msg.sender == _plotOwners[plotId], "You are not the owner of this plot");
        plots[plotId] = newData;
        emit PlotDataUpdated(plotId, newData);
    }

    // Function to get the URI for a given token ID
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(bytes(baseURI).length > 0, "Base URI not set");
        require(_totalSupply[tokenId] > 0, "This ID has not been minted yet");

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

    // Function to check if an address owns a plot (token) ID
    function isPlotOwner(address account, uint256 tokenId) public view returns (bool) {
        return _plotOwners[tokenId] == account;
    }

    // Function to get the remaining balance of a user for a specific token ID
    function getUserBalance(address account, uint256 tokenId) public view returns (uint256) {
        return _userBalances[account][tokenId];
    }

   // Existing state variables and functions remain unchanged

// Function to get the token IDs and corresponding supply minted by a specific address
function TotalFraction(address account) public view returns (uint256[] memory, uint256[] memory) {
    uint256[] memory tokenIds = new uint256[](MAX_TOKEN_ID); // Assuming MAX_TOKEN_ID is the maximum possible token ID
    uint256[] memory tokenSupplies = new uint256[](MAX_TOKEN_ID); // Array to store corresponding token supplies

    uint256 count = 0; // Counter for the number of token IDs found

    // Iterate through the token IDs to find the ones minted by the specified address
    for (uint256 i = 0; i <= MAX_TOKEN_ID; i++) {
        if (_userBalances[account][i] > 0) {
            tokenIds[count] = i; // Store the token ID
            tokenSupplies[count] = _userBalances[account][i]; // Store the corresponding token supply
            count++;
        }
    }

    // Resize the arrays to remove unused slots
    assembly {
        mstore(tokenIds, count)
        mstore(tokenSupplies, count)
    }

    return (tokenIds, tokenSupplies);
}
function getPlotSupply(uint256 plotId) external view returns (uint256) {
    require(plotId >= 0 && plotId <= MAX_TOKEN_ID, "Invalid plot ID");
    return _totalSupply[plotId];
}



}
