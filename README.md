# Rarity Masterwork
> ..masterwork item: a weapon, suit of armor, shield, or tool that conveys a bonus on its use through its exceptional craftsmanship.

- https://www.d20srd.org/srd/skills/craft.htm
- https://www.d20srd.org/srd/monsters/kobold.htm


## tasks
- [x] crafting
  - [x] events
  - [ ] tokenUri
  - [ ] codex

- [ ] mats
  - [ ] fight kobolds until you can't stand

- [ ] review crafting feats

## review
```
(, int check) = commonCrafting.craft_skillcheck(project.crafter, MASTERWORK_COMPONENT_DC);
project.check = project.check + uint(check);
```


## Crafting Masterwork Items (Rarity)
- Craft masterwork items using craft checks and XP
- Farm extra mats from Kobold Cave to speed up the process


## Masterwork crafting mechanic



### Wtf is a masterwork component?
The d20 "masterwork component" is a proxy for whatever it is that differentiates a common item from its masterwork counterpart. For a sword, that could mean strong metals and fine woods.


## Creating Masterwork Items (d20)
> You can make a masterwork item—a weapon, suit of armor, shield, or tool that conveys a bonus on its use through its exceptional craftsmanship, not through being magical. To create a masterwork item, you create the masterwork component as if it were a separate item in addition to the standard item. The masterwork component has its own price (300 gp for a weapon or 150 gp for a suit of armor or a shield) and a Craft DC of 20. Once both the standard component and the masterwork component are completed, the masterwork item is finished. Note: The cost you pay for the masterwork component is one-third of the given amount, just as it is for the cost in raw materials.


### hardhat
```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.ts
TS_NODE_FILES=true npx ts-node scripts/deploy.ts
npx eslint '**/*.{js,ts}'
npx eslint '**/*.{js,ts}' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```
