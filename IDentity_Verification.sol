// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IdentityVerification {
    address public dataValidatorAddress; // Address of the DataValidator contract

    struct Identity {
        string userName;
        string phone;
        string email;
        string adhar;
        bool isVerified;
    }

    struct ThirdPartyApp {
        string companyName;
        string email;
        string phoneNumber;
        bool isVerified;
    }

    mapping(address => Identity) public identities;
    mapping(address => ThirdPartyApp) public thirdPartyApps;
    mapping(address => bool) public thirdPartyAppRegistrations;

    // Event for identity verification
    event IdentityVerified(address indexed user);
    event ThirdPartyAppRegistered(address indexed appAddress);
    event ThirdPartyAppVerified(address indexed appAddress);
    event UserDataRequested(address indexed appAddress, string userName, string phone, string email);
    
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier isValidEmail(string memory _email) {
        require(_isValidEmail(_email), "Invalid email syntax");
        _;
    }

    modifier onlyVerifiedThirdPartyApp() {
        require(thirdPartyApps[msg.sender].isVerified, "Only verified third-party apps can call this function");
        _;
    }

    modifier isValidPhoneNumber(string memory _phoneNumber) {
        require(_isValidPhoneNumber(_phoneNumber), "Invalid phone number format");
        _;
    }

    modifier isValidAadhar(string memory _adhar) {
    require(_isValidAadhar(_adhar), "Invalid Aadhar number format");
    _;
}


    constructor(address _dataValidatorAddress) {
        admin = msg.sender;
        dataValidatorAddress = _dataValidatorAddress;
    }

    function setDataValidatorAddress(address _dataValidatorAddress) external onlyAdmin {
        dataValidatorAddress = _dataValidatorAddress;
    }

    function _isValidEmail(string memory _email) private pure returns (bool) {
        
        bytes memory emailBytes = bytes(_email);
        uint256 atIndex;
        for (uint256 i = 0; i < emailBytes.length; i++) {
            if (emailBytes[i] == '@') {
                atIndex = i;
                break;
            }
        }
        if (atIndex == 0 || atIndex == emailBytes.length - 1) return false;

        bool dotFound = false;
        for (uint256 i = atIndex + 1; i < emailBytes.length; i++) {
            if (emailBytes[i] == '.') {
                dotFound = true;
                break;
            }
        }
        return dotFound;
    }

    function _isValidPhoneNumber(string memory _phoneNumber) private pure returns (bool) {
        // Check if the phone number has exactly 10 digits
        bytes memory b = bytes(_phoneNumber);
        if (b.length != 10) return false;
        for (uint256 i = 0; i < b.length; i++) {
            uint8 digit = uint8(b[i]);
            if (digit < uint8(48) || digit > uint8(57)) {
                // Not a digit
                return false;
            }
        }
        return true;
    }

    function _isValidAadhar(string memory _adhar) private pure returns (bool) {
    // Check if the Aadhar number has the format XXXX-XXXX-XXXX
    bytes memory b = bytes(_adhar);
    if (b.length != 14) return false; // The length should be 14 including hyphens
    if (b[4] != '-' || b[9] != '-') return false; // Check hyphen positions
    for (uint256 i = 0; i < b.length; i++) {
        if (i == 4 || i == 9) {
            continue; // Skip hyphens
        }
        uint8 digit = uint8(b[i]);
        if (digit < uint8(48) || digit > uint8(57)) {
            return false; // Not a digit
        }
    }
    return true;
}



    function registerIdentity(
        string memory _userName,
        string memory _phone,
        string memory _email,
        string memory _adhar,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
    require(bytes(_userName).length > 0, "User name must not be empty");
    require(bytes(_phone).length > 0, "Phone must not be empty");
    require(bytes(_email).length > 0, "Email must not be empty");
    require(bytes(_adhar).length > 0, "Aadhar must not be empty");
    require(dataValidatorAddress != address(0), "DataValidator contract address not set");
    require(_isValidEmail(_email), "Invalid email syntax");
    require(_isValidPhoneNumber(_phone), "Invalid phone number format");
    require(_isValidAadhar(_adhar), "Invalid Aadhar number format");

    DataValidator dataValidator = DataValidator(dataValidatorAddress); // Instantiate DataValidator contract
    require(dataValidator.isValidUser(_userName, _phone, _email, _adhar), "Invalid user data");

    // Generate the hash of the message
    bytes32 hashedMessage = keccak256(abi.encodePacked(_userName, _phone, _email, _adhar));

    // Verify the signature
    require(VerifyMessage(hashedMessage, _v, _r, _s) == msg.sender, "Signature verification failed");

    Identity memory identity = Identity(_userName, _phone, _email, _adhar, false);
    identities[msg.sender] = identity;

    emit IdentityVerified(msg.sender);
}


    function registerThirdPartyApp(
        string memory _companyName,
        string memory _email,
        string memory _phoneNumber,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(bytes(_companyName).length > 0, "Company name must not be empty");
        require(bytes(_email).length > 0, "Email must not be empty");
        require(bytes(_phoneNumber).length > 0, "Phone number must not be empty");
        require(!thirdPartyAppRegistrations[msg.sender], "Third-party app already registered");
        require(_isValidEmail(_email), "Invalid email syntax");
        require(_isValidPhoneNumber(_phoneNumber), "Invalid phone number format");


        // Verify the signature
        bytes32 hashedMessage = keccak256(abi.encodePacked(_companyName, _email, _phoneNumber));
        require(VerifyMessage(hashedMessage, _v, _r, _s) == msg.sender, "Signature verification failed");


        thirdPartyApps[msg.sender] = ThirdPartyApp({
            companyName: _companyName,
            email: _email,
            phoneNumber: _phoneNumber,
            isVerified: false
        });

        thirdPartyAppRegistrations[msg.sender] = true;

        emit ThirdPartyAppRegistered(msg.sender);
    }

    function VerifyMessage(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function verifyThirdPartyApp(address _appAddress) external onlyAdmin {
        ThirdPartyApp storage app = thirdPartyApps[_appAddress];
        require(bytes(app.companyName).length > 0, "Third-party app not registered");
        require(bytes(app.email).length > 0, "Email not registered");
        require(bytes(app.phoneNumber).length > 0, "Phone number not registered");
        require(!app.isVerified, "Third-party app already verified");

        app.isVerified = true;

        // ThirdPartyAppVerified event will be recorded in blockchain
        emit ThirdPartyAppVerified(_appAddress);
    }

    function requestUserData() external onlyVerifiedThirdPartyApp view returns (string memory, string memory, string memory) {
        Identity storage identity = identities[msg.sender];
        require(bytes(identity.userName).length > 0, "Identity not registered");
        require(bytes(identity.phone).length > 0, "phone not registered");
        require(bytes(identity.email).length > 0, "Email not registered");
        
        // Return user details only if the third-party app is verified
        return (identity.userName, identity.phone, identity.email);
    }
}


