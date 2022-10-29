//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICapazEscrowFactory} from "./interfaces/ICapazEscrowFactory.sol";
import {CapazCommon} from "./CapazCommon.sol";

/**
 * @title CapazEscrow
 * @author Capaz Team @ ETHLisbon Hackathon
 */
contract CapazEscrow is Ownable, CapazCommon {
    ICapazEscrowFactory escrowFactory;
    uint256 tokenId;
    uint256 claimedAmount;
    bool isYieldClaimed;

    /**
     * Function called when the contract instance is cloned
     * @param _tokenId The tokenId to setup
     */
    function setup(uint256 _tokenId) public onlyOwner {
        tokenId = _tokenId;
        escrowFactory = ICapazEscrowFactory(owner());
        Escrow memory escrow = getEscrow();

        //!TODO Handle strategies mapping and handle adding a new one
        //!TODO deposit funds into strategy
        address token = escrow.tokenAddress;

        emit SetUp(escrow.sender, escrow.receiver, escrow);
    }

    /**
     * Get the total amount of token that the receiver can claimed
     */
    function releasableAmount() public view returns (uint256) {
        Escrow memory escrow = getEscrow();
        uint256 periods = escrow.periods;
        uint256 periodsPassed = Math.min(
            (block.timestamp - escrow.startTime) / escrow.periodDuration,
            periods
        );
        uint256 releasable = (periodsPassed * escrow.totalAmount) / periods;
        return releasable;
    }

    /**
     * Let the receiver release the avaiable funds
     */
    function release() public returns (uint256) {
        Escrow memory escrow = getEscrow();
        address receiver = escrow.receiver;
        uint256 amount = releasableAmount();
        require(amount > 0, "You don't have any funds to release");
        IERC20(escrow.tokenAddress).transfer(receiver, amount);
        claimedAmount += amount;

        emit Released(receiver, amount);
        return amount;
    }

    /**
     * Let the sender get is yield and choose how he want to distribute them
     */
    function distributeYield(address user1, address user2) public onlySender {
        // claim yield and distribute
        Escrow memory escrow = getEscrow();
        require(
            block.timestamp >= escrowEndTimestamp(escrow),
            "CapazEscrow: Escrow has not ended yet"
        );
        require(!isYieldClaimed, "CapazEscrow: Yield already claimed");

        //!TODO first release the remaining funds

        //!TODO claim yield and distribute
        if (user1 == user2) {
            // send all to same user
        } else {
            // send half to each user
        }
        uint256 amount;
        emit YieldDistributed(user1, user2, amount);
    }

    /**
     * Get the escrow configuration linked to this instance
     */
    function getEscrow() public view returns (Escrow memory) {
        return escrowFactory.getEscrow(tokenId);
    }

    /**
     * Get the total duration of the escrow
     */
    function escrowLenght(Escrow memory _escrow) public pure returns (uint256) {
        return _escrow.periods * _escrow.periodDuration;
    }

    /**
     * Get the timestamt of the last period
     */
    function escrowEndTimestamp(Escrow memory _escrow)
        public
        pure
        returns (uint256)
    {
        return _escrow.startTime + escrowLenght(_escrow);
    }

    /**
     * Checker to ensure that the caller is the sender of the escrow
     */
    modifier onlySender() {
        require(
            msg.sender == escrowFactory.getEscrow(tokenId).sender,
            "CapazEscrow: Only sender can call this function"
        );
        _;
    }

    /**
     * Emit when the contract is created
     * @param sender Address of the sender of the escrow
     * @param receiver Address of the receiver of the escrow
     * @param escrow the complete escrow configuration
     */
    event SetUp(
        address indexed sender,
        address indexed receiver,
        Escrow escrow
    );

    /**
     * Emit when funds are released to the receiver
     * @param receiver Address of the receiver of the escrow
     * @param amount total token released
     */
    event Released(address receiver, uint256 amount);

    /**
     * Emit when yields are distributed
     * @param user1 Address of first user to share the yield
     * @param user2 Address of second user to share the yield
     */
    event YieldDistributed(address user1, address user2, uint256 amount);
}
