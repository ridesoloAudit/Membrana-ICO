pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

import './Token.sol';

contract Presale {
    using SafeMath for uint256;

    // ERC20 basic token contract being held
    Token private token_;

    // Contract operator address
    address private operator_;
    // Contract treasure
    address private treasure_;
    // Maximum token supply which could be created via Presale process
    uint256 public maxSupply;
    // Timestamp when token release is enabled
    uint256 private releaseTime_;
    // Time when bonus lock is disabled
    uint256 private unlockTime_;
    // Received ethers
    mapping(address => uint256) private balances_;

    constructor(
      address _operator,
      address _treasure,
      uint256 _releaseTime,
      uint256 _unlockTime,
      uint256 _maxSupply
    )
      public
    {
      require(_operator != address(0));
      require(_treasure != address(0));
      require(_releaseTime > block.timestamp);
      require(_unlockTime > _releaseTime);
      require(_maxSupply > 0);

      operator_ = _operator;
      treasure_ = _treasure;
      releaseTime_ = _releaseTime;
      unlockTime_ = _unlockTime;
      maxSupply = _maxSupply;
    }

    // Events
    event Bonus(address receiver, address lock, uint256 amount);
    event Transfer(address receiver, uint256 amount);
    event Chargeback(address receiver, uint256 amount);

    // Modifiers
    modifier operatorOnly() {
      require(msg.sender == operator_);
      _;
    }

    // Methods

    // Increase balance from ICO Cab address. _receiver is address defined in
    // the cab as token's beneficiary.
    function increaseBalance(address _receiver)
      public
      payable
    {
      require(_receiver != address(0));
      balances_[_receiver].add(msg.value);
    }

    function transfer(address _receiver, uint256 _tokens, uint256 _bonus)
      public
      operatorOnly
    {
      require(_receiver != address(0));
      require(balances_[_receiver] > 0);
      require(token_.totalSupply().add(_tokens).add(_bonus) < maxSupply);

      token_.mint(_receiver, _tokens);

      // Send locked bonuses to timelock contract
      if (_bonus > 0) {
        TokenTimelock lock = new TokenTimelock(token_, _receiver, unlockTime_);
        token_.mint(lock, _bonus);
        emit Bonus(_receiver, lock, _bonus);
      }

      uint256 amount = balances_[_receiver];
      balances_[_receiver] = 0;
      treasure_.transfer(amount);

      emit Transfer(_receiver, amount);
    }

    // Chargeback money.
    function chargeback(address _receiver)
      public
      operatorOnly
    {
      uint256 amount = balances_[_receiver];
      balances_[_receiver] = 0;
      _receiver.transfer(amount);

      emit Chargeback(_receiver, amount);
    }

    function setOperator(address _operator)
      public
      operatorOnly
    {
      require(_operator != address(0));

      operator_ = _operator;
    }

    function setToken(Token _token)
      public
    {
      require(token_ == address(0));
      token_ = _token;
    }

    // Anyone could call release method if the release date is arrived.
    function release()
    public
    {
      require(releaseTime_ > block.timestamp);

      token_.setReleased();
    }
}
