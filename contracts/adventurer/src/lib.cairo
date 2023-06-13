mod adventurer;
mod adventurer_meta;
mod item_meta;
// #[derive(Drop, Copy)]
// struct Item {
//     id: u8,
//     xp: u16,
//     prefix1: u8,
//     prefix2: u8,
//     suffix: u8,
//     isEquipped: bool,
// }

// #[derive(Drop, Copy)]
// struct Beast {
//     id: u8,
//     level: u16,
//     health: u16,
//     prefix1: u8,
//     prefix2: u8,
//     suffix: u8,
// }

// // @loaf notes
// // Adventurer ID is needed to determine everything
// // Random seed value should be set when Adventurer upgrades so the market can be deterministic off the seed

// // need to set the owner address at some point
// #[derive(Drop, Copy)]
// struct Adventurer {
//     Name: u64, // name
//     Health: u16, // health
//     XP: u32, // xp 
//     // Adventurers have 7 Stats
//     // 3 Physical
//     Strength: u8,
//     Dexterity: u8,
//     Vitality: u8,
//     // 3 Mental
//     Intelligence: u8,
//     Wisdom: u8,
//     Charisma: u8,
//     // 1 Meta Physical
//     Luck: u8,
//     // Adventurers can carry a maximum of 16 items
//     Item1: Item, // starter weapon (wand) 
//     Item2: Item, // first item purchased (katana)
//     Item3: Item, // second item purchased
//     Item4: Item, // third item purchased
//     Item5: Item,
//     Item6: Item,
//     Item7: Item,
//     Item8: Item,
//     Item9: Item,
//     Item10: Item,
//     Item11: Item,
//     Item12: Item,
//     Item13: Item,
//     Item14: Item,
//     Item15: Item,
//     Item16: Item,
//     // Adventurer in battle will have a beast assigned to them
//     Beast: Beast,
//     // Denotes if the adventurer has a stat 
//     stat_upgrade_available: bool,
// }

// trait AdventurerTrait {
//     fn get_new_adventurer(name: u64) -> Adventurer;
//     fn get_adventurer_level(xp: u32) -> u8;
//     fn add_beast(self: @Adventurer, beast: Beast) -> Adventurer;
//     fn remove_beast(self: @Adventurer) -> Adventurer;
//     fn get_weak_beast_for_weapon(weapon_type: u8) -> u8;
//     fn get_random_explore(rnd: u256) -> u8;
//     fn get_random_discovery(rnd: u256) -> u8;
//     fn calculate_gold_discovery(rnd: u256, adventurer_level: u16) -> u8;
//     fn calculate_health_discovery(rnd: u256) -> u8;
//     fn calculate_xp_discovery(rnd: u256, adventurer_level: u16) -> u8;
//     fn unequip_item(self: @Adventurer, slot: u8) -> Adventurer;
//     fn equip_item(self: @Adventurer, item: Item, slot: u8) -> Adventurer;
//     fn get_item_from_slot(self: @Adventurer, slot: u8) -> Item;
//     fn get_weapon(self: @Adventurer) -> Item;
//     fn get_weapon_type(item: Item) -> u8;
//     fn get_head_armor(self: @Adventurer) -> Item;
//     fn get_chest_armor(self: @Adventurer) -> Item;
//     fn get_waist_armor(self: @Adventurer) -> Item;
//     fn get_hand_armor(self: @Adventurer) -> Item;
//     fn get_foot_armor(self: @Adventurer) -> Item;
//     fn get_necklace(self: @Adventurer) -> Item;
//     fn get_ring(self: @Adventurer) -> Item;
//     fn get_item_id_at_slot(self: @Adventurer, slot: u8) -> u8;
//     fn is_jewelry(item: @Item) -> bool;
//     fn impacts_stat_modifier(item: @Item) -> bool;
//     fn remove_jewerly_stat_boost(self: @Adventurer, item: @Item) -> Adventurer;
//     fn add_jewerly_stat_boost(self: @Adventurer, item: @Item) -> Adventurer;
//     fn get_stat_for_item(self: @Adventurer, item: @Item) -> u8;
//     fn apply_non_jewlery_stat_modifier(self: @Adventurer, item: @Item, amount: u8) -> Adventurer;
//     fn remove_item_stat_modifier(self: @Adventurer, item: @Item) -> Adventurer;
//     fn apply_item_stat_modifier(self: @Adventurer, item: @Item) -> Adventurer;
//     fn increase_equipped_items_xp(self: @Adventurer, amount: u16) -> Adventurer;
//     fn create_beast(
//         adventurer_level: u8,
//         beast_id: u8,
//         level_boost: u16,
//         health_boost: u16,
//         name_prefix: u8,
//         name_suffix: u8
//     ) -> Beast;
//     fn create_starter_beast(weapon_type: u8) -> Beast;
//     fn calculate_gold_reward(beast_level: u8, beast_tier: u8) -> u16;
// }

