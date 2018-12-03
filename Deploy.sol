pragma solidity ^0.4.24;

import './Presale.sol';
import './Token.sol';
import './Treasure.sol';

contract Deploy {
  address public treasure;
  address public presale;
  address public token;

  constructor()
    public
  {
    Treasure treasure_ = new Treasure(2);
    treasure_.addParty(address(0x0000000000000000000000000000000000000001));
    treasure_.addParty(address(0x0000000000000000000000000000000000000002));
    treasure_.addParty(address(0x0000000000000000000000000000000000000003));
    treasure_.finalize();
    treasure = treasure_;

    presale = new Presale(
      address(0x0000000000000000000000000000000000000001),
      address(treasure),
      1556658000000, // 2019-05-01T00:00:00
      1559336400000, // 2019-06-01T00:00:00
      1000000000
    );

    token = new Token(presale);
  }
}
