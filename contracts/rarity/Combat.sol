//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/ICodexItemsWeapons.sol";
import "../core/interfaces/IMaterials.sol";
import "../core/interfaces/ICrafting.sol";
import "./Attributes.sol";
import "./Random.sol";
import "./RarityBase.sol";
import "./Weapon.sol";

library Combat {
    function initiative(
        uint256 summonerId,
        int8 bonus,
        int8 dexModifier
    ) public view returns (int8) {
        int8 dMod = Attributes.dexterityModifier(summonerId) + dexModifier;
        uint8 roll = Random.dn(8, 8, 20);
        return int8(roll) + int8(dMod) + bonus;
    }

    function basicFullAttack(
        uint256 summonerId,
        bool hasWeapon,
        uint256 weaponId,
        ICrafting weaponContract,
        uint8 targetAC,
        int8 weaponBonus,
        int8 _strModifier
    )
        public
        view
        returns (
            uint8 attackRoll,
            int8 attackScore,
            uint8 damage,
            uint8 criticalRoll,
            uint8 criticalDamage
        )
    {
        attackRoll = Random.dn(targetAC, 1, 20);
        if (attackRoll == 1) {
            return (1, 0, 0, 0, 0);
        }

        attackScore =
            int8(baseAttack(summonerId)) +
            int8(attackRoll) +
            weaponBonus;
        int8 strModifier = Attributes.strengthModifier(summonerId) +
            _strModifier;
        int8 weaponDamage = strModifier;
        uint256 weaponCritical = 0;

        if (hasWeapon) {
            (, uint256 itemType, , ) = weaponContract.items(weaponId);
            codex_items_weapons.weapon memory _weapon = Weapon.fromCodex(
                itemType
            );
            weaponCritical = _weapon.critical;
            weaponDamage += int8(
                Random.dn(_weapon.damage, 2, uint8(_weapon.damage))
            );
        }
        if (
            attackRoll == 20 ||
            (attackScore > 0 && uint8(attackScore) >= targetAC)
        ) {
            if (weaponDamage < 0) {
                damage = 0;
            } else {
                damage = uint8(weaponDamage);
            }
            if (attackRoll == 20) {
                // Critical?
                criticalRoll = Random.dn(20, 1, 20) + baseAttack(summonerId);
                if (criticalRoll >= targetAC) {
                    for (uint8 i = 0; i < weaponCritical; i++) {
                        weaponDamage =
                            int8(Random.dn(1, i, uint8(weaponDamage))) +
                            strModifier;
                        if (weaponDamage > 0) {
                            criticalDamage += uint8(weaponDamage);
                        }
                    }
                }
            }
        }
    }

    function summonerHp(uint256 summonerId) public view returns (uint8) {
        uint256 _level = RarityBase.level(summonerId);
        uint256 _class = RarityBase.class(summonerId);
        Attributes.Abilities memory abilities = Attributes.abilityScores(
            summonerId
        );
        return
            uint8(
                healthByClassAndLevel(
                    _class,
                    _level,
                    uint32(abilities.constitution)
                )
            );
    }

    function healthByClass(uint256 _class)
        internal
        pure
        returns (uint256 health)
    {
        if (_class == 1) {
            health = 12;
        } else if (_class == 2) {
            health = 6;
        } else if (_class == 3) {
            health = 8;
        } else if (_class == 4) {
            health = 8;
        } else if (_class == 5) {
            health = 10;
        } else if (_class == 6) {
            health = 8;
        } else if (_class == 7) {
            health = 10;
        } else if (_class == 8) {
            health = 8;
        } else if (_class == 9) {
            health = 6;
        } else if (_class == 10) {
            health = 4;
        } else if (_class == 11) {
            health = 4;
        }
    }

    function baseAttack(uint256 summonerId) internal view returns (uint8) {
        uint256 _level = RarityBase.level(summonerId);
        uint256 _class = RarityBase.class(summonerId);
        return uint8(baseAttackBonusByClassAndLevel(_class, _level));
    }

    function healthByClassAndLevel(
        uint256 _class,
        uint256 _level,
        uint32 _const
    ) internal pure returns (uint256 health) {
        int256 _mod = computeModifier(_const);
        int256 _base_health = int256(healthByClass(_class)) + _mod;
        if (_base_health <= 0) {
            _base_health = 1;
        }
        health = uint256(_base_health) * _level;
    }

    function baseAttackBonusByClass(uint256 _class)
        public
        pure
        returns (uint256 attack)
    {
        if (_class == 1) {
            attack = 4;
        } else if (_class == 2) {
            attack = 3;
        } else if (_class == 3) {
            attack = 3;
        } else if (_class == 4) {
            attack = 3;
        } else if (_class == 5) {
            attack = 4;
        } else if (_class == 6) {
            attack = 3;
        } else if (_class == 7) {
            attack = 4;
        } else if (_class == 8) {
            attack = 4;
        } else if (_class == 9) {
            attack = 3;
        } else if (_class == 10) {
            attack = 2;
        } else if (_class == 11) {
            attack = 2;
        }
    }

    function baseAttackBonusByClassAndLevel(uint256 _class, uint256 _level)
        public
        pure
        returns (uint256)
    {
        return (_level * baseAttackBonusByClass(_class)) / 4;
    }

    function computeModifier(uint256 ability) internal pure returns (int256) {
        if (ability < 10) return -1;
        return (int256(ability) - 10) / 2;
    }
}