// impl AdventurerImpl of AdventurerTrait {
//     fn get_new_adventurer(name: u64) -> Adventurer {
//         // Create an empty item
//         let empty_item = Item {
//             id: 0, xp: 0, prefix1: 0, prefix2: 0, suffix: 0, isEquipped: false, 
//         };

//         // Create an empty Beast
//         let empty_beast = Beast { id: 0, level: 0, health: 0, prefix1: 0, prefix2: 0, suffix: 0,  };

//         // return a new named adventurer with empty items and beast
//         return Adventurer {
//             Strength: 0,
//             Dexterity: 0,
//             Vitality: 0,
//             Intelligence: 0,
//             Wisdom: 0,
//             Charisma: 0,
//             Luck: 0,
//             Item1: empty_item,
//             Item2: empty_item,
//             Item3: empty_item,
//             Item4: empty_item,
//             Item5: empty_item,
//             Item6: empty_item,
//             Item7: empty_item,
//             Item8: empty_item,
//             Item9: empty_item,
//             Item10: empty_item,
//             Item11: empty_item,
//             Item12: empty_item,
//             Item13: empty_item,
//             Item14: empty_item,
//             Item15: empty_item,
//             Item16: empty_item,
//             Name: name,
//             Beast: empty_beast,
//             Health: 100,
//             XP: 0,
//             stat_upgrade_available: false,
//         };
//     }

//     // @notice Gets the adventurers current level based 
//     // @param xp The adventurer's current xp
//     // @return level The adventurer's current level
//     // TODO
//     fn get_adventurer_level(xp: u32) -> u8 {
//         return 0;
//     }

//     // @notice Adds a beast to the adventurer
//     // @param beast The beast to be added to the adventurer
//     // @param Adventurer The adventurer to add the beast to
//     // @return Adventurer The updated state of the adventurer after adding the beast
//     // TODO: Implement this
//     fn add_beast(self: @Adventurer, beast: Beast) -> Adventurer {
//         return Adventurer {
//             Strength: *self.Strength,
//             Dexterity: *self.Dexterity,
//             Vitality: *self.Vitality,
//             Intelligence: *self.Intelligence,
//             Wisdom: *self.Wisdom,
//             Charisma: *self.Charisma,
//             Luck: *self.Luck,
//             Item1: *self.Item1,
//             Item2: *self.Item2,
//             Item3: *self.Item3,
//             Item4: *self.Item4,
//             Item5: *self.Item5,
//             Item6: *self.Item6,
//             Item7: *self.Item7,
//             Item8: *self.Item8,
//             Item9: *self.Item9,
//             Item10: *self.Item10,
//             Item11: *self.Item11,
//             Item12: *self.Item12,
//             Item13: *self.Item13,
//             Item14: *self.Item14,
//             Item15: *self.Item15,
//             Item16: *self.Item16,
//             Name: *self.Name,
//             Beast: beast,
//             Health: *self.Health,
//             XP: *self.XP,
//             stat_upgrade_available: *self.stat_upgrade_available,
//         };
//     }

