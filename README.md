<a href="https://twitter.com/lootrealms">
<img src="https://img.shields.io/twitter/follow/lootrealms?style=social"/>
</a>
<a href="https://twitter.com/BibliothecaDAO">
<img src="https://img.shields.io/twitter/follow/BibliothecaDAO?style=social"/>
</a>


[![discord](https://img.shields.io/badge/join-bibliothecadao-black?logo=discord&logoColor=white)](https://discord.gg/bibliothecadao)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

![background](.github/bg.png)


## 🪦 Loot Survivor

> Go and die with glory

Play [Loot Survivor](https://loot-survivor.vercel.app/)

Table of contents

- [Game Design](#🕹️-game-design)
- [Technology](#⛓️-technology)
- [Contributing](#🏗️-contributing)

---

## 🕹️ Game Design

Loot Survivor is a onchain Arcade machine game. You add some tokens, try get the highscore and live for eternity onchain.

Each play through will be different and there is no end to the game. Every level just gets progressively harder.

<details>

<summary>Game Statistics</summary>
Each level up grants adventurers 1+ upgrade to help them survive their explorations. Although Luck cannot be upgraded directly, it can be increased by equipping jewelry items:

- Strength: Boosts attack damage by 10%.
- Vitality: Increases health by +20ph and max health.
- Dexterity: Improves chances of successfully fleeing.
- Wisdom: Helps evade Beast ambushes.
- Intelligence: Aids in avoiding Obstacles.
- Luck: Raises chances of critical damage (cannot be upgraded directly).
</details>

<details>

<summary>Combat Logic</summary>

There are three categories of weapons and armor materials:

**Weapons**: Blade, Bludgeon, Magic

**Armor materials**: Cloth, Hide, Metal 

**Weapon vs. Armor Efficacy Chart**

| Weapon Type | Metal | Hide | Cloth |
|-------------|-------|------|-------|
| Blade       | Weak  | Fair | Strong|
| Bludgeon    | Fair  | Strong| Weak|
| Magic       | Strong | Weak | Fair |


</details>

<details>
<summary>Weapons and Materials</summary>

## Weapons

The items are based off the OG loot contract

- Weapon
- Head
- Chest
- Hands
- Waist
- Feet
- Neck 
- Ring

**Weapon Types and Ranks**

| Weapon Type | Item Name     | Rank |
|-------------|---------------|------|
| Blade       | Katana        | 1    |
| Blade       | Falchion      | 2    |
| Blade       | Scimitar      | 3    |
| Blade       | Long Sword    | 4    |
| Blade       | Short Sword   | 5    |
| Bludgeon    | Warhammer     | 1    |
| Bludgeon    | Quarterstaff  | 2    |
| Bludgeon    | Maul          | 3    |
| Bludgeon    | Mace          | 4    |
| Bludgeon    | Club          | 5    |
| Magic       | Ghost Wand    | 1    |
| Magic       | Grave Wand    | 2    |
| Magic       | Bone Wand     | 3    |
| Magic       | Wand          | 4    |
| Magic       | Grimoire      | 1    |
| Magic       | Chronicle     | 2    |
| Magic       | Tome          | 3    |
| Magic       | Book          | 4    |

## Encounters

- Beasts 
- Obstacles 

</details>

---

## 🏗️ Contributing

The game is a work in progress and contributions are greatly appreciated.

---

## ⛓️ Technology


Loot Survivor is a onchain game, designed to be immutable and permanently hosted on Starknet. We use advanced gas optimization to reduce costs on Starknet. A players gamestate exists primarily in a single felt252, every action the player takes only updates a single storage slot.


- Client: Nextjs
- Indexer: Apibara
- Contracts: Cairo 1.0



0x059dac5df32cbce17b081399e97d90be5fba726f97f00638f838613d088e5a47

### Deploying

#### Set up env
https://docs.starknet.io/documentation/getting_started/environment_setup/



```
export STARKNET_NETWORK=alpha-goerli
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
export CAIRO_COMPILER_DIR=~/.cairo/target/release/
export CAIRO_COMPILER_ARGS=--add-pythonic-hints
export ACCOUNT_NAME = INSERT_YOUR_ACCOUNT_NAME_HERE

scarb build

starknet declare --contract /home/os/Documents/code/bibliotheca/loot-survivor/contracts/game/target/dev/game_Game.sierra.json --account $ACCOUNT_NAME

starknet deploy --class_hash 0x2592ba7e082159424d860bf65694d0181afe5e53a7f546aa596335489fb5126 --max_fee 100000000000000000 --input 0x059dac5df32cbce17b081399e97d90be5fba726f97f00638f838613d088e5a47 0x020b96923a9e60f63a1829d440a03cf680768cadbc8fe737f71380258817d85b --account $ACCOUNT_NAME
```

export CONTRACT_ADDRESS=INSERT_ADDRESS_OF_NEWLY_DEPLOYED_CONTRACT_HERE

#### Start
starknet invoke --function start --address $CONTRACT_ADDRESS --input 12 123 0 0 0 0 --max_fee 10000000000000000 --account $ACCOUNT_NAME


#### Explore
starknet invoke --function explore --address $CONTRACT_ADDRESS --input 0 0 --max_fee 10000000000000000 --account $ACCOUNT_NAME

#### Attack
starknet invoke --function attack --address $CONTRACT_ADDRESS --input 0 0 --max_fee 10000000000000000 --account $ACCOUNT_NAME

#### Call
starknet call --function get_adventurer --address $CONTRACT_ADDRESS --input 0 0 --account $ACCOUNT_NAME
