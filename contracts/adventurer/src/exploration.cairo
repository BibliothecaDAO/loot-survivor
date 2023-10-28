use core::option::OptionTrait;
use core::traits::{Into, TryInto};

use survivor::{
    adventurer::{Adventurer, ImplAdventurer, ItemPrimitive},
    constants::discovery_constants::{DiscoveryEnums::DiscoveryType, DiscoveryEnums::ExploreResult}
};
use lootitems::constants::ItemId;

#[generate_trait]
impl ExploreUtils of Explore {
    // @notice: generates a random discovery {Gold, Health, XP} based on provided entropy
    // @param entropy: Entropy to use for random discovery
    // @return DiscoveryType: The type of discovery
    fn get_random_discovery(entropy: u128) -> DiscoveryType {
        let discovery_type = entropy % 2;
        if (discovery_type == 0) {
            DiscoveryType::Gold(())
        } else {
            DiscoveryType::Health(())
        }
    }

    // @notice: generates a random discovery amount based on adventurer level and provided entropy
    // @dev: The range for discovery amoutn increases by 3 every 5 levels
    // @param adventurer_level: The level of the adventurer
    // @param entropy: The entropy seed to use for random discovery amount
    // @return u16: the amount of gold discovered
    fn get_base_discovery_amount(adventurer_level: u8, entropy: u128) -> u16 {
        let discovery_multiplier = adventurer_level / 5;
        let discovery_range: u128 = (discovery_multiplier.into() + 1) * 3;
        let discovery_amount = 1 + (entropy % discovery_range);
        discovery_amount.try_into().unwrap()
    }

    // @notice: generates a random gold discovery based on adventurer level and provided entropy
    // @param adventurer: Adventurer
    // @param entropy: The entropy seed to use for random discovery amount
    // @return u16: the amount of gold discovered
    fn get_gold_discovery(adventurer: Adventurer, entropy: u128) -> u16 {
        ExploreUtils::get_base_discovery_amount(adventurer.get_level(), entropy)
    }


    // @notice: generates a random health discovery based on adventurer level and provided entropy
    // @param adventurer: Adventurer
    // @param entropy: The entropy seed to use for random discovery amount
    // @return u16: the amount of health discovered
    fn get_health_discovery(adventurer: Adventurer, entropy: u128) -> u16 {
        ExploreUtils::get_base_discovery_amount(adventurer.get_level(), entropy)
    }

    // @notice: generates a random xp discovery based on adventurer level and provided entropy
    // @param adventurer: the Adventurer
    // @param entropy: The entropy seed to use for random discovery amount
    // @return u16: the amount of xp discovered
    fn get_xp_discovery(adventurer: Adventurer, entropy: u128) -> u16 {
        ExploreUtils::get_base_discovery_amount(adventurer.get_level(), entropy)
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use survivor::{
        exploration::ExploreUtils, adventurer::{ImplAdventurer, ItemPrimitive}, stats::Stats
    };
    use lootitems::constants::ItemId;

    #[test]
    #[available_gas(328654)]
    fn test_get_gold_discovery_gas() {
        let adventurer = ImplAdventurer::new(ItemId::Wand);
        let entropy = 0;
        ExploreUtils::get_gold_discovery(adventurer, entropy);
    }

    #[test]
    #[available_gas(329054)]
    fn test_get_gold_discovery() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // base discovery for level 1 adventurer with 0 entropy should be 1
        let entropy = 0;
        let gold_discovery = ExploreUtils::get_gold_discovery(adventurer, entropy);
        assert(gold_discovery == 1, 'gold_discovery should be 1');
    }

    #[test]
    #[available_gas(328854)]
    fn test_get_health_discovery_gas() {
        let adventurer = ImplAdventurer::new(ItemId::Wand);
        let entropy = 12345;
        ExploreUtils::get_health_discovery(adventurer, entropy);
    }

    #[test]
    #[available_gas(329054)]
    fn test_get_health_discovery() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // base discovery for level 1 adventurer with 0 entropy should be 1
        let entropy = 0;
        let discovery_amount = ExploreUtils::get_health_discovery(adventurer, entropy);
        assert(discovery_amount == 1, 'health discovery should be 1');
    }

    #[test]
    #[available_gas(24850)]
    fn test_get_base_discovery_amount_gas() {
        let level = 1;
        let entropy = 12345;
        let discovery_amount = ExploreUtils::get_base_discovery_amount(level, entropy);
    }

    #[test]
    #[available_gas(6980)]
    fn test_get_random_discovery_gas() {
        let entropy = 12345;
        ExploreUtils::get_random_discovery(entropy);
    }
}
