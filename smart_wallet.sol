//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

contract commonCheck{

    event ValidationError(string errorMsg);
    function isValidNumber(uint8 _num) internal {
        require(_num > 0,"Provided Data can't be 0");
        emit ValidationError("Provided Data can't be 0");
    }

}

contract SimpleWallet is commonCheck{

    struct familyMember{
        string name;
        uint age;
        uint allowance;
        address payable ownWallet;
    }

    struct Wallet{
        uint balance;
        address payable currentBalance;
    }

    address owner;
    uint8 memberCount;
    mapping(address => Wallet) familyWallet;
    mapping(uint => address) memberAddress;
    mapping(address => familyMember) public familyMembers;

    event TransactionUpdate(address indexed from, uint amount, string message);

    constructor() {
        checkIfValidAddress(msg.sender);
        owner = msg.sender;
    }

    // Modifier to check only owner can access a certain function 
    modifier onlyOwner {
        // Check if the msg.sender is owner
        require(msg.sender == owner);
        _;
    }

    // Modifier to check only family member can access a certain function
    modifier onlyFamilyMember{
        require(msg.sender != owner);
        _;
    }

    // Receive fund from anyone
    receive() external payable {
        // AddFundToWallet();
    }

    /*
        Check if its a valid address
    */
    function checkIfValidAddress(address _address) pure internal {
        require(_address != address(0),"Invalid Address");
        assert(_address != 0x0000000000000000000000000000000000000001);
    }

    /*
        Function to set allowance for family member
    */
    function AddFamilyMember(string memory _name, uint8 _age, uint _maxAllowance, address _addr) onlyOwner public {
        checkIfValidAddress(msg.sender);
        memberCount++;
        isValidNumber(_age);
        memberAddress[memberCount] = _addr;
        familyMembers[_addr] = familyMember(_name, _age, _maxAllowance, payable(_addr));
    }

    // Update Allowance
    function updateAllowance(uint _newAllowance, address _addr) onlyOwner public {
        checkIfValidAddress(msg.sender);
        familyMembers[_addr].allowance += _newAllowance;
    }

    function checkCurrentBalance(uint _amount) view internal {
        require(_amount <= familyWallet[owner].balance,"Insufficient Fund");
    }

    function depositeFund() public payable onlyOwner  {
        require(msg.value >= 1 gwei,"Request amount very small");
        // AddFundToWallet();
        // If require returns false then the function will not execute further and gas will be refunded.
        require(msg.value > 1 wei,"Not value fund");
        // get the value prior the transaction, so that we can compare it later after transaction.
        uint balPriorToTransfer = familyWallet[msg.sender].balance;
        familyWallet[msg.sender].balance += msg.value;
        //wal = payable(msg.value);
        payable(familyWallet[msg.sender].currentBalance).transfer(msg.value);
        // Now the new fund on family wallter should be greate than before the transacrtion.
        // Here below, if the assert fails, then it will revert all the state change and will not refund any gas.
        assert(familyWallet[msg.sender].balance > balPriorToTransfer);
    }

    // only Owner can withdrawl any given fund
    function withdrawlFund(uint _amount) onlyOwner public {
        checkCurrentBalance(_amount);
        uint balPriorToTransfer = familyWallet[msg.sender].balance;
        familyWallet[msg.sender].balance -= _amount;
        payable(familyWallet[msg.sender].currentBalance).transfer(_amount);
        assert(familyWallet[msg.sender].balance < balPriorToTransfer);
    }

    // family member can withdraw can fund.
    function familyMemberWithdrawFund(uint _reqFund) onlyFamilyMember public payable{
        require(familyMembers[msg.sender].allowance >= _reqFund,"Requested Fund exceeds allowance");
        checkCurrentBalance(_reqFund);
        familyMembers[msg.sender].allowance -= _reqFund;
        familyMembers[msg.sender].ownWallet.transfer(_reqFund);
        // familyMembers[msg.sender].ownWallet.transfer(_reqFund); ----> Check this
    }

    // only Owner can withdraw all the fund.
    function withDrawAllFund() onlyOwner public {
        uint balPriorToTransfer = familyWallet[msg.sender].balance;
        familyWallet[msg.sender].balance = 0;
        payable(familyWallet[msg.sender].currentBalance).transfer(balPriorToTransfer);
        assert(familyWallet[msg.sender].balance == 0);
    }

    // Check current balance of wallet
    function checkWalletBalance() onlyOwner view public returns(uint){
        return(familyWallet[msg.sender].balance);
    }

    // get all the family memeber list
    function getAllFamilyMember() onlyOwner view public returns(string[] memory){
        string[] memory tempEmp = new string[](memberCount);
         for(uint i = 0;i < memberCount; i++) {
            tempEmp[i] = familyMembers[memberAddress[i+1]].name;
         }
        return tempEmp;
    }
}