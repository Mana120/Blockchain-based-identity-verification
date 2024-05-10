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

contract DataValidator {
    struct UserData {
        string userName;
        string phone;
        string email;
        string adhar;
        bool isValid;
    }

    mapping(string => UserData) private userData;
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor() {
    admin = msg.sender;

    addUser("Aarav", "9876543210", "aarav@example.com", "1234-5678-9012");
    addUser("Aarohi", "8765432109", "aarohi@example.com", "9876-5432-1098");
    addUser("Aditya", "7654321098", "aditya@example.com", "2345-6789-0123");
    addUser("Aisha", "6543210987", "aisha@example.com", "3456-7890-1234");
    addUser("Ananya", "5432109876", "ananya@example.com", "4567-8901-2345");
    addUser("Arjun", "4321098765", "arjun@example.com", "5678-9012-3456");
    addUser("Avani", "3210987654", "avani@example.com", "6789-0123-4567");
    addUser("Ayaan", "2109876543", "ayaan@example.com", "7890-1234-5678");
    addUser("Diya", "1098765432", "diya@example.com", "8901-2345-6789");
    addUser("Ishaan", "9988776655", "ishaan@example.com", "9012-3456-7890");
    addUser("Kabir", "8877665544", "kabir@example.com", "1098-7654-3210");
    addUser("Meera", "7766554433", "meera@example.com", "9876-5432-1098");
    addUser("Mihir", "6655443322", "mihir@example.com", "8765-4321-0987");
    addUser("Neha", "5544332211", "neha@example.com", "7654-3210-9876");
    addUser("Pranav", "4433221100", "pranav@example.com", "6543-2109-8765");
    addUser("Riya", "3322110099", "riya@example.com", "5432-1098-7654");
    addUser("Rohan", "2211009988", "rohan@example.com", "4321-0987-6543");
    addUser("Saanvi", "1100998877", "saanvi@example.com", "3210-9876-5432");
    addUser("Samaira", "0099887766", "samaira@example.com", "2109-8765-4321");
    addUser("Samarth", "9988776655", "samarth@example.com", "0123-4567-8901");
    addUser("Aaradhya", "9877665544", "aaradhya@example.com", "1234-5678-9012");
    addUser("Advik", "8766554433", "advik@example.com", "9876-5432-1098");
    addUser("Amaira", "7655443322", "amaira@example.com", "2345-6789-0123");
    addUser("Anika", "6544332211", "anika@example.com", "3456-7890-1234");
    addUser("Arnav", "5433221100", "arnav@example.com", "4567-8901-2345");
    addUser("Ishani", "4322110099", "ishani@example.com", "5678-9012-3456");
    addUser("Kiaan", "3211009988", "kiaan@example.com", "6789-0123-4567");
    addUser("Kavya", "2110099887", "kavya@example.com", "7890-1234-5678");
    addUser("Kiara", "1009988776", "kiara@example.com", "8901-2345-6789");
    addUser("Reyansh", "9877655443", "reyansh@example.com", "9012-3456-7890");
    addUser("Rudra", "8765544332", "rudra@example.com", "1098-7654-3210");
    addUser("Sai", "7654433221", "sai@example.com", "9876-5432-1098");
    addUser("Shaurya", "6543322110", "shaurya@example.com", "8765-4321-0987");
    addUser("Shreya", "5432211009", "shreya@example.com", "7654-3210-9876");
    addUser("Tanishka", "4322110098", "tanishka@example.com", "6543-2109-8765");
    addUser("Tushar", "3211009987", "tushar@example.com", "5432-1098-7654");
    addUser("Vedant", "2110099886", "vedant@example.com", "4321-0987-6543");
    addUser("Vihaan", "1009988775", "vihaan@example.com", "3210-9876-5432");
    addUser("Vivaan", "9998877664", "vivaan@example.com", "2109-8765-4321");
    addUser("Yash", "9887766553", "yash@example.com", "0123-4567-8901");
    addUser("Yuvan", "8776655442", "yuvan@example.com", "1234-5678-9012");
    addUser("Zara", "7665544331", "zara@example.com", "9876-5432-1098");
    addUser("Zoya", "6554433220", "zoya@example.com", "2345-6789-0123");
}


    function addUser(string memory _userName, string memory _phone, string memory _email, string memory _adhar) internal {
    require(bytes(_userName).length > 0, "User name must not be empty");
    require(_isValidPhoneNumber(_phone), "Invalid phone number format");
    require(bytes(_email).length > 0 && _isValidEmail(_email), "Invalid email syntax");
    require(_isValidAadhar(_adhar), "Invalid Aadhar number format");

    userData[_userName] = UserData(_userName, _phone, _email, _adhar, true);
}

    function isValidUser(string memory _userName, string memory _phone, string memory _email, string memory _adhar) external view returns (bool) {
        UserData memory user = userData[_userName];
        return user.isValid && 
               keccak256(bytes(user.phone)) == keccak256(bytes(_phone)) && 
               keccak256(bytes(user.email)) == keccak256(bytes(_email)) &&
               keccak256(bytes(user.adhar)) == keccak256(bytes(_adhar));
    }

    function updateUser(string memory _userName, string memory _newPhone, string memory _newEmail) external onlyAdmin {
        require(bytes(_userName).length > 0, "User name must not be empty");
        require(_isValidPhoneNumber(_newPhone), "Invalid new phone number format");
        require(bytes(_newEmail).length > 0 && _isValidEmail(_newEmail), "Invalid new email syntax");

        UserData storage user = userData[_userName];
        require(user.isValid, "User not found");

        user.phone = _newPhone;
        user.email = _newEmail;
    }

    function _isValidPhoneNumber(string memory _phoneNumber) private pure returns (bool) {
        bytes memory b = bytes(_phoneNumber);
        if (b.length != 10) return false;
        for (uint256 i = 0; i < b.length; i++) {
            uint8 digit = uint8(b[i]);
            if (digit < uint8(48) || digit > uint8(57)) {
                return false; // Not a digit
            }
        }
        return true;
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

}

