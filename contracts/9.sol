// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// 은행에 입금을 하면 진짜 돈이 빠져나가는 case

contract APP {
    mapping(address=>uint) public balance; // 개인 잔액
    // mapping(address=>mapping(address=>uint)) bankAccounts; // 은행 잔고
    receive() external payable{}

    modifier balanceCheck(address _a, uint _amount) {
        require(balance[_a] >= _amount);
        _;
    }

    /*modifier Fee(uint _amount) {
        require(msg.value == _amount*101/100);
        _;
    }*/

    // 입금 - 해당 App에게 얼만큼의 돈을 입금하겠다.
    function depositToApp() public payable {
        balance[msg.sender] += msg.value;
    }

    // 입금 - 특정 은행에게 얼만큼의 돈을 입금하겠다.
    function depositToBank(address payable _bank, uint _amount) public /*payable Fee(_amount)*/ {
        Bank targetBank = Bank(_bank);
        require(balance[msg.sender] >= _amount);
        payable(targetBank).transfer(_amount);
        balance[msg.sender] -= _amount;
        targetBank.Deposit(msg.sender, _amount);
    }

    function _depositToBank(address payable _bank, address _to, uint _amount) public {
        Bank targetBank = Bank(_bank);
        require(balance[msg.sender] >= _amount);
        payable(targetBank).transfer(_amount);
        balance[msg.sender] -= _amount;
        targetBank.Deposit(_to, _amount);
    }

    // 인출 - 해당 App에게 얼만큼의 돈을 출금하겠다.
    function withdrawFromApp(uint _amount) public balanceCheck(msg.sender, _amount) {
        balance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);        
    }

    // 인출 - 특정 은행에서 얼만큼의 돈을 출금하겠다.
    function withdrawFromBank(address payable _bank, uint _amount) public {
        Bank targetBank = Bank(_bank);
        targetBank.Withdraw(msg.sender, _amount);
        balance[msg.sender] += _amount;
    }

    // 송금 - A가 B에게 돈을 보내는 것(App을 통해서)
    function transferTo(address _bAccount, uint _amount) public balanceCheck(msg.sender, _amount) {
        balance[msg.sender] -= _amount;
        balance[_bAccount] += _amount;
    }

    // 은행송금 - A의 은행에서 B의 은행에게 돈을 보내는 것(은행끼리)
    function transferWire(address payable _aBank, address _bAccount, address payable _bBank, uint _amount) public {
        withdrawFromBank(_aBank, _amount);
        _depositToBank(_bBank, _bAccount, _amount);
    }
}

contract Bank {
    mapping(address=>uint) private balance;
    receive() payable external{}

    //잔고 확인
    function balanceOf() public view returns(uint) {
        return balance[msg.sender];
    }

    /*function balanceOf(address _account) public view returns(uint) {
        require(_account == msg.sender);
        return balance[_account];
    }*/

    // 입금 - 얼만큼의 돈을 입금하겠다.
    function deposit() public payable {
        balance[msg.sender] += msg.value;
    }

    function _deposit(address _account, uint _amount) internal {
        balance[_account] += _amount;
    }

    function Deposit(address _account, uint _amount) public {
        require(_amount != 0, "Amount should not be zero.");
        _deposit(_account, _amount);
    }

    // 인출 - 얼만큼의 돈을 출금하겠다.
    function withdraw(uint _amount) public {
        balance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function _withdraw(address _account, uint _amount) internal {
        balance[_account] -= _amount;
        payable(msg.sender).transfer(_amount); // App한테
    }

    function _withdraw2(address _account, uint _amount) internal {
        balance[_account] -= _amount;
        payable(_account).transfer(_amount); // 개인지갑으로
    }

    function Withdraw(address _account, uint _amount) public {
        require(balance[_account] >= _amount);
        _withdraw(_account, _amount);
    }

    // 송금 - A가 B에게 돈을 보내는 것(동행)
    function transferTo(address _bAccount, uint _amount) public {
        balance[msg.sender] -= _amount;
        balance[_bAccount] += _amount;
    }

    // 타행송금 - A가 B의 다른 은행에게 돈을 보내는 것(타행)
    function transferWire(address _bAccount, address payable anotherBank, uint _amount) public {
        Bank B = Bank(anotherBank);
        balance[msg.sender] -= _amount;
        payable(B).transfer(_amount);
        B.Deposit(_bAccount, _amount);
    }
}