//     // @notice Removes a beast from the adventurer
//     // @param Adventurer The adventurer to remove the beast from
//     // @return Adventurer The updated state of the adventurer after removing the beast
//     fn remove_beast(self: @Adventurer) -> Adventurer {
//         // Create an empty beast
//         let empty_beast = Beast { id: 0, level: 0, health: 0, prefix1: 0, prefix2: 0, suffix: 0,  };

//         return Adventurer {
//             Strength: *self.Strength,
//             Dexterity: *self.Dexterity,
//             Vitality: *self.Vitality,
//             Intelligence: *self.Intelligence,
//             Wisdom: *self.Wisdom,
//             Charisma: *self.Charisma,
//             Luck: *self.Luck,
//             Item1: *self.Item1,
//             Item2: *self.Item2,
//             Item3: *self.Item3,
//             Item4: *self.Item4,
//             Item5: *self.Item5,
//             Item6: *self.Item6,
//             Item7: *self.Item7,
//             Item8: *self.Item8,
//             Item9: *self.Item9,
//             Item10: *self.Item10,
//             Item11: *self.Item11,
//             Item12: *self.Item12,
//             Item13: *self.Item13,
//             Item14: *self.Item14,
//             Item15: *self.Item15,
//             Item16: *self.Item16,
//             Name: *self.Name,
//             Beast: empty_beast,
//             Health: *self.Health,
//             XP: *self.XP,
//             stat_upgrade_available: *self.stat_upgrade_available,
//         };
//     }

//     // @notice gets a random outcome from exploring
//     // @param rnd The random number to be used to determine what the adventurer finds
//     // @return explore The outcome of the exploration
//     // TODO: Implement this
//     fn get_random_explore(rnd: u256) -> u8 {
//         // returning 0 for now
//         return 0;
//     }

//     // @notice Takes in a random number and returns what the adventurer finds {beast, obstacle, discovery}
//     // @param rnd The random number to be used to determine what the adventurer finds
//     // @return discovery The discovery the adventurer finds
//     // TODO: Implement this
//     fn get_random_discovery(rnd: u256) -> u8 {
//         // returning 0 for now
//         return 0;
//     }

//     // @notice Takes in a random number and returns a gold discovery
//     // @param rnd The random number to be used to determine what the adventurer finds
//     // @param adventurer_level The level of the adventurer
//     // @return discovery The discovery the adventurer finds
//     // TODO: Implement this
//     fn calculate_gold_discovery(rnd: u256, adventurer_level: u16) -> u8 {
//         // returning 0 for now
//         return 0;
//     }

//     // @notice Takes in a random number and returns a health discovery
//     // @param rnd The random number to be used to determine what the adventurer finds
//     // @param adventurer_level The level of the adventurer
//     // @return discovery The discovery the adventurer finds
//     // TODO: Implement this
//     fn calculate_health_discovery(rnd: u256) -> u8 {
//         // returning 0 for now
//         return 0;
//     }

//     // @notice Takes in a random number and returns a xp discovery
//     // @param rnd The random number to be used to determine what the adventurer finds
//     // @param adventurer_level The level of the adventurer
//     // @return discovery The discovery the adventurer finds
//     // TODO: Implement this
//     fn calculate_xp_discovery(rnd: u256, adventurer_level: u16) -> u8 {
//         // returning 0 for now
//         return 0;
//     }

//     // @notice gets the item from an adventurers item slot
//     // @param slot The slot to get the item from
//     // @return item The item in the slot
//     // TODO: Implement this
//     fn get_item_from_slot(self: @Adventurer, slot: u8) -> Item {
//         // just return an empty item for now
//         return Item { id: 0, xp: 0, prefix1: 0, prefix2: 0, suffix: 0, isEquipped: false };
//     }

