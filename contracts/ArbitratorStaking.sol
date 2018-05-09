pragma solidity ^0.4.23;

import "./SafeMath.sol";
import "./Ownership/Ownable.sol";

// ERC900 compliant staking interface supporting ETH stakes.
// Code is based off of: https://github.com/HarbourProject/stakebank

contract ArbitratorStaking is Ownable {

    using SafeMath for uint256;

    uint private staked;

    mapping (address => uint) public stakes;

    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    /// @notice Stakes a certain amount of tokens.
    /// @param data Data field used for signalling in more complex staking applications.
    function stake(uint256, bytes data) public payable {
        stakeFor(msg.sender, 0, data);
    }

    /// @notice Stakes a certain amount of tokens for another user.
    /// @param user Address of the user to stake for.
    /// @param data Data field used for signalling in more complex staking applications.
    function stakeFor(address user, uint256, bytes data) public payable {
        uint amount = msg.value;

        stakes[user] = stakes[user].add(amount);
        staked = staked.add(amount);

        emit Staked(user, amount, totalStakedFor(user), data);
    }

    /// @notice Unstakes a certain amount of tokens.
    /// @param amount Amount of tokens to unstake.
    /// @param data Data field used for signalling in more complex staking applications.
    function unstake(uint256 amount, bytes data) public {
        require(totalStakedFor(msg.sender) >= amount);

        // @todo ensure arbitrator is allowed to unstake, depending on mechanism arbitrators must wait until all
        // appeal times have run out for any disputes they have recently arbitrated.

        stakes[msg.sender] = stakes[msg.sender].sub(amount);
        staked = staked.sub(amount);
        msg.sender.transfer(amount);

        emit Unstaked(msg.sender, amount, totalStakedFor(msg.sender), data);
    }

    function withdrawOverflow() public onlyOwner {
        require(address(this).balance > staked);
        msg.sender.transfer(address(this).balance.sub(staked));
    }

    /// @notice Returns total tokens staked for address.
    /// @param addr Address to check.
    /// @return amount of tokens staked.
    function totalStakedFor(address addr) public view returns (uint256) {
        return stakes[addr];
    }

    /// @notice Returns total tokens staked.
    /// @return amount of tokens staked.
    function totalStaked() public view returns (uint256) {
        return staked;
    }

    /// @notice Returns if history related functions are implemented.
    /// @return Bool whether history is implemented.
    function supportsHistory() public pure returns (bool) {
        return false; // currently no need, may be required later
    }
}
