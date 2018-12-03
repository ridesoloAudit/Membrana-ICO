pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract Treasure {
  using SafeMath for uint256;

  mapping(address => bool) status_;
  address[] private participants_;
  uint256 public quorum;
  bool private isFinalized_;

  mapping(address => uint256) private amounts_;
  mapping(address => uint256) private votes_;
  mapping(address => mapping(address => bool)) private votesStatus_;

  constructor(uint256 _quorum)
    public
  {
    require(_quorum > 0);

    quorum = _quorum;
  }

  function () external payable {
    require(msg.data.length == 0); // No external calls
  }

  // Events

  // Modifiers
  modifier partyOnly() {
    require(status_[msg.sender] == true);
    _;
  }

  modifier notFinalizedOnly() {
    require(isFinalized_ == false);
    _;
  }

  // Methods
  function addParty(address _party)
    public
    notFinalizedOnly
  {
    require(_party != address(0));
    require(status_[_party] == false);

    status_[_party] = true;
    participants_.push(_party);
  }

  function initTransfer(address _to, uint256 _amount)
    public
    partyOnly
  {
    require(_to != address(0));
    require(amounts_[_to] == 0);
    require(_amount > 0);

    amounts_[_to] = _amount;
    votesStatus_[_to][msg.sender] = true;
    votes_[_to] = 1;
  }

  function voteUp(address _to, uint256 _amount)
    public
    partyOnly
  {
    require(amounts_[_to] > 0);
    require(votesStatus_[_to][msg.sender] == false);
    require(amounts_[_to] == _amount);

    votes_[_to].add(1);

    if (votes_[_to] == quorum) {
      processTransfer(_to);
    }
    else {
      votesStatus_[_to][msg.sender] = true;
    }
  }

  function voteDown(address _to, uint256 _amount)
    public
  {
    require(amounts_[_to] > 0);
    require(votesStatus_[_to][msg.sender] == true);
    require(amounts_[_to] == _amount);

    votes_[_to].sub(1);
    votesStatus_[_to][msg.sender] = false;

    if (votes_[_to] == 0) {
      amounts_[_to] = 0;
    }
  }

  function processTransfer(address _to)
    internal
  {
    uint256 amount = amounts_[_to];

    amounts_[_to] = 0;
    votes_[_to] = 0;

    for (uint256 i = 0; i < participants_.length; i++) {
      votesStatus_[_to][participants_[i]] == false;
    }

    _to.transfer(amount);
  }

  function finalize()
    public
  {
    isFinalized_ = true;
  }
}