//     // @notice equips an item to an adventurer
//     // @param id The item id to equip
//     // @param Adventurer The adventurer equipping the item
//     // @return new_unpacked_adventurer The updated state of the adventurer after equipping the item
//     // @dev this is going to be one of the more complex functions with our new model because
//     // we have very little information about the items in the Adventurer Struct
//     // In our Cairo 0 contracts we had a weaponId on the adventurer made it easy to 
//     // equip a new weapon because we could just swap the weaponId
//     // Now we have to do a lot more work to figure out what the item is and where it goes
//     // and if there is a current item in that slot we have to unequip it
//     // in the end, the gas savings will be worth it because we can update all items in one transaction
//     // TODO: Implement this
//     fn equip_item(self: @Adventurer, item: Item, slot: u8) -> Adventurer {
//         // just returning a copy of the adventurer for now
//         return *self;
//     }

//     // @notice unequips an item to an adventurer
//     // @param id The item id to unequip
//     // @param Adventurer The adventurer to unequip the item to
//     // @return new_unpacked_adventurer The updated state of the adventurer after equipping the item
//     // @dev this should be less complex than equip_item because we can blindly set the
//     // id for the provided slot to unequipped. When we are equipping we have to worry about
//     // a double equip situation but that is not possible when unequipping
//     fn unequip_item(self: @Adventurer, slot: u8) -> Adventurer {
//         // just returning pasesed in adventurer for now
//         return *self;
//     }

//     // @notice Retrieves the adventurers currently equipped weapon
//     // @param Adventurer The adventurer to retrieve the item from
//     // @return item The item at the weapon slot
//     // TODO: implement this function
//     fn get_weapon(self: @Adventurer) -> Item {
//         // just returning the first item for now
//         return *self.Item1;
//     }

//     // @notice return the type of weapon {blade, bludgeon, magic}
//     // @param item The item to get the type from
//     // @return weapon_type The type of weapon
//     // TODO: implement this function (need to pull in weapon ids)
//     fn get_weapon_type(item: Item) -> u8 {
//         // just returning 0 for now
//         return 0;
//     }

//     // @notice Retrieves the adventurers currently equipped head armor
//     // @param Adventurer The adventurer to retrieve the item from
//     // @return item The item at the head armor slot
//     // TODO: implement this function
//     fn get_head_armor(self: @Adventurer) -> Item {
//         // just returning the first item for now
//         return *self.Item1;
//     }

//     // @notice Retrieves the adventurers currently equipped chest armor
//     // @param Adventurer The adventurer to retrieve the item from
//     // @return item The item at the chest armor slot
//     // TODO: implement this function
//     fn get_chest_armor(self: @Adventurer) -> Item {
//         // just returning the first item for now
//         return *self.Item1;
//     }

//     // @notice Retrieves the adventurers currently equipped waist armor
//     // @param Adventurer The adventurer to retrieve the item from
//     // @return item The item at the waist armor slot
//     // TODO: implement this function
//     fn get_waist_armor(self: @Adventurer) -> Item {
//         // just returning the first item for now
//         return *self.Item1;
//     }

//     // @notice Retrieves the adventurers currently equipped hand armor
//     // @param Adventurer The adventurer to retrieve the item from
//     // @return item The item at the hand armor slot
//     // TODO: implement this function
//     fn get_hand_armor(self: @Adventurer) -> Item {
//         // just returning the first item for now
//         return *self.Item1;
//     }

//     // @notice Retrieves the adventurers currently equipped foot armor
//     // @param Adventurer The adventurer to retrieve the item from
//     // @return item The item at the foot armor slot
//     // TODO: implement this function
//     fn get_foot_armor(self: @Adventurer) -> Item {
//         // just returning the first item for now
//         return *self.Item1;
//     }

//     // @notice Retrieves the adventurers currently equipped necklace
//     // @param Adventurer The adventurer to retrieve the item from
//     // @return item The item at the necklace slot
//     // TODO: implement this function
//     fn get_necklace(self: @Adventurer) -> Item {
//         // just returning the first item for now
//         return *self.Item1;
//     }

