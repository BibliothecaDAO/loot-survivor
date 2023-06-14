use core::option::OptionTrait;
use core::traits::Into;
use survivor::adventurer::{Adventurer, AdventurerActions};
use survivor::constants::discovery_constants::DiscoveryType;
use integer::{U8IntoU64, U64TryIntoU16};

trait Explore {
    fn get_random_explore(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u64;
    fn get_discovery_type(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u64;
    fn get_level_adjusted_discovery_amount(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u16;
    fn get_gold_discovery(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u16;
    fn get_health_discovery(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u16;
    fn get_xp_discovery(adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64) -> u16;
}

impl ExploreUtils of Explore {
    // get_random_explore returns a random number between 0 and 3 based on provided entropy
    // @param adventurer: Adventurer
    // @param adventurer_entropy: The adventurer specific entropy seed
    // @param game_entropy: The global game entropy seed
    // @return u64: A random number between 0 and 3 denoting the outcome of the explore
    fn get_random_explore(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u64 {
        return (adventurer_entropy + game_entropy) % 3;
    } // get_discovery_type returns a random number between 0 and 3 based on provided entropy
    // @param adventurer: Adventurer
    // @param adventurer_entropy: The adventurer specific entropy seed
    // @param game_entropy: The global game entropy seed
    // @return u64: A random number between 0 and 3 denoting the outcome of the explore
    fn get_discovery_type(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u64 {
        return (adventurer_entropy + game_entropy + adventurer.xp.into()) % 3;
    }

    // get_level_adjusted_discovery_amount generates a random discovery amount based on adventurer level and provided entropy
    // @param adventurer: Adventurer
    // @param adventurer_entropy: The adventurer specific entropy seed
    // @param game_entropy: The global game entropy seed
    // @return u16: the amount of gold discovered
    fn get_level_adjusted_discovery_amount(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u16 {
        // get adventurer's level
        let adventurer_level = AdventurerActions::get_level(adventurer);

        // divide adventurer level by 5 and store the whole number
        let discovery_multiplier = adventurer_level / 5;

        // add 1 to the whole number, multiply by 3, and convert to u64
        let discovery_range = U8IntoU64::into((discovery_multiplier + 1) * 3);

        // add adventurer entropy and game entropy to produce rnd
        let rnd = adventurer_entropy + game_entropy;

        // divide rnd by discovery_range and store the remainder as discovery amount
        let discovery_amount = rnd % discovery_range;

        // return discovery amount as a u16
        return U64TryIntoU16::try_into(discovery_amount).unwrap();
    }

    // get_gold_discovery generates a random gold discovery based on adventurer level and provided entropy
    // @param adventurer: Adventurer
    // @param adventurer_entropy: The adventurer specific entropy seed
    // @param game_entropy: The global game entropy seed
    // @return u16: the amount of gold discovered
    // @dev splitting up the discovery types into their own functions to provide option to adjust discovery amounts by type
    //      for example by making gold discovery amount higher than health discovery amounts.
    fn get_gold_discovery(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u16 {
        // generate gold discovery based on adventurer level
        return ExploreUtils::get_level_adjusted_discovery_amount(
            adventurer, adventurer_entropy, game_entropy
        );
    }

    // get_health_discovery generates a random health discovery based on adventurer level and provided entropy
    // @param adventurer: Adventurer
    // @param adventurer_entropy: The adventurer specific entropy seed
    // @param game_entropy: The global game entropy seed
    // @return u16: the amount of health discovered
    // @dev splitting up the discovery types into their own functions to provide option to adjust discovery amounts by type
    //      for example by making gold discovery amount higher than health discovery amounts.
    fn get_health_discovery(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u16 {
        return ExploreUtils::get_level_adjusted_discovery_amount(
            adventurer, adventurer_entropy, game_entropy
        );
    }

    // get_xp_discovery generates a random xp discovery based on adventurer level and provided entropy
    // @param adventurer: Adventurer
    // @param adventurer_entropy: The adventurer specific entropy seed
    // @param game_entropy: The global game entropy seed
    // @return u16: the amount of xp discovered
    // @dev splitting up the discovery types into their own functions to provide option to adjust discovery amounts by type
    //      for example by making gold discovery amount higher than xp discovery amounts.
    fn get_xp_discovery(adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64) -> u16 {
        return ExploreUtils::get_level_adjusted_discovery_amount(
            adventurer, adventurer_entropy, game_entropy
        );
    }
}

#[test]
#[available_gas(4000000)]
fn test_explore_beast_discovery() {
    let adventurer = AdventurerActions::new(1, 1);
    let adventurer_entropy = 0;
    let game_entropy = 0;
    let discover_beast = ExploreUtils::get_random_explore(
        adventurer, adventurer_entropy, game_entropy
    );
    assert(discover_beast == DiscoveryType::Beast, 'should have found beast');
}

#[test]
#[available_gas(4000000)]
fn test_explore_obstacle_discovery() {
    let adventurer = AdventurerActions::new(1, 1);
    let adventurer_entropy = 0;
    let game_entropy = 1;
    let discover_obstacle = ExploreUtils::get_random_explore(
        adventurer, adventurer_entropy, game_entropy
    );
    assert(discover_obstacle == DiscoveryType::Obstacle, 'should have found obstacle');
}

#[test]
#[available_gas(4000000)]
fn test_explore_item_discovery() {
    let adventurer = AdventurerActions::new(1, 1);
    let adventurer_entropy = 0;
    let game_entropy = 2;
    let discover_item = ExploreUtils::get_random_explore(
        adventurer, adventurer_entropy, game_entropy
    );
    assert(discover_item == DiscoveryType::LootStatistics, 'should have found item');
}
