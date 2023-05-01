# Loot Survivor Game

This repository includes both the client and indexer that form the game Loot Survivor.

## Setup

Currently we are running the app locally until we fix an issue with running devnet over https.

### If you don't have yarn installed

Install nodejs https://nodejs.org/en/download/. 

Install yarn:

```
npm install --global yarn
```

If permissions error `sudo npm install --global yarn`

### Start app

Clone repo:

```
git clone https://github.com/BibliothecaDAO/loot-survivor.git
```

Set up server:

```
cd loot-survivor/ui
yarn
yarn dev
```

You will find the app at http://localhost:3000/.

Setting up devnet:

- Select "Launch on Devnet"
- Select "Connect ArgentX"
- Select "Add Devnet" (confirm in Argent)
- Select "Switch to Devnet" (confirm in Argent)
- Open Argent and create an account. You will be given 1 ETH as a starting balance. (May take a few seconds to create)

To see your ETH balance add token address `0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7`

If you get a `Class with hash 0x3343...` error follow below to resolve:

- Go to ArgentX wallet 
- Select Settings cog icon
- Select Developer settings
- Select Manage networks
- Select Loot Survivor Devnet
- Select Advanced settings 
- Add address into the Account class hash field: `0x3ebe39375ba9e0f8cc21d5ee38c48818e8ed6612fa2e4e04702a323d64b96ba`
- Save and refresh page

If you receive an error after, create a new account in Loot Survivor Devnet (1 eth should be loaded) to resolve.


# Game Description

Loot Survivor is a game built under the Adventurers series. It encompases the Loot ecosystem by creating an environment in which adventurers are born to survive against a range of different oppositions. You must battle beasts, face frightening obstacles and build stats and acquire items in order to increase the chances of ranking up and progressing through the game.

## Stats

Adventurers receive 1+ upgrade on each level up to help them survive as they explore. Luck cannot be upgraded but can be gained by equipping jewellery items.

- Strength increases attack damage by 10%
- Vitality increases health +20ph +20 max health
- Dexterity increases chances of fleeing
- Wisdom helps avoid Beast ambush
- Intelligence helps avoid Obstacles
- Luck increases critical damage chance (Non-upgradeable)

## Efficacies

- There are 3 types of weapons: Blade, Bludgeon & Magic
- There are 3 types of armour material: Cloth, Hide & Metal 

**Weapon vs Armour Efficacy**

Type | Metal | Hide | Cloth |
|-----| ----- | ----- | ----- |
| Blade | Weak | Fair | Strong | 
| Bludgeon | Fair | Strong | Weak |
| Magic | Strong | Weak | Fair |
 
## Items 

Items can be purchased in the Marketplace auction. Items can be equipped to each item slot; 

- Weapon

Type | Item | Rank | 
|-----| ----- | ----- | 
| Blade | Katana | 1 | 
| Blade | Falchion  | 2 |
| Blade | Scimitar | 3 | 
| Blade | Long Sword | 4 | 
| Blade | Short Sword | 5 | 
| Bludgeon | Warhammer | 1 | 
| Bludgeon | Quarterstaff  | 2 |
| Bludgeon | Maul | 3 | 
| Bludgeon | Mace | 4 | 
| Bludgeon | Club | 5 | 
| Magic | Ghost Wand | 1 | 
| Magic | Grave Wand  | 2 |
| Magic | Bone Wand | 3 | 
| Magic | Wand | 4 | 
| Magic | Grimoire | 1 | 
| Magic | Chronicle | 2 | 
| Magic | Tome  | 3 |
| Magic | Book | 4 | 

- Head
- Chest
- Hands
- Waist
- Feet
- Neck 
- Ring

## Beasts 
## Obstacles 
## Levels