//     // @notice Retrieves the adventurers currently equipped ring
//     // @param Adventurer The adventurer to retrieve the item from
//     // @return item The item at the ring slot
//     // TODO: implement this function
//     fn get_ring(self: @Adventurer) -> Item {
//         // just returning the first item for now
//         return *self.Item1;
//     }

//     // @notice Retrieves the item at a specific slot in the adventurer's equipment
//     // @param slot The slot to retrieve the item from
//     // @param Adventurer The adventurer to retrieve the item from
//     // @return item id The item id at the specified slot
//     // TODO: implement this function
//     fn get_item_id_at_slot(self: @Adventurer, slot: u8) -> u8 {
//         // just return 0 for now
//         return 0;
//     }

//     // @notice Checks if an item is jewelry
//     // @param item The item to be checked
//     // @return is_jewerly A boolean indicating whether the item is jewelry (TRUE) or not (FALSE)
//     // TODO: implement this function
//     fn is_jewelry(item: @Item) -> bool {
//         // just returning false for now
//         return false;
//     }

//     // @notice Checks if an item impacts the stat modifier
//     // @param item The item to be checked
//     // @return impacts_stat_modifier A boolean indicating whether the item impacts the stat modifier (TRUE) or not (FALSE)
//     // TODO: implement this function
//     fn impacts_stat_modifier(item: @Item) -> bool {
//         // just returning false for now
//         return false;
//     }

//     // @notice Removes the stat modifiers from jewelry items in the adventurer's state
//     // @param item The jewelry item to remove the stat modifiers from
//     // @param unpacked_adventurer The current state of the adventurer
//     // @return new_unpacked_adventurer The updated state of the adventurer after removing the jewelry stat modifiers
//     // TODO: implement this function
//     fn remove_jewerly_stat_boost(self: @Adventurer, item: @Item) -> Adventurer {
//         // just returning the adventurer for now
//         return *self;
//     }

//     // @notice Adds the stat modifiers from jewelry items in the adventurer's state
//     // @param item The jewelry item to add the stat modifiers from
//     // @param unpacked_adventurer The current state of the adventurer
//     // @return new_unpacked_adventurer The updated state of the adventurer after adding the jewelry stat modifiers
//     // TODO: implement this function
//     fn add_jewerly_stat_boost(self: @Adventurer, item: @Item) -> Adventurer {
//         // just returning the adventurer for now
//         return *self;
//     }

//     // @notice Retrieves the stat amount for a specific item suffix in the adventurer's state
//     // @param item The item to retrieve the stat amount for
//     // @param unpacked_adventurer The current state of the adventurer
//     // @return amount The amount of the specific stat associated with the item suffix
//     // TODO: implement this function
//     fn get_stat_for_item(self: @Adventurer, item: @Item) -> u8 {
//         // just returning 0 for now
//         return 0;
//     }

//     // @notice Updates the non-jewelry stat modifier in the adventurer's state based on the item suffix
//     // @param item The item to update the stat modifier for
//     // @param original_adventurer The original state of the adventurer
//     // @param amount The new amount of the stat modifier
//     // @return updated_adventurer The updated state of the adventurer after updating the non-jewelry stat modifier
//     // TODO: implement this function
//     fn apply_non_jewlery_stat_modifier(self: @Adventurer, item: @Item, amount: u8) -> Adventurer {
//         // just returning the adventurer for now
//         return *self;
//     }

//     // @notice Removes the stat modifier from the adventurer's state based on the item
//     // @param item The item to remove the stat modifier for
//     // @param original_adventurer The original state of the adventurer
//     // @return updated_adventurer The updated state of the adventurer after removing the item stat modifier
//     // TODO: implement this function
//     fn remove_item_stat_modifier(self: @Adventurer, item: @Item) -> Adventurer {
//         // just returning the adventurer for now
//         return *self;
//     }

//     // @notice Applies the stat modifier from the item to the adventurer's state
//     // @param item The item to apply the stat modifier for
//     // @param original_adventurer The original state of the adventurer
//     // @return updated_adventurer The updated state of the adventurer after applying the item stat modifier
//     // TODO: implement this function
//     fn apply_item_stat_modifier(self: @Adventurer, item: @Item) -> Adventurer {
//         // just returning the adventurer for now
//         return *self;
//     }

