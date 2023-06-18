use core::option::OptionTrait;
use core::traits::Into;
use survivor::adventurer::{Adventurer, ImplAdventurer};
use survivor::constants::discovery_constants::{
    DiscoveryEnums::TreasureDiscovery, DiscoveryEnums::ExploreResult
};
use integer::{U8IntoU64, U64TryIntoU16};

trait Explore {
    fn get_random_treasury_discovery(adventurer: Adventurer, entropy: u64) -> TreasureDiscovery;
    fn get_level_adjusted_discovery_amount(adventurer: Adventurer, entropy: u64) -> u16;
    fn get_gold_discovery(adventurer: Adventurer, entropy: u64) -> u16;
    fn get_health_discovery(adventurer: Adventurer, entropy: u64) -> u16;
    fn get_xp_discovery(adventurer: Adventurer, entropy: u64) -> u16;
}

impl ExploreUtils of Explore {
    // get_random_treasury_discovery returns a random number between 0 and 3 based on provided entropy
    // @param adventurer: Adventurer
    // @param adventurer_entropy: The adventurer specific entropy seed
    // @param game_entropy: The global game entropy seed
    // @return u64: A random number between 0 and 3 denoting the outcome of the explore
    fn get_random_treasury_discovery(adventurer: Adventurer, entropy: u64) -> TreasureDiscovery {
        let discovery_type = entropy + adventurer.xp.into() % 3;
        if (discovery_type == 0) {
            return TreasureDiscovery::Gold(());
        } else if (discovery_type == 1) {
            return TreasureDiscovery::Health(());
        } else {
            return TreasureDiscovery::XP(());
        }
    }

    // get_level_adjusted_discovery_amount generates a random discovery amount based on adventurer level and provided entropy
    // @param adventurer: Adventurer
    // @param adventurer_entropy: The adventurer specific entropy seed
    // @param game_entropy: The global game entropy seed
    // @return u16: the amount of gold discovered
    fn get_level_adjusted_discovery_amount(adventurer: Adventurer, entropy: u64) -> u16 {
        // get adventurer's level
        let adventurer_level = ImplAdventurer::get_level(adventurer.xp);

        // divide adventurer level by 5 and store the whole number
        let discovery_multiplier = adventurer_level / 5;

        // add 1 to the whole number, multiply by 3, and convert to u64
        let discovery_range = U8IntoU64::into((discovery_multiplier + 1) * 3);

        // divide rnd by discovery_range and store the remainder as discovery amount
        let discovery_amount = entropy % discovery_range;

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
    fn get_gold_discovery(adventurer: Adventurer, entropy: u64) -> u16 {
        // generate gold discovery based on adventurer level
        return ExploreUtils::get_level_adjusted_discovery_amount(adventurer, entropy);
    }

    // get_health_discovery generates a random health discovery based on adventurer level and provided entropy
    // @param adventurer: Adventurer
    // @param adventurer_entropy: The adventurer specific entropy seed
    // @param game_entropy: The global game entropy seed
    // @return u16: the amount of health discovered
    // @dev splitting up the discovery types into their own functions to provide option to adjust discovery amounts by type
    //      for example by making gold discovery amount higher than health discovery amounts.
    fn get_health_discovery(adventurer: Adventurer, entropy: u64) -> u16 {
        return ExploreUtils::get_level_adjusted_discovery_amount(adventurer, entropy);
    }

    // get_xp_discovery generates a random xp discovery based on adventurer level and provided entropy
    // @param adventurer: Adventurer
    // @param adventurer_entropy: The adventurer specific entropy seed
    // @param game_entropy: The global game entropy seed
    // @return u16: the amount of xp discovered
    // @dev splitting up the discovery types into their own functions to provide option to adjust discovery amounts by type
    //      for example by making gold discovery amount higher than xp discovery amounts.
    fn get_xp_discovery(adventurer: Adventurer, entropy: u64) -> u16 {
        return ExploreUtils::get_level_adjusted_discovery_amount(adventurer, entropy);
    }
}
