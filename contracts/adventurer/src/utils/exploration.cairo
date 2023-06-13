use core::traits::Into;
use survivor::adventurer::{Adventurer, AdventurerActions};
use survivor::utils::constants::DiscoveryType;

fn get_random_explore(adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64) -> u64 {
    // return a random number between 0 and 3 based on provided entropy

    return (adventurer_entropy + game_entropy + adventurer.xp.into()) % 4;
}

fn get_discovery_type(adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64) -> u64 {
    return (adventurer_entropy + game_entropy + adventurer.xp.into()) % 4;
}

fn get_gold_discovery(adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64) -> u16 {
    return 1;
}
fn get_health_discovery(adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64) -> u16 {
    return 1;
}
fn get_xp_discovery(adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64) -> u16 {
    return 1;
}

#[test]
#[available_gas(4000000)]
fn test_explore_beast_discovery() {
    let adventurer = AdventurerActions::new(1, 1);
    let adventurer_entropy = 0;
    let game_entropy = 0;
    let discover_beast = get_random_explore(adventurer, adventurer_entropy, game_entropy);
    assert(discover_beast == DiscoveryType::Beast, 'should have found beast');
}

#[test]
#[available_gas(4000000)]
fn test_explore_obstacle_discovery() {
    let adventurer = AdventurerActions::new(1, 1);
    let adventurer_entropy = 0;
    let game_entropy = 1;
    let discover_obstacle = get_random_explore(adventurer, adventurer_entropy, game_entropy);
    assert(discover_obstacle == DiscoveryType::Obstacle, 'should have found obstacle');
}

#[test]
#[available_gas(4000000)]
fn test_explore_item_discovery() {
    let adventurer = AdventurerActions::new(1, 1);
    let adventurer_entropy = 0;
    let game_entropy = 2;
    let discover_item = get_random_explore(adventurer, adventurer_entropy, game_entropy);
    assert(discover_item == DiscoveryType::Item, 'should have found item');
}
