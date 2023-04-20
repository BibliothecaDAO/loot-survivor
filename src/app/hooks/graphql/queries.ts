import { gql } from "@apollo/client";

const getAdventurer = gql`
  query get_adventurer($owner: HexValue) {
    adventurers(where: { owner: { eq: $owner } }) {
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

const getBeasts = gql`
  query get_beasts {
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

const getDiscoveries = gql`
  query get_discoveries {
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
  query get_items {
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
    adventurers(where: { owner: { eq: $owner } }) {
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
    adventurers(where: { id: { eq: $id } }) {
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

const getBeastById = gql`
  query get_beast_by_id($id: number) {
    beasts(where: { id: { eq: $id } }) {
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

const getDiscoveryByTxHash = gql`
  query get_discovery($txHash: HexValue) {
    discoveries(where: { txHash: { eq: $txHash } }) {
      adventurerId
      discoveryTime
      discoveryType
      entityId
      outputAmount
      subDiscoveryType
      txHash
    }
  }
`;

const getItemsByTokenId = gql`
  query get_items($id: FeltValue) {
    items(where: { id: { eq: $id } }) {
      bag
      bidder
      claimedTime
      createdBlock
      equippedAdventurerId
      expiry
      greatness
      id
      item
      lastUpdated
      marketId
      material
      owner
      ownerAdventurerId
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

const getItemsByTokenIds = gql`
  query get_items($ids: [FeltValue]) {
    items(where: { id: { In: $ids } }) {
      bag
      bidder
      claimedTime
      createdBlock
      equippedAdventurerId
      expiry
      greatness
      id
      item
      lastUpdated
      marketId
      material
      owner
      ownerAdventurerId
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

const getMarketItems = gql`
  query get_market_items {
    items(
      where: { marketId: { gt: "0" } }
      limit: 20
      orderBy: { createdBlock: { desc: true } }
    ) {
      bag
      bidder
      claimedTime
      createdBlock
      equippedAdventurerId
      expiry
      greatness
      id
      item
      lastUpdated
      marketId
      material
      owner
      ownerAdventurerId
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
  query get_items_by_adventurer($adventurer: FeltValue) {
    items(where: { ownerAdventurerId: { eq: $adventurer } }) {
      bag
      bidder
      claimedTime
      createdBlock
      equippedAdventurerId
      expiry
      greatness
      id
      item
      lastUpdated
      marketId
      material
      owner
      ownerAdventurerId
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
    items(where: { owner: { eq: $owner } }) {
      bag
      bidder
      claimedTime
      createdBlock
      equippedAdventurerId
      expiry
      greatness
      id
      item
      lastUpdated
      marketId
      material
      owner
      ownerAdventurerId
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
  getBeasts,
  getDiscoveries,
  getItems,
  getAdventurersByOwner,
  getAdventurerById,
  getBeastById,
  getDiscoveryByTxHash,
  getItemsByTokenId,
  getMarketItems,
  getItemsByOwner,
  getItemsByAdventurer,
};
