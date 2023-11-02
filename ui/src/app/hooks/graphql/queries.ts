import { gql } from "@apollo/client";

const ADVENTURER_FIELDS = `
  id
  lastAction
  owner
  name
  health
  strength
  dexterity
  vitality
  intelligence
  wisdom
  charisma
  luck
  xp
  weapon
  chest
  head
  waist
  foot
  hand
  neck
  ring
  beastHealth
  statUpgrades
  startBlock
  revealBlock
  actionsPerBlock
  gold
  createdTime
  lastUpdatedTime
  timestamp
`;

const ADVENTURERS_FRAGMENT = `
  fragment AdventurerFields on Adventurer {
    ${ADVENTURER_FIELDS}
  }
`;

const BATTLE_FIELDS = `
  adventurerId
  adventurerHealth
  beast
  beastHealth
  beastLevel
  special1
  special2
  special3
  seed
  attacker
  fled
  damageDealt
  damageTaken
  criticalHit
  damageLocation
  xpEarnedAdventurer
  xpEarnedItems
  goldEarned
  txHash
  blockTime
  timestamp
`;

const BATTLES_FRAGMENT = `
  fragment BattleFields on Battle {
    ${BATTLE_FIELDS}
  }
`;

const ITEM_FIELDS = `
  item
  adventurerId
  ownerAddress
  owner
  equipped
  purchasedTime
  special1
  special2
  special3
  xp
  isAvailable
  timestamp
`;

const ITEMS_FRAGMENT = `
  fragment ItemFields on Item {
    ${ITEM_FIELDS}
  }
`;

const DISCOVERY_FIELDS = `
  adventurerId
  adventurerHealth
  discoveryType
  subDiscoveryType
  outputAmount
  obstacle
  obstacleLevel
  dodgedObstacle
  damageTaken
  damageLocation
  xpEarnedAdventurer
  xpEarnedItems
  entity
  entityLevel
  entityHealth
  special1
  special2
  special3
  seed
  ambushed
  discoveryTime
  txHash
  timestamp
`;

const DISCOVERIES_FRAGMENT = `
  fragment DiscoveryFields on Discovery {
    ${DISCOVERY_FIELDS}
  }
`;

const BEAST_FIELDS = `
  adventurerId
  beast
  createdTime
  health
  lastUpdatedTime
  level
  seed
  slainOnTime
  special1
  special2
  special3
  timestamp
`;

const BEASTS_FRAGMENT = `
  fragment BeastFields on Beast {
    ${BEAST_FIELDS}
  }
`;

const SCORE_FIELDS = `
  adventurerId
  timestamp
  totalPayout
`;

const SCORES_FRAGMENT = `
  fragment ScoreFields on Score {
    ${SCORE_FIELDS}
  }
`;

const GOLDEN_TOKEN_FIELDS = `
  contract_address
  id
  image
  name
  owner
  token_id
`;

const GOLDEN_TOKEN_FRAGMENT = `
  fragment GoldenTokenFields on ERC721Tokens {
    ${GOLDEN_TOKEN_FIELDS}
  }
`;

const getAdventurer = gql`
  ${ADVENTURERS_FRAGMENT}
  query getAdventurer($owner: HexValue) {
    adventurers(where: { owner: { eq: $owner } }) {
      ...AdventurerFields
    }
  }
`;

const getDiscoveries = gql`
  ${DISCOVERIES_FRAGMENT}
  query getDiscoveries($id: FeltValue) {
    discoveries(
      where: { adventurerId: { eq: $id } }
      limit: 1000000
      orderBy: { timestamp: { desc: true } }
    ) {
      ...DiscoveryFields
    }
  }
`;

const getLatestDiscoveries = gql`
  ${DISCOVERIES_FRAGMENT}
  query getLatestDiscoveries($id: FeltValue) {
    discoveries(
      where: { adventurerId: { eq: $id } }
      limit: 10
      orderBy: { timestamp: { desc: true } }
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
      orderBy: { timestamp: { desc: true } }
    ) {
      ...DiscoveryFields
    }
  }
`;

const getLastBeastDiscovery = gql`
  ${DISCOVERIES_FRAGMENT}
  query get_last_beast_query($id: FeltValue) {
    discoveries(
      where: { adventurerId: { eq: $id }, entityLevel: { gt: 0 } }
      limit: 1
      orderBy: { timestamp: { desc: true } }
    ) {
      ...DiscoveryFields
    }
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

const getBeast = gql`
  ${BEASTS_FRAGMENT}
  query get_beast_by_id(
    $beast: BeastValue
    $adventurerId: FeltValue
    $seed: HexValue
  ) {
    beasts(
      where: {
        beast: { eq: $beast }
        adventurerId: { eq: $adventurerId }
        seed: { eq: $seed }
      }
    ) {
      ...BeastFields
    }
  }
`;

const getBeastsByAdventurer = gql`
  ${DISCOVERIES_FRAGMENT}
  query get_beast_by_id($id: FeltValue) {
    discoveries(where: { adventurerId: { eq: $id } }) {
      ...DiscoveryFields
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
  query get_battles_by_beast(
    $adventurerId: FeltValue
    $beast: BeastValue
    $seed: HexValue
  ) {
    battles(
      where: {
        adventurerId: { eq: $adventurerId }
        beast: { eq: $beast }
        seed: { eq: $seed }
      }
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
      orderBy: { timestamp: { asc: true } }
    ) {
      ...BattleFields
    }
  }
`;

const getItemsByTokenId = gql`
  ${ITEMS_FRAGMENT}
  query get_items($item: ItemValue) {
    items(where: { item: { eq: $item } }) {
      ...ItemFields
    }
  }
`;

const getLatestMarketItems = gql`
  ${ITEMS_FRAGMENT}
  query get_latest_market_items($id: FeltValue) {
    items(
      where: { adventurerId: { eq: $id }, isAvailable: { eq: true } }
      limit: 100000
    ) {
      ...ItemFields
    }
  }
`;

const getItemsByAdventurer = gql`
  ${ITEMS_FRAGMENT}
  query get_items_by_adventurer($id: FeltValue) {
    items(
      where: { adventurerId: { eq: $id }, owner: { eq: true } }
      limit: 10000000
    ) {
      ...ItemFields
    }
  }
`;

const getItemsByOwner = gql`
  ${ITEMS_FRAGMENT}
  query get_items_by_owner($owner: HexValue) {
    items(where: { owner: { eq: $owner } }, limit: 10000000) {
      ...ItemFields
    }
  }
`;

const getTopScores = gql`
  ${SCORES_FRAGMENT}
  query get_top_scores {
    scores(limit: 10000000) {
      ...ScoreFields
    }
  }
`;

const getScoresInList = gql`
  ${SCORES_FRAGMENT}
  query get_top_scores($ids: [FeltValue!]) {
    scores(where: { adventurerId: { In: $ids } }, limit: 10000000) {
      ...ScoreFields
    }
  }
`;

const getGoldenTokensByOwner = gql`
  ${GOLDEN_TOKEN_FRAGMENT}
  query getGoldenTokensByOwner($contractAddress: String!, $owner: String!) {
    getERC721Tokens(
      contract_address: $contractAddress
      cursor: 0
      limit: 10000
      owner: $owner
    ) {
      ...GoldenTokenFields
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
  getBeast,
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
  getAdventurerByXP,
  getAdventurersByXPPaginated,
  getTopScores,
  getScoresInList,
  getGoldenTokensByOwner,
};