//     // @notice increase the xp of the adventurers equipped items
//     // @param amount The amount to increase the xp by
//     // @param Adventurer The adventurer to increase the xp for
//     // @return updated_adventurer The updated state of the adventurer after increasing the xp
//     fn increase_equipped_items_xp(self: @Adventurer, amount: u16) -> Adventurer {
//         // just returning the adventurer for now
//         return *self;
//     }
//     // ================================================================================================
//     // ================================================================================================

//     // ================================================================================================
//     // Functions from our Cairo 0 Adventurer Lib
//     // ================================================================================================

//     // @notice Creates a new beast
//     // @param adventurer_level The level of the active adventurer
//     // @param beast_id The id of the beast to create
//     // @param level_boost The level boost of the beast
//     // @param health_boost The health boost of the beast
//     // @param name_prefix The prefix of the beast's name
//     // @param name_suffix The suffix of the beast's name
//     // @return beast The newly created beast
//     // TODO: implement this function
//     fn create_beast(
//         adventurer_level: u8,
//         beast_id: u8,
//         level_boost: u16,
//         health_boost: u16,
//         name_prefix: u8,
//         name_suffix: u8
//     ) -> Beast {
//         // returning a simple beast for now
//         return Beast {
//             id: beast_id,
//             level: level_boost,
//             health: health_boost,
//             prefix1: name_prefix,
//             prefix2: name_suffix,
//             suffix: name_suffix
//         };
//     }

//     // @notice Gets a beast that is weak against the provided weapon type
//     // @param weapon_type The type of weapon the beast will be weak against
//     // @return beast_id The id of the beast that is weak against the provided weapon type
//     // TODO
//     fn get_weak_beast_for_weapon(weapon_type: u8) -> u8 {
//         // returning a simple beast for now
//         return 1;
//     }

//     // @notice Creates a starter beast which will have low stats and be weak against the provided weapon
//     // @param weapon_type The type of weapon the beast will be weak against
//     fn create_starter_beast(weapon_type: u8) -> Beast {
//         // get beast Id that is weak against the provided weapon type
//         // let beast_id = get_weak_beast_for_weapon(weapon_type);
//         let beast_id = 1;

//         // returning a simple beast for now
//         return Beast { id: beast_id, level: 1, health: 100, prefix1: 1, prefix2: 1, suffix: 1 };
//     }

//     // @notice calculates the reward from defeating a beast
//     // @param beast_level The level of the beast
//     // @param beast_tier The tier of the beast
//     // @return gold_reward The amount of gold the adventurer will receive for defeating the beast
//     // TODO: implement this function
//     fn calculate_gold_reward(beast_level: u8, beast_tier: u8) -> u16 {
//         // just returning 0 for now
//         return 0;
//     }
// }

// #[cfg(test)]
// mod tests {
//     use super::Item;
//     use super::Adventurer;
//     use super::AdventurerTrait;

//     // unit test for calculate_gold_reward function
//     #[test]
//     fn test_calculate_gold_reward() {
//         let beast_level = 10;
//         let beast_tier = 1;
//         let gold_reward = AdventurerTrait::calculate_gold_reward(beast_level, beast_tier);
//         assert(gold_reward == 50, 'gold reward should be 50');
//     }

//     // unit test for is_jewelry function
//     #[test]
//     fn test_is_jewelry() {
//         // create an item that is jewelry
//         let item = Item { id: 1, xp: 1, prefix1: 1, prefix2: 1, suffix: 1, isEquipped: true };
//         let is_jewelry = AdventurerTrait::is_jewelry(@item);
//         assert(is_jewelry == true, 'item should not be jewelry');
//     }

//     // unit test for get_new_adventurer function
//     #[test]
//     fn test_get_new_adventurer() {
//         let adventurer_name = 1;

