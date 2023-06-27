import { gql } from "@apollo/client";

const ADVENTURER_FIELDS = `
  beastHealth
  charisma
  chestId
  dexterity
  feetId
  handsId
  headId
  health
  id
  intelligence
  level
  luck
  name
  neckId
  order
  owner
  race
  ringId
  statUpgrades
  strength
  vitality
  waistId
  weaponId
  wisdom
  xp
  gold
`;

const ADVENTURERS_FRAGMENT = `
  fragment AdventurerFields on Adventurer {
    ${ADVENTURER_FIELDS}
  }
`;

const BATTLE_FIELDS = `
  adventurerId
  beast
  beastHealth
  beastLevel
  beastNamePrefix
  beastNameSuffix
  attacker
  fled
  damageDealt
  damageTaken
  damageLocation
  xpEarnedAdventurer
  xpEarnedItems
  goldEarned
  txHash
  timestamp
`;

const BATTLES_FRAGMENT = `
  fragment BattleFields on Battle {
    ${BATTLE_FIELDS}
  }
`;

const ITEM_FIELDS = `
  item
  cost
  owner
  ownerAdventurerId
  equippedAdventurerId
  purchasedTime
  namePrefix
  nameSuffix
  itemSuffix
  xp
  lastUpdatedTime
`;

const ITEMS_FRAGMENT = `
  fragment ItemFields on Item {
    ${ITEM_FIELDS}
  }
`;

const DISCOVERY_FIELDS = `
  adventurerId
  discoveryType
  subDiscoveryType
  outputAmount
  obstacle
  obstacleLevel
  dodgedObstacle
  damageTaken
  damageLocation
  xp_earned_adventurer
  xp_earned_items
  entityId
  entityLevel
  entityHealth
  ambushed
  discoveryTime
  txHash
`;

const DISCOVERIES_FRAGMENT = `
  fragment DiscoveryFields on Item {
    ${DISCOVERY_FIELDS}
  }
`;

const getAdventurer = gql`
  ${ADVENTURERS_FRAGMENT}
  query get_adventurer($owner: HexValue) {
    adventurers(where: { owner: { eq: $owner } }) {
      ...AdventurerFields
    }
  }
`;

const getDiscoveries = gql`
  ${DISCOVERIES_FRAGMENT}
  query get_discoveries($adventurerId: FeltValue) {
    discoveries(
      where: { adventurerId: { eq: $adventurerId } }
      limit: 1000000
      orderBy: { discoveryTime: { desc: true } }
    ) {
      ...DiscoveryFields
    }
  }
`;

const getLatestDiscoveries = gql`
  ${DISCOVERIES_FRAGMENT}
  query get_latest_discoveries($adventurerId: FeltValue) {
    discoveries(
      where: { adventurerId: { eq: $adventurerId } }
      limit: 10
      orderBy: { discoveryTime: { desc: true } }
    ) {
      ...DiscoveryFields
    }
  }
`;

const getLastDiscovery = gql`
  ${DISCOVERIES_FRAGMENT}
  query get_last_discovery($adventurerId: FeltValue) {
    discoveries(
      where: { adventurerId: { eq: $adventurerId } }
      limit: 1
      orderBy: { discoveryTime: { desc: true } }
    ) {
      ...DiscoveryFields
    }
  }
`;

const getLastBeastDiscovery = gql`
  ${DISCOVERIES_FRAGMENT}
  query get_last_beast_query($adventurerId: FeltValue) {
    discoveries(
      where: { adventurerId: { eq: $adventurerId }, entity: { gt: 0 } }
      limit: 1
      orderBy: { discoveryTime: { desc: true } }
    )
  }
`;

const getDiscoveryByTxHash = gql`
  ${DISCOVERIES_FRAGMENT}
  query get_discovery($txHash: HexValue) {
    discoveries(where: { txHash: { eq: $txHash } }) {
      ...DiscoveryFields
    }
  }
`;

const getItems = gql`
  ${ITEMS_FRAGMENT}
  query get_items {
    items {
      ...ItemFields
    }
  }
`;

const getAdventurersByOwner = gql`
  ${ADVENTURERS_FRAGMENT}
  query get_adventurers_by_owner($owner: HexValue) {
    adventurers(where: { owner: { eq: $owner } }, limit: 10000000) {
      ...AdventurerFields
    }
  }
`;

const getAdventurerById = gql`
  ${ADVENTURERS_FRAGMENT}
  query get_adventurer_by_id($id: FeltValue) {
    adventurers(where: { id: { eq: $id } }) {
      ...AdventurerFields
    }
  }
`;

const getAdventurersInList = gql`
  ${ADVENTURERS_FRAGMENT}
  query get_adventurer_by_id($ids: [FeltValue!]) {
    adventurers(where: { id: { In: $ids } }, limit: 10000000) {
      ...AdventurerFields
    }
  }
`;

const getAdventurersInListByXp = gql`
  ${ADVENTURERS_FRAGMENT}
  query get_adventurer_by_id_order_xp($ids: [FeltValue!]) {
    adventurers(
      where: { id: { In: $ids } }
      limit: 10000000
      orderBy: { xp: { desc: true } }
    ) {
      ...AdventurerFields
    }
  }
`;

const getAdventurerByGold = gql`
  ${ADVENTURERS_FRAGMENT}
  query get_adventurer_by_gold {
    adventurers(orderBy: { gold: { desc: true } }, limit: 10000000) {
      ...AdventurerFields
    }
  }
`;

