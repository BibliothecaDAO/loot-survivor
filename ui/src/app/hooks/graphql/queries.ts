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
      attackLocation
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

const getLatestDiscoveries = gql`
  query get_discoveries($adventurerId: FeltValue) {
    discoveries(
      where: { adventurerId: { eq: $adventurerId } }
      limit: 10
      orderBy: { discoveryTime: { desc: true } }
    ) {
      adventurerId
      attackLocation
      discoveryTime
      discoveryType
      entityId
      outputAmount
      subDiscoveryType
      txHash
    }
  }
`;

const getLastDiscovery = gql`
  query get_discoveries($adventurerId: FeltValue) {
    discoveries(
      where: { adventurerId: { eq: $adventurerId } }
      limit: 1
      orderBy: { discoveryTime: { desc: true } }
    ) {
      adventurerId
      attackLocation
      discoveryTime
      discoveryType
      entityId
      outputAmount
      subDiscoveryType
      txHash
    }
  }
`;

const getDiscoveryByTxHash = gql`
  query get_discovery($txHash: HexValue) {
    discoveries(where: { txHash: { eq: $txHash } }) {
      adventurerId
      attackLocation
      discoveryTime
      discoveryType
      entityId
      outputAmount
      subDiscoveryType
      txHash
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

const getAdventurersInList = gql`
  query get_adventurer_by_id($ids: [FeltValue!]) {
    adventurers(where: { id: { In: $ids } }, limit: 10000000) {
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

const getAdventurerByGold = gql`
  query get_adventurer_by_gold {
    adventurers(orderBy: { gold: { desc: true } }, limit: 10000000) {
      id
      name
      gold
      beastId
      birthdate
      charisma
      chestId
      dexterity
      feetId
      handsId
      headId
      health
      homeRealm
      imageHash1
      imageHash2
      intelligence
      lastUpdated
      level
      luck
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
    }
  }
`;

const getBeastById = gql`
  query get_beast_by_id($id: FeltValue) {
    beasts(where: { id: { eq: $id } }) {
      adventurerId
      armorType
      attackType
      attackLocation
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

const getLatestBattlesByAdventurer = gql`
  query get_latest_battles($adventurerId: FeltValue) {
    battles(
      limit: 10
      orderBy: { timestamp: { desc: true } }
      where: { adventurerId: { eq: $adventurerId } }
    ) {
      adventurerId
      ambushed
      attacker
      beastId
      damage
      fled
      goldEarned
      targetHealth
      timestamp
      txHash
      xpEarned
    }
  }
`;

const getBattlesByBeast = gql`
  query get_battles_by_beast($adventurerId: FeltValue, $beastId: FeltValue) {
    battles(
      where: { adventurerId: { eq: $adventurerId }, beastId: { eq: $beastId } }
      orderBy: { timestamp: { desc: true } }
    ) {
      adventurerId
      ambushed
      attacker
      beastId
      damage
      fled
      goldEarned
      targetHealth
      timestamp
      txHash
      xpEarned
    }
  }
`;

const getLastBattleByAdventurer = gql`
  query get_latest_battle_by_adventurer($adventurerId: FeltValue) {
    battles(
      limit: 1
      where: { adventurerId: { eq: $adventurerId } }
      orderBy: { timestamp: { desc: true } }
    ) {
      adventurerId
      ambushed
      attacker
      beastId
      damage
      fled
      goldEarned
      targetHealth
      timestamp
      txHash
      xpEarned
    }
  }
`;

const getBattleByTxHash = gql`
  query get_latest_battle_by_tx($txHash: HexValue) {
    battles(
      where: { txHash: { eq: $txHash } }
      orderBy: { timestamp: { desc: true } }
    ) {
      adventurerId
      ambushed
      attacker
      beastId
      damage
      fled
      goldEarned
      targetHealth
      timestamp
      txHash
      xpEarned
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

const getLatestMarketItems = gql`
  query get_latest_market_items($itemsNumber: Int) {
    items(
      where: { marketId: { gt: 0 } }
      limit: $itemsNumber
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
    items(where: { ownerAdventurerId: { eq: $adventurer } }, limit: 10000000) {
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

const getUnclaimedItemsByAdventurer = gql`
  query get_items_by_adventurer($bidder: FeltValue, $status: StatusValue) {
    items(
      where: { bidder: { eq: $bidder }, status: { eq: $status } }
      limit: 10000000
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

const getItemsByOwner = gql`
  query get_items_by_owner($owner: HexValue) {
    items(where: { owner: { eq: $owner } }, limit: 10000000) {
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

const getLatestMarketItemsNumber = gql`
  query get_market_items_number {
    market(limit: 1, orderBy: { timestamp: { desc: true } }) {
      caller
      itemsNumber
      timestamp
    }
  }
`;

export {
  getAdventurer,
  getLatestDiscoveries,
  getLastDiscovery,
  getDiscoveryByTxHash,
  getAdventurersByOwner,
  getAdventurerById,
  getAdventurersInList,
  getAdventurerByGold,
  getBeasts,
  getBeastById,
  getLatestBattlesByAdventurer,
  getBattlesByBeast,
  getLastBattleByAdventurer,
  getBattleByTxHash,
  getItems,
  getItemsByTokenId,
  getLatestMarketItems,
  getItemsByOwner,
  getItemsByAdventurer,
  getLatestMarketItemsNumber,
  getUnclaimedItemsByAdventurer,
};
