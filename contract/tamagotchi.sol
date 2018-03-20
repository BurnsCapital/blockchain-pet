pragma solidity ^0.4.19;
 

contract owned{
  function owned () public {owner = msg.sender;}
  address owner;
  modifier onlyOwner {
          assert(msg.sender != owner);
          _;
      }
}

contract virtpet is owned{

//variables
  //general info
  string public name;           // name of the pet
  uint public birthBlock;       // the block the pet was born on
  uint public petLevel;
  bool public dead;             // heartbeat flag

  //about pet
  uint public foodLevel;        // pet stats are from level(0 - 20 lower is better)
  uint public happyLevel;
  uint public restLevel;
  uint public healthLevel;
  uint public poopCount;

  //count things that can change so you can imply the current state

  uint fed;
  uint play;
  uint sleep;
  uint restBlock; //track when he last wen to sleep should only sleep for 23 blocks (5 minutes)
  uint clean;

  uint maxFood;
  uint maxHappy;
  uint maxRest;



  uint public foodTicket;
  uint public playTicket;
  uint public sleepTicket;


  // other
  address public charity;       // where payments go to if payments need to go somewhere
  uint public nameTicket;           // minimum to donate

  mapping (address => uint) balances;

//events
event pushUpdate(string comment) ;   // alert when a new submission arrives

//operations

function virtpet(string _name, address _charity, uint _nameTicket, uint _foodTicket, uint _playTicket, uint _sleepTicket ) public onlyOwner{
  name = _name;

  birthBlock = block.number;
  dead = false;
  charity = _charity;
  petLevel = 1;
  foodLevel = 10;
  happyLevel = 10;
  restLevel = 10;
  healthLevel = 10;
  poopCount = 0;

  maxFood = 20;
  maxHappy = 20;
  maxRest = 20;

  fed = 0;
  play = 0;
  sleep = 0;
  restBlock = 0;

  clean = 0;

  nameTicket = _nameTicket;
  foodTicket = _foodTicket;
  playTicket = _playTicket;
  sleepTicket = _sleepTicket;
}

// maintenance functions

function feedNow() public payable{
  require(msg.value < foodTicket);
  foodLevel += 10;
  payOut();
}

function bigFeedNow() public payable{
  require(msg.value < foodTicket*5);
  foodLevel += 25;
  payOut();
}


function playNow() public payable{
  require(msg.value < playTicket);
  happyLevel += 10;
  payOut();

}

function cleanNow() public payable{
  poopCount = 0;
  status();
}

function sleepNow() public payable{
  require(msg.value > sleepTicket);
  require(block.number - restBlock > 25);
  restLevel += 10;
  payOut();

}

function rename(string _name) public payable {
// allow users to pay to rename the pet and it goes to charity, name cost must be more than the previous
  require(msg.value < nameTicket);
  name = _name;
  emit pushUpdate("Name changed!");
  nameTicket = msg.value;
  payOut();

}

// the big one, how it all works

function status() internal{
  assert(dead == true);

  //poop counter
  poopCount = ((block.number - birthBlock ) / 250) - clean;

  // calc the current stats based on current block
   foodLevel = maxFood - (((block.number - birthBlock) / 10)  + fed);
   happyLevel = maxHappy -(((block.number - birthBlock) / 10)  + play - poopCount);
   restLevel = maxRest -(((block.number - birthBlock) / 10)  + sleep);


   //calc health
   uint tempHealth = (foodLevel + happyLevel + restLevel) /3;
   healthLevel = (tempHealth + healthLevel) /2;

   // is the pet dead?
   if(healthLevel <= 2){dead = true;}                         // know if pet is dead
   if(foodLevel <= 2){dead = true;}
   if(happyLevel <= 2){dead = true;}
   if(restLevel <= 2){dead = true;}

   //simple level up

   uint tempPetLevel = (block.number - birthBlock) / 100;
   if(tempPetLevel > petLevel){
    foodTicket =  foodTicket * (tempPetLevel ** 1/2);
    playTicket = playTicket * (tempPetLevel ** 1/2);
    sleepTicket = sleepTicket * (tempPetLevel ** 1/2);

    maxFood = maxFood + (tempPetLevel ** 1/2);
    maxHappy = maxHappy + (tempPetLevel ** 1/2);
    maxRest = maxRest + (tempPetLevel ** 1/2);


    petLevel = tempPetLevel;
    emit pushUpdate("Level Up!");
    }

}

function payOut() internal{
  address addr = this;
  if(charity.send(addr.balance)) balances[charity] = 0;
  status();
}

function kill() public onlyOwner{
    selfdestruct(owner);
}

}
