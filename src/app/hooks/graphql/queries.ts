import { gql } from "@apollo/client";

const getAdventurer = gql`
query get_adventurer($owner: HexValue) {
    adventurers(where: {owner: {eq: $owner}}) {
      beastId
      charisma
      chestId
      dexterity
      feetId
      handsId
      headId
      health
      id
      imageHash1
      imageHash2
      intelligence
      level
      luck
      name
      neckId
      order
      owner
      race
      ringId
      status
      strength
      upgrading
      vitality
      waistId
      weaponId
      wisdom
      xp
      gold
    }
  }
`;


const getBeast = gql`
query get_beast($owner: HexValue) {
    beasts {
        adventurerId
        armorType
        attackType
        beast
        health
        id
        level
        prefix1
        prefix2
        rank
        xp
    }
  }
`;

const getDiscovery = gql`
query get_discovery($owner: HexValue) {
    discoveries {
        adventurerId
        discoveryTime
        discoveryType
        entityId
        outputAmount
        subDiscoveryType
        TxHash
    }
  }
`;

const getItems = gql`
query get_items($owner: HexValue) {
    items {
        adventurerId
        bag
        bidder
        claimedTime
        createdBlock
        expiry
        greatness
        id
        item
        marketId
        material
        owner
        prefix1
        prefix2
        price
        rank
        slot
        status
        suffix
        type
        xp
    }
  }
`;

const getAdventurersByOwner = gql`
query get_adventurers_by_owner($owner: HexValue) {
    adventurers(where: {owner: {eq: $owner}}) {
      beastId
      charisma
      chestId
      dexterity
      feetId
      handsId
      headId
      health
      id
      imageHash1
      imageHash2
      intelligence
      level
      luck
      name
      neckId
      order
      owner
      race
      ringId
      status
      strength
      upgrading
      vitality
      waistId
      weaponId
      wisdom
      xp
      gold
    }
  }
`;

const getAdventurerById = gql`
query get_adventurer_by_id($id: FeltValue) {
    adventurers(where: {id: {eq: $id}}) {
      beastId
      charisma
      chestId
      dexterity
      feetId
      handsId
      headId
      health
      id
      imageHash1
      imageHash2
      intelligence
      level
      luck
      name
      neckId
      order
      owner
      race
      ringId
      status
      strength
      upgrading
      vitality
      waistId
      weaponId
      wisdom
      xp
      gold
    }
  }
`;

const getBeastsById = gql`
query get_beasts_by_id($id: number) {
    beasts(where: {id: {eq: $id}}) {
      adventurerId
      armorType
      attackType
      beast
      health
      id
      level
      prefix1
      prefix2
      rank
      slainOnDate
      xp
    }
  }
`;

const getItemsByMarketId = gql`
query get_items_by_market_id {
    items{
        adventurerId
        bag
        bidder
        claimedTime
        createdBlocks
        expiry
        greatness
        id
        item
        lastUpdated
        marketId
        material
        owner
        prefix1
        prefix2
        price
        rank
        slot
        status
        suffix
        type
        xp
    }
  }
`;

const getDiscoveryByTxHash = gql`
query get_discovery($TxHash: HexValue) {
    discoveries(where: {TxHash: {eq: $TxHash}}) {
        adventurerId
        discoveryTime
        discoveryType
        entityId
        outputAmount
        subDiscoveryType
        TxHash
    }
  }
`;

const getItemsByTokenId = gql`
query get_items($id: FeltValue) {
    items(where: {id: {eq: $id}}) {
        adventurerId
        bag
        bidder
        claimedTime
        createdBlock
        expiry
        greatness
        id
        item
        marketId
        material
        owner
        prefix1
        prefix2
        price
        rank
        slot
        status
        suffix
        type
        xp
    }
  }
`;

const getItemsByAdventurer = gql`
query get_items($id: FeltValue) {
    items(limit: 20, orderBy: {createdBlock: {desc: true}}) {
        adventurerId
        bag
        bidder
        claimedTime
        createdBlock
        expiry
        greatness
        id
        item
        marketId
        material
        owner
        prefix1
        prefix2
        price
        rank
        slot
        status
        suffix
        type
        xp
    }
  }
`;

const getItemsByOwner = gql`
query get_items_by_owner($owner: HexValue) {
    items(where: {owner: {eq: $owner}}) {
      adventurerId
        bag
        bidder
        claimedTime
        createdBlock
        expiry
        greatness
        id
        item
        marketId
        material
        owner
        prefix1
        prefix2
        price
        rank
        slot
        status
        suffix
        type
        xp
    }
  }
`;

export {
    getAdventurer,
    getBeast,
    getDiscovery,
    getItems,
    getAdventurersByOwner,
    getAdventurerById,
    getBeastsById,
    getItemsByMarketId,
    getDiscoveryByTxHash,
    getItemsByTokenId,
    getItemsByAdventurer,
    getItemsByOwner,
};
