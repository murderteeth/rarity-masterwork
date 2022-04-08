//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IEffects {
  function attack_bonus(uint token) external view returns (int8);
  function skill_bonus(uint token, uint8 skill) external view returns (int8);  
}