const getAdventurerByXP = gql`
  ${ADVENTURERS_FRAGMENT}
  query get_adventurer_by_xp {
    adventurers(orderBy: { xp: { desc: true } }, limit: 10000000) {
      ...AdventurerFields
    }
  }
`;

const getAdventurersByXPPaginated = gql`
  ${ADVENTURERS_FRAGMENT}
  query get_adventurer_by_xp_paginated($skip: Int) {
    adventurers(limit: 10, skip: $skip, orderBy: { xp: { desc: true } }) {
      ...AdventurerFields
    }
  }
`;

const getBeastById = gql`
  ${DISCOVERIES_FRAGMENT}
  query get_beast_by_id($id: FeltValue, $adventurerId: FeltValue) {
    discoveries(
      where: { entityId: { eq: $id }, adventurerId: { eq: $adventurerId } }
    ) {
      ...DISCOVERY_FIELDS
    }
  }
`;

const getBeastsByAdventurer = gql`
  ${DISCOVERIES_FRAGMENT}
  query get_beast_by_id($id: FeltValue) {
    discoveries(where: { adventurerId: { eq: $id } }) {
      ...DISCOVERY_FIELDS
    }
  }
`;

const getLatestBattlesByAdventurer = gql`
  ${BATTLES_FRAGMENT}
  query get_latest_battles($adventurerId: FeltValue) {
    battles(
      limit: 10
      orderBy: { timestamp: { desc: true } }
      where: { adventurerId: { eq: $adventurerId } }
    ) {
      ...BattleFields
    }
  }
`;

const getBattlesByAdventurer = gql`
  ${BATTLES_FRAGMENT}
  query get_battles($adventurerId: FeltValue) {
    battles(
      limit: 1000000
      orderBy: { timestamp: { desc: true } }
      where: { adventurerId: { eq: $adventurerId } }
    ) {
      ...BattleFields
    }
  }
`;

const getBattlesByBeast = gql`
  ${BATTLES_FRAGMENT}
  query get_battles_by_beast($adventurerId: FeltValue, $beastId: FeltValue) {
    battles(
      where: { adventurerId: { eq: $adventurerId }, beastId: { eq: $beastId } }
      orderBy: { timestamp: { desc: true } }
    ) {
      ...BattleFields
    }
  }
`;

const getLastBattleByAdventurer = gql`
  ${BATTLES_FRAGMENT}
  query get_latest_battle_by_adventurer($adventurerId: FeltValue) {
    battles(
      limit: 1
      where: { adventurerId: { eq: $adventurerId } }
      orderBy: { timestamp: { desc: true } }
    ) {
      ...BattleFields
    }
  }
`;

const getBattleByTxHash = gql`
  ${BATTLES_FRAGMENT}
  query get_latest_battle_by_tx($txHash: HexValue) {
    battles(
      where: { txHash: { eq: $txHash } }
      orderBy: { timestamp: { desc: true } }
    ) {
      ...BattleFields
    }
  }
`;

const getItemsByTokenId = gql`
  ${ITEM_FIELDS}
  query get_items($id: FeltValue) {
    items(where: { id: { eq: $id } }) {
      ...ItemFields
    }
  }
`;

const getLatestMarketItems = gql`
  ${ITEM_FIELDS}
  query get_latest_market_items($adventurerId: FeltValue) {
    items(
      where: { adventurerId: { eq: $adventurerId } }
      limit: 20
      orderBy: { createdBlock: { desc: true } }
    ) {
      ...ItemFields
    }
  }
`;

const getItemsByAdventurer = gql`
  ${ITEM_FIELDS}
  query get_items_by_adventurer($adventurer: FeltValue) {
    items(where: { ownerAdventurerId: { eq: $adventurer } }, limit: 10000000) {
      ...ItemFields
    }
  }
`;

const getUnclaimedItemsByAdventurer = gql`
  ${ITEM_FIELDS}
  query get_items_by_adventurer($bidder: FeltValue, $status: StatusValue) {
    items(
      where: { bidder: { eq: $bidder }, status: { eq: $status } }
      limit: 10000000
    ) {
      ...ItemFields
    }
  }
`;

const getItemsByOwner = gql`
  ${ITEM_FIELDS}
  query get_items_by_owner($owner: HexValue) {
    items(where: { owner: { eq: $owner } }, limit: 10000000) {
      ...ItemFields
    }
  }
`;

const getTopScores = gql`
  query get_top_scores {
    scores(orderBy: { score: { desc: true } }, limit: 10) {
      address
      adventurerId
      rank
      scoreTime
      txHash
    }
  }
`;

export {
  getAdventurer,
  getDiscoveries,
  getLatestDiscoveries,
  getLastDiscovery,
  getLastBeastDiscovery,
  getDiscoveryByTxHash,
  getAdventurersByOwner,
  getAdventurerById,
  getAdventurersInList,
  getAdventurersInListByXp,
  getAdventurerByGold,
  getBeastsByAdventurer,
  getBeastById,
  getLatestBattlesByAdventurer,
  getBattlesByBeast,
  getLastBattleByAdventurer,
  getBattlesByAdventurer,
  getBattleByTxHash,
  getItems,
  getItemsByTokenId,
  getLatestMarketItems,
  getItemsByOwner,
  getItemsByAdventurer,
  getUnclaimedItemsByAdventurer,
  getAdventurerByXP,
  getAdventurersByXPPaginated,
  getTopScores,
};
