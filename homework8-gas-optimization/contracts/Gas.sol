// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

error NotOwnerOrAdmin();
error NotWhitelisted();
error InsufficientBalance();
error InvalidParams();

contract GasContract {
    enum PaymentType {
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    struct Payment {
        PaymentType paymentType;
        bool adminUpdated;
        address admin; // administrators address
        address recipient;
        bytes8 recipientName; // max 8 characters
        uint256 paymentId;
        uint256 amount;
    }

    uint256 public immutable totalSupply; // cannot be updated
    address public immutable contractOwner;
    address[5] public administrators;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) private balances;
    mapping(address => Payment[]) private payments;

    event Transfer(address recipient, uint256 amount);

    constructor(address[5] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        administrators = _admins;
        balances[msg.sender] = totalSupply = _totalSupply;
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) external {
        bytes calldata bytesName = bytes(_name);
        uint256 balanceSender = balances[msg.sender];
        uint256 balanceRecipient = balances[_recipient];
        if (bytesName.length > 8) revert InvalidParams();
        if (balanceSender < _amount) revert InsufficientBalance();

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
    ) external {
        _onlyAdminOrOwner();
        if (_id == 0 || _amount == 0 || _user == address(0))
            revert InvalidParams();

        Payment storage payment = payments[_user][_id - 1];

        assembly {
            sstore(payment.slot, add(shl(16, _user), add(0x0100, _type)))
            sstore(add(payment.slot, 3), _amount)
        }
    }

    function addToWhitelist_0n2(address _user, uint256 _tier) external {
        _onlyAdminOrOwner();
        if (_tier == 0 || _tier > 4) revert InvalidParams();
        whitelist[_user] = _tier;
    }

    function whiteTransfer(address _recipient, uint256 _amount) external {
        uint256 balanceSender = balances[msg.sender];
        uint256 balanceRecipient = balances[_recipient];
        uint256 tierSender = whitelist[msg.sender];
        if (_amount < 4) revert InvalidParams();
        if (balanceSender < _amount) revert InsufficientBalance();
        if (tierSender == 0) revert NotWhitelisted();
        balances[msg.sender] = balanceSender - _amount + tierSender;
        balances[_recipient] = balanceRecipient + _amount - tierSender;
    }

    function balanceOf(address _user) external view returns (uint256 balance) {
        balance = balances[_user];
    }

    function getPayments(address _user)
        external
        view
        returns (Payment[] memory userPayments)
    {
        userPayments = payments[_user];
    }

    function getTradingMode() external pure returns (bool mode) {
        mode = true;
    }

    function _onlyAdminOrOwner() internal view {
        if (contractOwner == msg.sender) return;
        for (uint256 i = 0; i < administrators.length; ) {
            unchecked {
                ++i;
            }
            if (administrators[i] == msg.sender) {
                return;
            }
        }
        revert NotOwnerOrAdmin();
    }
}
