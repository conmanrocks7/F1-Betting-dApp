pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract F1Betting is Ownable {

  event NewBet(
    address user,
    uint amount,
    Driver driver
  );

  struct Bet {
    address user;
    uint amount;
    Driver driver;
  }

  struct Driver {
    string surname;
    string forename;
    string team;
    uint id;
  }

  Bet[] public bets;
  address[] public winningBets;
  Driver[] public drivers;
  mapping (address => uint) public numBetsAddress;

  address payable conOwner;
  uint public totalBetMoney;

  bool public paused;
  bool public raceStarted;

  constructor() payable {
    conOwner = payable(msg.sender);
    drivers.push(Driver("Verstappen", "Max", "Redbull Racing", 0));
    drivers.push(Driver("Hamilton", "Lewis", "Mercedes AMG", 1));
    drivers.push(Driver("Bottas", "Valtteri", "Alfa Romeo", 2));
    drivers.push(Driver("Perez", "Sergio", "Redbull Racing", 3));
    drivers.push(Driver("Sainz", "Carlos", "Ferrari", 4));
    drivers.push(Driver("Norris", "Lando", "McLaren", 5));
    drivers.push(Driver("Leclerc", "Charles", "Ferrari", 6));
    drivers.push(Driver("Ricciardo", "Daniel", "McLaren", 7));
    drivers.push(Driver("Gasly", "Pierre", "Alphatauri", 8));
    drivers.push(Driver("Alonso", "Fernando", "Alpine", 9));
    drivers.push(Driver("Ocon", "Esteban", "Alpine", 10));
    drivers.push(Driver("Vettel", "Sebastian", "Aston Martin", 11));
    drivers.push(Driver("Stroll", "Lance", "Aston Martin", 12));
    drivers.push(Driver("Tsunoda", "Yuki", "Alphatauri", 13));
    drivers.push(Driver("Russell", "George", "Mercedes", 14));
    drivers.push(Driver("Latifi", "Nicholas", "Williams", 15));
    drivers.push(Driver("Schumacher", "Mick", "Haas", 16));
    drivers.push(Driver("Zhou", "Guanyu", "Alfa Romeo", 17));
    drivers.push(Driver("Magnussen", "Kevin", "Haas", 18));
    drivers.push(Driver("Albon", "Alex", "Williams", 19));
  }

  function createBet(
    uint _driverID
  ) external payable {
    require(msg.value >= 0.05 ether, "Bet amount must be greater than 0.05 ether.");
    require(!checkForExistingBet(), "You cannot place more than 1 bet.");

    require(!paused, "Betting has been momentarily paused. Please try again later.");
    require(!raceStarted, "You cannot place a bet after the race has started.");

    // Create Bet
    bets.push(Bet(msg.sender, msg.value, drivers[_driverID]));

    numBetsAddress[msg.sender]++;

    (bool sent, bytes memory data) = conOwner.call{ value: msg.value }("");
    require(sent, "Could not place bet. Failed to send Ether.");

    totalBetMoney += msg.value;

    emit NewBet(msg.sender, msg.value, drivers[_driverID]);

  }

  function declareWinner(
    uint _driverID
  ) public payable onlyOwner {

    require(raceStarted, "Race has not been started yet; a winner cannot be declared.");
    require(!paused, "Betting has currently been paused.");

    // Find winning bets and push to winningBets array
    for (uint i = 0; i < bets.length; i++) {
      if (bets[i].driver.id == _driverID) {
        winningBets.push(bets[i].user);
      }
    }

    // Calculate winning split
    uint winnersAmount = totalBetMoney / winningBets.length;

    // Pay each address in winningBets array
    for (uint i = 0; i < winningBets.length; i++) {
      address payable receiver = payable(winningBets[i]);

      (bool sent, bytes memory data) = receiver.call{ value: winnersAmount }("");
      require(sent, "Could not pay winners. Failed to transfer ether.");
    }

    // Reset variables
    totalBetMoney = 0;
    delete winningBets;
    for (uint i = 0; i < bets.length; i++) {
      numBetsAddress[bets[i].user] = 0;
    }
    delete bets;
    raceStarted = false;
  }

  function checkForExistingBet() public view returns(bool) {
    if (numBetsAddress[msg.sender] == 0) {
        return false;
    } else {
        return true;
    }
  }

  function pause() public onlyOwner {
    paused = true;
  }

  function unpause() public onlyOwner {
    paused = false;
  }

  function raceStart() public onlyOwner {
    raceStarted = true;
  }

}
