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
yarn build
yarn start
```

You will find the app at http://localhost:3000/.

Setting up devnet:

- Select "Launch on Devnet"
- Select "Connect ArgentX"
- Select "Add Devnet" (confirm in Argent)
- Select "Switch to Devnet" (confirm in Argent)
- Open Argent and create an account. You will be given 1 ETH as a starting balance. (May take a few seconds to create)

To see your ETH balance add token address `0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7`


## Game Description

Loot Survivor is a game built under the Adventurers series. It encompases the Loot ecosystem by creating an environment in which adventurers are born to survive against a range of different oppositions. You must battle beasts, face frightening obstacles and build stats and acquire items in order to increase the chances of ranking up and progressing through the game.

### Stats

### Efficacies