//         // create a new adventurer
//         let adventurer = AdventurerTrait::get_new_adventurer(adventurer_name);
//         assert(adventurer.Health == 100, 'new advntr should have 100hp');
//         assert(adventurer.Name == adventurer_name, 'wrong name');
//         assert(adventurer.XP == 0, 'non zero xp');
//         assert(adventurer.Strength == 0, 'strength should be 0');
//         assert(adventurer.Dexterity == 0, 'dexerity should be 0');
//         assert(adventurer.Vitality == 0, 'Vitality should be 0');
//         assert(adventurer.Intelligence == 0, 'Intelligence should be 0');
//         assert(adventurer.Wisdom == 0, 'Wisdom should be 0');
//         assert(adventurer.Charisma == 0, 'Charisma should be 0');
//         assert(adventurer.Luck == 0, 'Luck should be 0');
//         assert(adventurer.Item1.id == 0, 'Item1 should be 0');
//         assert(adventurer.Item2.id == 0, 'Item2 should be 0');
//         assert(adventurer.Item3.id == 0, 'Item3 should be 0');
//         assert(adventurer.Item4.id == 0, 'Item4 should be 0');
//         assert(adventurer.Item5.id == 0, 'Item5 should be 0');
//         assert(adventurer.Item6.id == 0, 'Item6 should be 0');
//         assert(adventurer.Item7.id == 0, 'Item7 should be 0');
//         assert(adventurer.Item8.id == 0, 'Item8 should be 0');
//         assert(adventurer.Item9.id == 0, 'Item9 should be 0');
//         assert(adventurer.Item10.id == 0, 'Item10 should be 0');
//         assert(adventurer.Item11.id == 0, 'Item11 should be 0');
//         assert(adventurer.Item12.id == 0, 'Item12 should be 0');
//         assert(adventurer.Item13.id == 0, 'Item13 should be 0');
//         assert(adventurer.Item14.id == 0, 'Item14 should be 0');
//         assert(adventurer.Item15.id == 0, 'Item15 should be 0');
//         assert(adventurer.Item16.id == 0, 'Item16 should be 0');
//         assert(adventurer.Beast.id == 0, 'Beast should be 0');
//         assert(adventurer.stat_upgrade_available == false, 'should be no upgrade');
//     }

//     // unit test for get_adventurer_level function
//     #[test]
//     fn test_get_adventurer_level() {
//         let mut adventurer = AdventurerTrait::get_new_adventurer(1);
//         adventurer.XP = 0;
//         let adventurer_level = AdventurerTrait::get_adventurer_level(adventurer.XP);
//         assert(adventurer_level == 1, 'adventurer level should be 0');

//         adventurer.XP = 10;
//         assert(adventurer_level == 1, 'adventurer level should be 1');

//         adventurer.XP = 35;
//         assert(adventurer_level == 1, 'adventurer level should be 1');

//         adventurer.XP = 36;
//         assert(adventurer_level == 2, 'adventurer level should be 2');

//         adventurer.XP = 900;
//         assert(adventurer_level == 9, 'adventurer level should be 9');
//     }

//     // unit test for add_beast function
//     #[test]
//     fn test_add_beast() {
//         let mut adventurer = AdventurerTrait::get_new_adventurer(1);
//         let mut beast = AdventurerTrait::create_starter_beast(1);

//         AdventurerTrait::add_beast(@adventurer, beast);
//         assert(adventurer.Beast.id == 1, 'beast id should be 1');
//     }

//     // unit test for remove_beast function
//     #[test]
//     fn test_remove_beast() {
//         let mut adventurer = AdventurerTrait::get_new_adventurer(1);
//         let mut beast = AdventurerTrait::create_starter_beast(1);

//         AdventurerTrait::add_beast(@adventurer, beast);
//         assert(adventurer.Beast.id == 1, 'beast id should be 1');

//         AdventurerTrait::remove_beast(@adventurer);
//         assert(adventurer.Beast.id == 0, 'beast id should be 0');
//     }

