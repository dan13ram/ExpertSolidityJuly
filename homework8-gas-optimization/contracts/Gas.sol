// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

contract GasContract {
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct ImportantStruct {
        uint16 valueA; // max 3 digits
        uint128 bigValue;
        uint16 valueB; // max 3 digits
    }

    uint256 public immutable totalSupply; // cannot be updated
    address public immutable contractOwner;
    uint256 public paymentCounter;
    mapping(address => uint256) public balances;
    uint256 public tradePercent = 12;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;

    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 id,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    modifier onlyAdminOrOwner() {
        require(
            contractOwner == msg.sender || _checkForAdmin(msg.sender),
            "not owner or admin"
        );
        _;
    }

    modifier onlyWhiteListed() {
        uint256 usersTier = whitelist[msg.sender];
        require(usersTier > 0 && usersTier < 4, "not whitelisted");
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                }
            }
        }
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        address senderOfTx = msg.sender;
        require(balances[senderOfTx] >= _amount, "insufficient Balance");
        require(bytes(_name).length < 9, "invalid name");
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        Payment memory payment;
        payment.admin = address(0);
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[senderOfTx].push(payment);
        bool[] memory status = new bool[](tradePercent);
        for (uint256 i = 0; i < tradePercent; i++) {
            status[i] = true;
        }
        return (status[0] == true);
    }

    function updatePayment(
        address _user,
        uint256 _id,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        require(_id > 0, "invalid id");
        require(_amount > 0, "invalid amount");
        require(_user != address(0), "zero address");

        address senderOfTx = msg.sender;

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _id) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                emit PaymentUpdated(
                    senderOfTx,
                    _id,
                    _amount,
                    payments[_user][ii].recipientName
                );
            }
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        require(_tier < 255, "invalid tier");
        whitelist[_userAddrs] = _tier;
        if (_tier > 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 3;
        } else if (_tier == 1) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 1;
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 2;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount,
        ImportantStruct calldata _struct
    ) public onlyWhiteListed {
        uint256 balance = balances[msg.sender];
        uint256 whitelisted = whitelist[msg.sender];
        require(balance >= _amount, "insufficient balance");
        require(_amount > 3, "amount too low");
        balances[msg.sender] = balance - _amount + whitelisted;
        balances[_recipient] = balances[_recipient] + _amount - whitelisted;

        whiteListStruct[msg.sender] = _struct;
        emit WhiteListTransfer(_recipient);
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    function getPayments(address _user) public view returns (Payment[] memory) {
        require(_user != address(0), "zero address");
        return payments[_user];
    }

    function getTradingMode() public pure returns (bool mode) {
        mode = true;
    }

    function _checkForAdmin(address _user) internal view returns (bool admin) {
        for (uint256 i = 0; i < administrators.length; i++) {
            if (administrators[i] == _user) {
                admin = true;
                break;
            }
        }
    }
}
