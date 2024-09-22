// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingRewards {
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public rewardBalance;
    mapping(address => uint256) public stakingStartTime;

    uint256 public constant MIN_REWARD_RATE = 1;  // 1%
    uint256 public constant MAX_REWARD_RATE = 7;  // 7%

    constructor(IERC20 _stakingToken, IERC20 _rewardToken) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
    }

    function stake(uint256 _amount) public {
        require(_amount > 0, "El monto debe ser mayor que cero");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakingBalance[msg.sender] += _amount;
        if (stakingStartTime[msg.sender] == 0) {
            stakingStartTime[msg.sender] = block.timestamp;
        }
    }

    function withdraw(uint256 _amount) public {
        require(stakingBalance[msg.sender] >= _amount, "Saldo insuficiente");
        claimRewards();
        stakingBalance[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        if (stakingBalance[msg.sender] == 0) {
            stakingStartTime[msg.sender] = 0;
        }
    }

    function claimRewards() public {
        uint256 reward = calculateRewards(msg.sender);
        rewardBalance[msg.sender] = 0; // Reiniciar el saldo de recompensas
        rewardToken.transfer(msg.sender, reward); // Pagar las recompensas
    }

    function calculateRewards(address _user) internal view returns (uint256) {
        uint256 rewardRate = getRewardRate(_user);
        return (stakingBalance[_user] * rewardRate) / 100;
    }

    function getRewardRate(address _user) internal view returns (uint256) {
        uint256 stakingDuration = block.timestamp - stakingStartTime[_user];
        uint256 daysStaked = stakingDuration / 1 days;

        if (daysStaked <= 30) {
            return 1;
        } else if (daysStaked <= 60) {
            return 3;
        } else if (daysStaked <= 90) {
            return 5;
        } else {
            return 7;
        }
    }
}
