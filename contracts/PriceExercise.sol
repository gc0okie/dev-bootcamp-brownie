// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

contract PriceContract is ChainlinkClient{

    AggregatorV3Interface internal priceFeed;
    
    bool public priceFeedGreater;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    int256 private price_api;

    /* It’s constructor function should contain a combination of the existing PriceConsumerV3 and the APIConsumer contract contract logic, including taking in the _priceFeed address parameter like the PriceConsumerV3 contract does, as well as all the parameters in the existing APIConsumer contract (hint: append the price consumer parameter to the end of the 4 API consumer ones)
    */
    constructor(address _oracle, string memory _jobId, uint256 _fee, address _link, address AggregatorAddress) public {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        // oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
        // jobId = "29fa9aa13bf1468788b7cc4a500a45b8";
        // fee = 0.1 * 10 ** 18; // 0.1 LINK
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = _fee;
        priceFeed = AggregatorV3Interface(AggregatorAddress);
    }

    /* The ‘requestPriceData’ function should request the BTC price from the URL https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC&tsyms=USD, remembering to set the ‘path’ to the current price returned in the JSON, and multiplying the result by 10**18 before sending the request to a Chainlink oracle
    */
    function requestPriceData() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC&tsyms=USD");
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"BTC":
        //    {"USD":
        //     {
        //      "PRICE": xxxxx.xx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "RAW.BTC.USD.PRICE");

        // Multiply the result by 100000000 to remove decimals
        int timesAmount = 10**8;
        request.addInt("times", timesAmount);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /* The ‘fulfill’ function signature should take in 2 parameters, a bytes32 type field called _requestId, and an int256 (not uint256) called _price. 
The ‘fulfill’ function should compare the returned value from cryptocompare to the current price of the BTC/USD price feed using an if/else statement (hint: syntax for if/else can be seen in the APIConsumer constructor). The price feed current price can be accessed by calling the getLatestPrice() function in your contract
The fulfill function should set the value of the variabel ‘priceFeedGreater’ to  true (syntax: priceFeedGreater = true;) if the price feed result is greater than (>) then the cryptocompare result, else it should set the variable to false (syntax: priceFeedGreater = false;)
*/
    function fulfill(bytes32 _requestId, int256 _price) public recordChainlinkFulfillment(_requestId){
        price_api = _price;
        if ( getLatestPrice() > _price) {
            priceFeedGreater = true;
        } else {
            priceFeedGreater = false;
        }
    }

    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
/*
    function priceFeedGreater() public view returns (bool) {
        return priceFeedGreater;
    }*/

    // copied from APIConsumer.sol
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}