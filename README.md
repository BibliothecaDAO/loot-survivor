# Loot Survivor Game

Welcome to the Loot Survivor game repository, where you'll find both the client and indexer that make up this immersive gaming experience. 

Access the app here: [Loot Survivor](https://loot-survivor.vercel.app/)

## Running the Game Locally

### Prerequisites

If you do not have Yarn installed:

1. Install Node.js from [here](https://nodejs.org/en/download/).

2. Install Yarn globally by running this command in your terminal:

   ```
   npm install --global yarn
   ```

   If you encounter a permissions error, you may need to use sudo:

   ```
   sudo npm install --global yarn
   ```

### Starting the App

To run the app locally, follow these steps:

1. Clone the repository:

   ```
   git clone https://github.com/BibliothecaDAO/loot-survivor.git
   ```

2. Set up the server:

   ```
   cd loot-survivor/ui
   yarn
   yarn dev
   ```

You should now be able to access the app at [http://localhost:3000/](http://localhost:3000/).

## Setting up Devnet:

To set up a development network (devnet):

1. Select "Launch on Devnet".
2. Connect ArgentX.
3. Add Devnet (confirm this action in Argent).
4. Switch to Devnet (again, confirm in Argent).
5. Open Argent and create an account. You will receive 1 ETH as a starting balance. This might take a few seconds.

To check your ETH balance, add the token address: `0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7`

If you encounter an error that reads `Class with hash 0x3343...`, follow these steps to resolve it:

1. Go to your ArgentX wallet.
2. Select the Settings cog icon.
3. Open Developer settings.
4. Manage networks.
5. Choose Loot Survivor Devnet.
6. Open Advanced settings.
7. Add this address to the Account class hash field: `0x3ebe39375ba9e0f8cc21d5ee38c48818e8ed6612fa2e4e04702a323d64b96ba`
8. Save your changes and refresh the page.

If you still receive an error, try creating a new account in Loot Survivor Devnet (1 ETH should be loaded) to resolve it.

# Game Description

Loot Survivor is a part of the Adventurers series and builds upon the Loot ecosystem to create an environment where adventurers must battle beasts, overcome terrifying obstacles, boost their stats, and acquire items to advance in the game.

## Stats

Each level up grants adventurers 1+ upgrade to help them survive their explorations. Although Luck cannot be upgraded directly, it can be increased by equipping jewelry items:

- Strength: Boosts attack damage by 10%.
- Vitality: Increases health by +20ph and max health.
- Dexterity: Improves chances of successfully fleeing.
- Wisdom: Helps evade Beast ambushes.
- Intelligence: Aids in avoiding Obstacles.
- Luck: Raises chances of critical damage (cannot be upgraded directly).

## Efficacies

There are three categories of weapons and armor materials:

**Weapons**: Blade, Bludgeon, Magic

**Armor materials**: Cloth, Hide, Metal 

**Weapon vs. Armor Efficacy Chart**

| Weapon Type | Metal | Hide | Cloth |
|-------------|-------|------|-------|
| Blade       | Weak  | Fair | Strong|
| Bludgeon    | Fair  | Strong| Weak|
| Magic       | Strong | Weak | Fair |

## Items

Items can be purchased in the Marketplace auction and can be equipped in each item slot. Available slots include:

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

## Progression

- Levels
