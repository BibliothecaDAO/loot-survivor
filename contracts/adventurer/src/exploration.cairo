use core::option::OptionTrait;
use core::traits::{Into, TryInto};

use survivor::{
    adventurer::{Adventurer, ImplAdventurer, ItemPrimitive},
    constants::discovery_constants::{
        DiscoveryEnums::TreasureDiscovery, DiscoveryEnums::ExploreResult
    }
};
use lootitems::statistics::constants::ItemId;

#[generate_trait]
impl ExploreUtils of Explore {
    // @notice: generates a random discovery {Gold, Health, XP} based on provided entropy
    // @param entropy: Entropy to use for random discovery
    // @return TreasureDiscovery: The type of discovery
    fn get_random_discovery(entropy: u128) -> TreasureDiscovery {
        let discovery_type = entropy % 3;
        if (discovery_type == 0) {
            TreasureDiscovery::Gold(())
        } else if (discovery_type == 1) {
            TreasureDiscovery::Health(())
        } else {
            TreasureDiscovery::XP(())
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
        let base_gold = ExploreUtils::get_base_discovery_amount(adventurer.get_level(), entropy);
        if adventurer.double_gold_discovery_unlocked() {
            base_gold * 2
        } else {
            base_gold
        }
    }


    // @notice: generates a random health discovery based on adventurer level and provided entropy
    // @param adventurer: Adventurer
    // @param entropy: The entropy seed to use for random discovery amount
    // @return u16: the amount of health discovered
    fn get_health_discovery(adventurer: Adventurer, entropy: u128) -> u16 {
        let base_health = ExploreUtils::get_base_discovery_amount(adventurer.get_level(), entropy);
        if adventurer.double_health_discovery_unlocked() {
            base_health * 2
        } else {
            base_health
        }
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
        exploration::ExploreUtils, adventurer::{ImplAdventurer, ItemPrimitive},
        adventurer_stats::Stats
    };
    use lootitems::statistics::constants::ItemId;

    #[test]
    #[available_gas(69690)]
    fn test_get_gold_discovery_gas() {
        let adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );
        let entropy = 0;
        ExploreUtils::get_gold_discovery(adventurer, entropy);
    }

    #[test]
    #[available_gas(509690)]
    fn test_get_gold_discovery() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        // base discovery for level 1 adventurer with 0 entropy should be 1
        let entropy = 0;
        let gold_discovery = ExploreUtils::get_gold_discovery(adventurer, entropy);
        assert(gold_discovery == 1, 'gold_discovery should be 1');

        // equip an amulet and verify result doesn't change
        adventurer.neck = ItemPrimitive { id: ItemId::Amulet, xp: 400, metadata: 1 };
        let gold_discovery = ExploreUtils::get_gold_discovery(adventurer, entropy);
        assert(gold_discovery == 1, 'gold_discovery should be 1');

        // equip a pendant and verify we get 2x gold
        adventurer.neck = ItemPrimitive { id: ItemId::Pendant, xp: 400, metadata: 2 };
        let gold_discovery = ExploreUtils::get_gold_discovery(adventurer, entropy);
        assert(gold_discovery == 2, 'gold_discovery should be 2');
    }

    #[test]
    #[available_gas(61690)]
    fn test_get_health_discovery_gas() {
        let adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );
        let entropy = 12345;
        ExploreUtils::get_health_discovery(adventurer, entropy);
    }

    #[test]
    #[available_gas(509690)]
    fn test_get_health_discovery() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        // base discovery for level 1 adventurer with 0 entropy should be 1
        let entropy = 0;
        let discovery_amount = ExploreUtils::get_health_discovery(adventurer, entropy);
        assert(discovery_amount == 1, 'health discovery should be 1');

        // equip a pendant and verify result doesn't change
        adventurer.neck = ItemPrimitive { id: ItemId::Pendant, xp: 400, metadata: 1 };
        let discovery_amount = ExploreUtils::get_health_discovery(adventurer, entropy);
        assert(discovery_amount == 1, 'health discovery should be 1');

        // last we equip a necklace and verify result is doubled
        adventurer.neck = ItemPrimitive { id: ItemId::Necklace, xp: 400, metadata: 1 };
        let discovery_amount = ExploreUtils::get_health_discovery(adventurer, entropy);
        assert(discovery_amount == 1, 'health discovery should be 1');

        // equip an amulet and verify result doesn't change
        adventurer.neck = ItemPrimitive { id: ItemId::Amulet, xp: 400, metadata: 1 };
        let discovery_amount = ExploreUtils::get_health_discovery(adventurer, entropy);
        assert(discovery_amount == 2, 'double discovery fail');
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