//     // unit test for get_weapon_type function
//     #[test]
//     fn test_get_weapon_type() {
//         // Create a ghost wand which is type Weapon.magic = 103 in current contrtacts
//         let ghost_wand = Item { id: 9, xp: 1, prefix1: 1, prefix2: 1, suffix: 1, isEquipped: true };
//         let ghost_wand_type = AdventurerTrait::get_weapon_type(ghost_wand);
//         assert(ghost_wand_type == 103, 'ghost wand should be type 103');
//     }

//     // unit test for get_weak_beast_for_weapon function
//     #[test]
//     fn test_get_weak_beast_for_weapon() {
//         let mut beast = AdventurerTrait::create_starter_beast(1);
//         let club = Item { id: 76, xp: 1, prefix1: 1, prefix2: 1, suffix: 1, isEquipped: true };
//         let club_weapon_type = AdventurerTrait::get_weapon_type(club);

//         let mut weak_against_club_beast = AdventurerTrait::get_weak_beast_for_weapon(
//             club_weapon_type
//         );
//         let rat_id = 20;

//         assert(weak_against_club_beast == rat_id, 'rat is weak against club');
//     }

//     // unit test for get_random_explore function
//     #[test]
//     fn test_get_random_explore() {}

//     // unit test for get_random_discovery function
//     #[test]
//     fn test_get_random_discovery() {}

//     // unit test for calculate_gold_discovery function
//     #[test]
//     fn test_calculate_gold_discovery() {
//         let gold_discovery = AdventurerTrait::calculate_gold_discovery(1, 1);
//         assert(gold_discovery == 2, 'gold discovery should be 2');
//     }

//     // unit test for calculate_health_discovery function
//     #[test]
//     fn test_calculate_health_discovery() {
//         let health_discovery = AdventurerTrait::calculate_health_discovery(0);
//         assert(health_discovery == 10, 'health discovery should be 10');
//     }

//     // unit test for calculate_xp_discovery function
//     #[test]
//     fn test_calculate_xp_discovery() {
//         let xp_discovery = AdventurerTrait::calculate_xp_discovery(0, 1);
//         assert(xp_discovery == 1, 'xp discovery should be 1');
//     }

//     // unit test for equip_item function
//     #[test]
//     fn test_equip_item() {
//         let mut adventurer = AdventurerTrait::get_new_adventurer(1);
//         let mut divine_slippers = Item {
//             id: 32, xp: 1, prefix1: 1, prefix2: 1, suffix: 1, isEquipped: false
//         };
//         adventurer.Item1 = divine_slippers;

//         AdventurerTrait::equip_item(@adventurer, divine_slippers, 1);
//         assert(adventurer.Item1.isEquipped == true, 'item should be equipped');
//     }

//     // unit test for unequip_item function
//     #[test]
//     fn test_unequip_item() {
//         let mut adventurer = AdventurerTrait::get_new_adventurer(1);
//         let mut divine_slippers = Item {
//             id: 32, xp: 1, prefix1: 1, prefix2: 1, suffix: 1, isEquipped: false
//         };
//         adventurer.Item1 = divine_slippers;

//         AdventurerTrait::equip_item(@adventurer, divine_slippers, 1);
//         assert(adventurer.Item1.isEquipped == true, 'item should be equipped');

//         AdventurerTrait::unequip_item(@adventurer, 1);
//         assert(adventurer.Item1.isEquipped == false, 'item should be unequipped');
//     }

//     // unit test for get_item_from_slot function
//     #[test]
//     fn test_get_item_from_slot() {
//         let mut adventurer = AdventurerTrait::get_new_adventurer(1);
//         let mut divine_slippers = Item {
//             id: 32, xp: 1, prefix1: 1, prefix2: 1, suffix: 1, isEquipped: false
//         };
//         adventurer.Item1 = divine_slippers;

//         let item_from_slot = AdventurerTrait::get_item_from_slot(@adventurer, 1);
//         assert(item_from_slot.id == 32, 'item id should be 32');
//     }
// }


