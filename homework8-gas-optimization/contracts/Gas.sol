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
        bool adminUpdated;
        address recipient;
        address admin; // administrators address
        bytes8 recipientName; // max 8 characters
        uint256 paymentId;
        uint256 amount;
    }

    uint256 public immutable totalSupply; // cannot be updated
    address public immutable contractOwner;
    address[5] public administrators;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => Payment[]) public payments;

    event Transfer(address recipient, uint256 amount);

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

    constructor(address[5] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        administrators = _admins;
        balances[msg.sender] = totalSupply = _totalSupply;
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public {
        uint256 balanceSender = balances[msg.sender];
        require(balanceSender >= _amount, "insufficient Balance");
        bytes calldata bytesName = bytes(_name);
        require(bytesName.length < 9, "invalid name");

        uint256 balanceRecipient = balances[_recipient];
        balances[msg.sender] = balanceSender - _amount;
        balances[_recipient] = balanceRecipient + _amount;

        uint256 paymentsLength = payments[msg.sender].length;
        payments[msg.sender].push(
            Payment({
                paymentType: PaymentType.BasicPayment,
                recipient: _recipient,
                amount: _amount,
                recipientName: bytes8(bytesName),
                paymentId: paymentsLength + 1,
                adminUpdated: false,
                admin: address(0)
            })
        );

        emit Transfer(_recipient, _amount);
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

        Payment storage payment = payments[_user][_id - 1];

        payment.adminUpdated = true;
        payment.admin = _user;
        payment.paymentType = _type;
        payment.amount = _amount;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        require(_tier < 4 && _tier > 0, "invalid tier");
        whitelist[_userAddrs] = _tier;
    }

    function whiteTransfer(address _recipient, uint256 _amount)
        public
        onlyWhiteListed
    {
        uint256 balanceSender = balances[msg.sender];
        require(balanceSender >= _amount, "insufficient balance");
        require(_amount > 3, "amount too low");
        uint256 balanceRecipient = balances[_recipient];
        uint256 tierSender = whitelist[msg.sender];
        balances[msg.sender] = balanceSender - _amount + tierSender;
        balances[_recipient] = balanceRecipient + _amount - tierSender;
    }

    function balanceOf(address _user) public view returns (uint256 balance) {
        balance = balances[_user];
    }

    function getPayments(address _user)
        public
        view
        returns (Payment[] memory userPayments)
    {
        userPayments = payments[_user];
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
