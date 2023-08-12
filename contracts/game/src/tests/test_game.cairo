#[cfg(test)]
mod tests {
    use array::ArrayTrait;
    use core::{result::ResultTrait, traits::Into, array::SpanTrait, serde::Serde, clone::Clone};
    use option::OptionTrait;
    use starknet::{
        syscalls::deploy_syscall, testing, ContractAddress, ContractAddressIntoFelt252,
        contract_address_const
    };
    use traits::TryInto;
    use box::BoxTrait;

    use market::market::{ImplMarket, LootWithPrice, ItemPurchase};
    use lootitems::{loot::{Loot, ImplLoot, ILoot}, statistics::constants::{ItemId}};
    use game::{
        Game,
        game::{
            interfaces::{IGameDispatcherTrait, IGameDispatcher},
            constants::{messages::{STAT_UPGRADES_AVAILABLE}, STARTER_BEAST_ATTACK_DAMAGE}
        }
    };
    use combat::{constants::CombatEnums::{Slot, Tier}, combat::ImplCombat};
    use survivor::{
        adventurer_stats::Stats, adventurer_meta::{AdventurerMetadata},
        constants::adventurer_constants::{
            STARTING_GOLD, POTION_HEALTH_AMOUNT, POTION_PRICE, STARTING_HEALTH, ClassStatBoosts,
            MAX_BLOCK_COUNT
        },
        adventurer::{Adventurer, ImplAdventurer, IAdventurer}, item_primitive::ItemPrimitive,
        bag::{Bag, IBag}
    };
    use beasts::constants::{BeastSettings, BeastId};

    fn INTERFACE_ID() -> ContractAddress {
        contract_address_const::<1>()
    }

    fn DAO() -> ContractAddress {
        contract_address_const::<1>()
    }

    fn CALLER() -> ContractAddress {
        contract_address_const::<0x1>()
    }

    const ADVENTURER_ID: u256 = 1;
    const MAX_LORDS: felt252 = 500000000000000000000;

    fn setup() -> IGameDispatcher {
        testing::set_block_number(1000);

        let mut calldata = ArrayTrait::new();
        calldata.append(DAO().into());
        calldata.append(DAO().into());

        let (address0, _) = deploy_syscall(
            Game::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();

        IGameDispatcher { contract_address: address0 }
    }

    fn new_adventurer() -> IGameDispatcher {
        let mut game = setup();

        let adventurer_meta = AdventurerMetadata {
            name: 'Loaf'.try_into().unwrap(), home_realm: 1, class: 1, entropy: 1
        };

        let starting_stats = Stats {
            strength: 0, dexterity: 2, vitality: 0, intelligence: 2, wisdom: 2, charisma: 0, 
        };

        game.start(INTERFACE_ID(), ItemId::Wand, adventurer_meta, starting_stats);

        let original_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(original_adventurer.xp == 0, 'wrong starting xp');
        assert(
            original_adventurer.health == STARTING_HEALTH - STARTER_BEAST_ATTACK_DAMAGE,
            'wrong starting health'
        );
        assert(original_adventurer.weapon.id == ItemId::Wand, 'wrong starting weapon');
        assert(
            original_adventurer.beast_health == BeastSettings::STARTER_BEAST_HEALTH,
            'wrong starter beast health '
        );

        game
    }

    fn new_adventurer_max_charisma() -> IGameDispatcher {
        let mut game = setup();
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 6, 
        };

        game
            .start(
                INTERFACE_ID(),
                ItemId::Wand,
                AdventurerMetadata {
                    name: 'loothero'.try_into().unwrap(), home_realm: 1, class: 1, entropy: 1
                },
                starting_stats
            );

        game
    }

    fn new_adventurer_max_charisma_level2() -> IGameDispatcher {
        // start game
        let mut game = new_adventurer_max_charisma();

        // attack starter beast
        game.attack(ADVENTURER_ID, false);

        // assert starter beast is dead
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.beast_health == 0, 'should not be in battle');
        assert(adventurer.get_level() == 2, 'should be level 2');
        assert(adventurer.stat_points_available == 1, 'should have 1 stat available');

        // return game
        game
    }

    fn new_adventurer_lvl2_with_idle_penalty() -> IGameDispatcher {
        // start game on block number 1
        testing::set_block_number(1);
        let mut game = new_adventurer();

        // fast forward chain to block number 400
        testing::set_block_number(400);

        // double attack beast
        // this will trigger idle penalty which will deal extra
        // damage to adventurer
        game.attack(ADVENTURER_ID, false);
        game.attack(ADVENTURER_ID, false);

        // assert starter beast is dead
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.beast_health == 0, 'should not be in battle');

        // return game
        game
    }

    fn new_adventurer_lvl2() -> IGameDispatcher {
        // start game
        let mut game = new_adventurer();

        // attack starter beast
        game.attack(ADVENTURER_ID, false);

        // assert starter beast is dead
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.beast_health == 0, 'should not be in battle');
        assert(adventurer.get_level() == 2, 'should be level 2');
        assert(adventurer.stat_points_available == 1, 'should have 1 stat available');

        // return game
        game
    }

    fn new_adventurer_lvl3(stat: u8) -> IGameDispatcher {
        // start game on lvl 2
        let mut game = new_adventurer_lvl2();

        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // go explore
        game.explore(ADVENTURER_ID, true);
        game.flee(ADVENTURER_ID, false);
        game.explore(ADVENTURER_ID, true);
        game.flee(ADVENTURER_ID, false);
        game.explore(ADVENTURER_ID, true);
        game.flee(ADVENTURER_ID, false);
        game.explore(ADVENTURER_ID, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 3, 'adventurer should be lvl 3');

        // return game
        game
    }

    fn new_adventurer_lvl4(stat: u8) -> IGameDispatcher {
        // start game on lvl 2
        let mut game = new_adventurer_lvl3(stat);

        // upgrade charisma
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // go explore
        game.explore(ADVENTURER_ID, true);
        game.flee(ADVENTURER_ID, false);
        game.explore(ADVENTURER_ID, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 4, 'adventurer should be lvl 4');

        // return game
        game
    }

    fn new_adventurer_lvl5(stat: u8) -> IGameDispatcher {
        // start game on lvl 2
        let mut game = new_adventurer_lvl4(stat);

        // upgrade charisma
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // go explore
        game.explore(ADVENTURER_ID, true);
        game.explore(ADVENTURER_ID, true);
        game.flee(ADVENTURER_ID, false);
        game.explore(ADVENTURER_ID, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 5, 'adventurer should be lvl 5');

        // return game
        game
    }

    fn new_adventurer_lvl6_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl5(stat);
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        let weapon_inventory = @game.get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Weapon(())));
        let chest_inventory = @game.get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Chest(())));
        let head_inventory = @game.get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Head(())));
        let waist_inventory = @game.get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Waist(())));
        let foot_inventory = @game.get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Foot(())));
        let hand_inventory = @game.get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Hand(())));

        let purchase_weapon_id = *weapon_inventory.at(0);
        let purchase_chest_id = *chest_inventory.at(2);
        let purchase_head_id = *head_inventory.at(2);
        let purchase_waist_id = *waist_inventory.at(0);
        let purchase_foot_id = *foot_inventory.at(0);
        let purchase_hand_id = *hand_inventory.at(0);

        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: purchase_weapon_id, equip: true });
        shopping_cart.append(ItemPurchase { item_id: purchase_chest_id, equip: true });
        shopping_cart.append(ItemPurchase { item_id: purchase_head_id, equip: true });
        shopping_cart.append(ItemPurchase { item_id: purchase_waist_id, equip: true });
        shopping_cart.append(ItemPurchase { item_id: purchase_foot_id, equip: true });
        shopping_cart.append(ItemPurchase { item_id: purchase_hand_id, equip: true });

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.weapon.id == purchase_weapon_id, 'new weapon should be equipped');
        assert(adventurer.chest.id == purchase_chest_id, 'new chest should be equipped');
        assert(adventurer.head.id == purchase_head_id, 'new head should be equipped');
        assert(adventurer.waist.id == purchase_waist_id, 'new waist should be equipped');
        assert(adventurer.foot.id == purchase_foot_id, 'new foot should be equipped');
        assert(adventurer.hand.id == purchase_hand_id, 'new hand should be equipped');
        assert(adventurer.gold < STARTING_GOLD, 'items should not be free');

        // upgrade stats
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // go explore
        game.explore(ADVENTURER_ID, true);

        // verify adventurer is now level 6
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 6, 'adventurer should be lvl 6');

        game
    }

    fn new_adventurer_lvl7_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl6_equipped(stat);
        let STRENGTH: u8 = 0;
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // go explore
        game.explore(ADVENTURER_ID, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 7, 'adventurer should be lvl 7');

        game
    }

    fn new_adventurer_lvl8_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl7_equipped(stat);
        let STRENGTH: u8 = 0;
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // go explore
        game.explore(ADVENTURER_ID, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 8, 'adventurer should be lvl 8');

        game
    }

    fn new_adventurer_lvl9_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl8_equipped(stat);
        let STRENGTH: u8 = 0;
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // go explore
        game.explore(ADVENTURER_ID, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 9, 'adventurer should be lvl 9');

        game
    }

    fn new_adventurer_lvl10_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl9_equipped(stat);
        let STRENGTH: u8 = 0;
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // go explore
        game.explore(ADVENTURER_ID, true);
        game.flee(ADVENTURER_ID, false);
        game.explore(ADVENTURER_ID, true);
        game.explore(ADVENTURER_ID, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 10, 'adventurer should be lvl 10');

        game
    }

    fn new_adventurer_lvl11_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl10_equipped(stat);
        let STRENGTH: u8 = 0;
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // go explore
        game.explore(ADVENTURER_ID, true);
        game.explore(ADVENTURER_ID, true);
        game.explore(ADVENTURER_ID, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 11, 'adventurer should be lvl 11');

        game
    }

    // TODO: need to figure out how to make this more durable
    // #[test]
    // #[available_gas(3000000000000)]
    // fn test_full_game() {
    //     let mut game = new_adventurer_lvl11_equipped(5);
    // }

    #[test]
    #[available_gas(3000000000000)]
    fn test_start() {
        let mut game = new_adventurer();

        let adventurer_1 = game.get_adventurer(ADVENTURER_ID);
        let adventurer_meta_1 = game.get_adventurer_meta(ADVENTURER_ID);

        // check adventurer
        assert(adventurer_1.weapon.id == ItemId::Wand, 'weapon');
        assert(adventurer_1.beast_health > 0, 'beast_health');

        // check meta
        assert(adventurer_meta_1.name == 'Loaf', 'name');
        assert(adventurer_meta_1.home_realm == 1, 'home_realm');
        assert(adventurer_meta_1.class == 1, 'class');

        adventurer_meta_1.entropy;
    }

    #[test]
    #[should_panic(expected: ('Action not allowed in battle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(38000000)]
    fn test_no_explore_during_battle() {
        let mut game = new_adventurer();

        // try to explore before defeating start beast
        // should result in a panic 'In battle cannot explore' which
        // is annotated in the test
        game.explore(ADVENTURER_ID, true);
    }

    #[test]
    #[should_panic]
    #[available_gas(900000)]
    fn test_attack() {
        let mut game = new_adventurer();

        testing::set_block_number(1002);

        let adventurer_start = game.get_adventurer(ADVENTURER_ID);

        // verify starting state
        assert(adventurer_start.health == 100, 'advtr should start with 100hp');
        assert(adventurer_start.xp == 0, 'advtr should start with 0xp');
        assert(
            adventurer_start.beast_health == BeastSettings::STARTER_BEAST_HEALTH,
            'wrong beast starting health'
        );

        // attack beast
        game.attack(ADVENTURER_ID, false);

        // verify beast and adventurer took damage
        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            updated_adventurer.beast_health < adventurer_start.beast_health,
            'beast should have taken dmg'
        );

        // if the beast was killed in one hit
        if (updated_adventurer.beast_health == 0) {
            // verify adventurer received xp and gold
            assert(updated_adventurer.xp > adventurer_start.xp, 'advntr should gain xp');
            assert(updated_adventurer.gold > adventurer_start.gold, 'adventuer should gain gold');
            // and adventurer was untouched
            assert(updated_adventurer.health == 100, 'no dmg from 1 hit tko');

            // attack again after the beast is dead which should
            // result in a panic. This test is annotated to expect a panic
            // so if it doesn't, this test will fail
            game.attack(ADVENTURER_ID, false);
        } // if the beast was not killed in one hit
        else {
            assert(updated_adventurer.xp == adventurer_start.xp, 'should have same xp');
            assert(updated_adventurer.gold == adventurer_start.gold, 'should have same gold');
            assert(updated_adventurer.health != 100, 'should have taken dmg');

            // attack again (will take out starter beast with current settings regardless of critical hit)
            game.attack(ADVENTURER_ID, false);

            // recheck adventurer stats
            let updated_adventurer = game.get_adventurer(ADVENTURER_ID);
            assert(updated_adventurer.beast_health == 0, 'beast should be dead');
            assert(updated_adventurer.xp > adventurer_start.xp, 'should have same xp');
            assert(updated_adventurer.gold > adventurer_start.gold, 'should have same gold');

            // attack again after the beast is dead which should
            // result in a panic. This test is annotated to expect a panic
            // so if it doesn't, this test will fail
            game.attack(ADVENTURER_ID, false);
        }
    }

    #[test]
    #[should_panic(expected: ('Cant flee starter beast', 'ENTRYPOINT_FAILED'))]
    #[available_gas(25000000)]
    fn test_cant_flee_starter_beast() {
        // start new game
        let mut game = new_adventurer();

        // immediately attempt to flee starter beast
        // which is not allowed and should result in a panic 'Cant flee starter beast'
        // which is annotated in the test
        game.flee(ADVENTURER_ID, false);
    }

    #[test]
    #[should_panic(expected: ('Not in battle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(65000000)]
    fn test_cant_flee_outside_battle() {
        // start adventuer and advance to level 2
        let mut game = new_adventurer_lvl2();

        // attempt to flee despite not being in a battle
        // this should trigger a panic 'Not in battle' which is
        // annotated in the test
        game.flee(ADVENTURER_ID, false);
    }

    #[test]
    #[available_gas(15000000000)]
    fn test_flee() {
        let mut game = new_adventurer_lvl2();

        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(updated_adventurer.beast_health == 0, 'beast should be dead');

        // explore till we find a beast
        // TODO: use cheat codes to make this less fragile
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart.clone());

        testing::set_block_number(1006);
        game.explore(ADVENTURER_ID, true);
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart.clone());
        testing::set_block_number(1007);
        game.explore(ADVENTURER_ID, true);


        // verify we found a beast
        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(updated_adventurer.beast_health > 0, 'should have found a beast');

        // flee from beast
        game.flee(ADVENTURER_ID, false);
        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(updated_adventurer.beast_health == 0, 'should have fled beast');
    }

    #[test]
    #[should_panic(expected: ('Stat upgrade available', 'ENTRYPOINT_FAILED'))]
    #[available_gas(8000000000)]
    fn test_explore_not_allowed_with_avail_stat_upgrade() {
        let mut game = new_adventurer();

        // take out starter beast
        game.attack(ADVENTURER_ID, false);

        // get updated adventurer
        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);

        // assert adventurer is now level 2 and has 1 stat upgrade available
        assert(updated_adventurer.get_level() == 2, 'advntr should be lvl 2');
        assert(updated_adventurer.stat_points_available == 1, 'advntr should have 1 stat avl');

        // verify adventurer is unable to explore with stat upgrade available
        // this test is annotated to expect a panic so if it doesn't, this test will fail
        game.explore(ADVENTURER_ID, true);
    }

    #[test]
    #[should_panic(expected: ('Market is closed', 'ENTRYPOINT_FAILED'))]
    #[available_gas(1800000000)]
    fn test_buy_items_during_battle() {
        // mint new adventurer (will start in battle with starter beast)
        let mut game = new_adventurer();

        // get valid item from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);
        let item_id = *market_items.at(0).item.id;
        let item_price = *market_items.at(0).price.into();

        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: true });

        // attempt to buy item during battle - should_panic with message 'Action not allowed in battle'
        // this test is annotated to expect a panic so if it doesn't, this test will fail
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);
    }

    #[test]
    #[should_panic(expected: ('Market is closed', 'ENTRYPOINT_FAILED'))]
    #[available_gas(85000000)]
    fn test_buy_items_without_stat_upgrade() {
        // mint adventurer and advance to level 2
        let mut game = new_adventurer_lvl2();

        // get valid item from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);
        let item_id = *market_items.at(0).item.id;
        let mut shoppping_cart = ArrayTrait::<ItemPurchase>::new();

        shoppping_cart.append(ItemPurchase { item_id: item_id, equip: true });

        // upgrade adventurer and don't buy anything
        let mut empty_shoppping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, empty_shoppping_cart);

        // after upgrade try to buy item
        // should panic with message 'Market is closed'
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shoppping_cart);
    }

    #[test]
    #[should_panic(expected: ('Item already owned', 'ENTRYPOINT_FAILED'))]
    #[available_gas(80000000)]
    fn test_buy_duplicate_item_equipped() {
        // start new game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2();

        // get items from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);

        // get first item on the market
        let item_id = *market_items.at(0).item.id;
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: true });
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: true });

        // submit an upgrade with duplicate items in the shopping cart
        // 'Item already owned' which is annotated in the test
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);
    }

    #[test]
    #[should_panic(expected: ('Item already owned', 'ENTRYPOINT_FAILED'))]
    #[available_gas(80000000)]
    fn test_buy_duplicate_item_bagged() {
        // start new game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2();

        // get items from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);

        // try to buy same item but equip one and put one in bag
        let item_id = *market_items.at(0).item.id;
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: true });

        // should throw 'Item already owned' panic
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);
    }

    #[test]
    #[should_panic(expected: ('Market item does not exist', 'ENTRYPOINT_FAILED'))]
    #[available_gas(65000000)]
    fn test_buy_item_not_on_market() {
        let mut game = new_adventurer_lvl2();
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: 255, equip: false });
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);
    }

    #[test]
    #[available_gas(75000000)]
    fn test_buy_and_bag_item() {
        let mut game = new_adventurer_lvl2();
        let market_items = @game.get_items_on_market(ADVENTURER_ID);
        let item_id = *market_items.at(0).item.id;
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);
        let bag = game.get_bag(ADVENTURER_ID);
        assert(bag.item_1.id == *market_items.at(0).item.id, 'item should be in bag');
    }

    #[test]
    #[available_gas(80000000)]
    fn test_buy_items() {
        // start game on level 2 so we have access to the market
        let mut game = new_adventurer_max_charisma_level2();

        // get items from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);

        let mut purchased_weapon: u8 = 0;
        let mut purchased_chest: u8 = 0;
        let mut purchased_head: u8 = 0;
        let mut purchased_waist: u8 = 0;
        let mut purchased_foot: u8 = 0;
        let mut purchased_hand: u8 = 0;
        let mut purchased_ring: u8 = 0;
        let mut purchased_necklace: u8 = 0;
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();

        let mut i: u32 = 0;
        loop {
            if i >= market_items.len() {
                break ();
            }
            let market_item = *market_items.at(i).item;

            if (market_item.tier != Tier::T5(()) && market_item.tier != Tier::T4(())) {
                i += 1;
                continue;
            }

            // if the item is a weapon and we haven't purchased a weapon yet
            // and the item is a tier 4 or 5 item
            // repeat this for everything
            if (market_item.slot == Slot::Weapon(())
                && purchased_weapon == 0
                && market_item.id != 12) {
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: true });
                purchased_weapon = market_item.id;
            } else if (market_item.slot == Slot::Chest(()) && purchased_chest == 0) {
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: true });
                purchased_chest = market_item.id;
            } else if (market_item.slot == Slot::Head(()) && purchased_head == 0) {
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: true });
                purchased_head = market_item.id;
            } else if (market_item.slot == Slot::Waist(()) && purchased_waist == 0) {
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
                purchased_waist = market_item.id;
            } else if (market_item.slot == Slot::Foot(()) && purchased_foot == 0) {
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
                purchased_foot = market_item.id;
            } else if (market_item.slot == Slot::Hand(()) && purchased_hand == 0) {
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
                purchased_hand = market_item.id;
            }
            i += 1;
        };

        // verify we have at least two items in shopping cart
        let shopping_cart_length = shopping_cart.len();
        assert(shopping_cart_length > 1, 'need more items to equip');

        // buy items in shopping cart
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart.clone());

        // get updated adventurer and bag state
        let bag = game.get_bag(ADVENTURER_ID);
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        let mut buy_and_equip_tested = false;
        let mut buy_and_bagged_tested = false;

        let mut items_to_equip = ArrayTrait::<u8>::new();
        // iterate over the items we bought
        let mut i: u32 = 0;
        loop {
            if i >= shopping_cart.len() {
                break ();
            }
            let item_purchase = *shopping_cart.at(i);

            // if the item was purchased with equip flag set to true
            if item_purchase.equip {
                // assert it's equipped
                assert(adventurer.is_equipped(item_purchase.item_id), 'item not equipped');
                buy_and_equip_tested = true;
            } else {
                // if equip was false, verify item is in bag
                assert(bag.contains(item_purchase.item_id), 'item not in bag');
                buy_and_bagged_tested = true;
            }
            i += 1;
        };

        assert(buy_and_equip_tested, 'did not test buy and equip');
        assert(buy_and_bagged_tested, 'did not test buy and bag');
    }

    #[test]
    #[should_panic(expected: ('Item not in bag', 'ENTRYPOINT_FAILED'))]
    #[available_gas(26000000)]
    fn test_equip_not_in_bag() {
        // start new game
        let mut game = new_adventurer();

        // initialize an array of items to equip that contains an item not in bag
        let mut items_to_equip = ArrayTrait::<u8>::new();
        items_to_equip.append(1);

        // try to equip the item which is not in bag
        // this should result in a panic 'Item not in bag' which is
        // annotated in the test
        game.equip(ADVENTURER_ID, items_to_equip);
    }

    #[test]
    #[should_panic(expected: ('Too many items', 'ENTRYPOINT_FAILED'))]
    #[available_gas(26000000)]
    fn test_equip_too_many_items() {
        // start new game
        let mut game = new_adventurer();

        // initialize an array of 9 items (too many to equip)
        let mut items_to_equip = ArrayTrait::<u8>::new();
        items_to_equip.append(1);
        items_to_equip.append(2);
        items_to_equip.append(3);
        items_to_equip.append(4);
        items_to_equip.append(5);
        items_to_equip.append(6);
        items_to_equip.append(7);
        items_to_equip.append(8);
        items_to_equip.append(9);

        // try to equip the 9 items
        // this should result in a panic 'Too many items' which is
        // annotated in the test
        game.equip(ADVENTURER_ID, items_to_equip);
    }

    #[test]
    #[available_gas(130000000)]
    fn test_equip() {
        // start game on level 2 so we have access to the market
        let mut game = new_adventurer_max_charisma_level2();

        // get items from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);

        // get first item on the market
        let item_id = *market_items.at(0).item.id;

        let mut purchased_weapon: u8 = 0;
        let mut purchased_chest: u8 = 0;
        let mut purchased_head: u8 = 0;
        let mut purchased_waist: u8 = 0;
        let mut purchased_foot: u8 = 0;
        let mut purchased_hand: u8 = 0;
        let mut purchased_ring: u8 = 0;
        let mut purchased_necklace: u8 = 0;
        let mut purchased_items = ArrayTrait::<Loot>::new();
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();

        let mut i: u32 = 0;
        loop {
            if i >= market_items.len() {
                break ();
            }
            let market_item = *market_items.at(i).item;

            // if the item is a weapon and we haven't purchased a weapon yet
            // and the item is a tier 4 or 5 item
            // repeat this for everything
            if (market_item.slot == Slot::Weapon(())
                && purchased_weapon == 0
                && (market_item.tier == Tier::T5(()))
                && market_item.id != 12) {
                purchased_items.append(market_item);
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
                purchased_weapon = market_item.id;
            } else if (market_item.slot == Slot::Chest(())
                && purchased_chest == 0
                && market_item.tier == Tier::T5(())) {
                purchased_items.append(market_item);
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
                purchased_chest = market_item.id;
            } else if (market_item.slot == Slot::Head(())
                && purchased_head == 0
                && market_item.tier == Tier::T5(())) {
                purchased_items.append(market_item);
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
                purchased_head = market_item.id;
            } else if (market_item.slot == Slot::Waist(())
                && purchased_waist == 0
                && market_item.tier == Tier::T5(())) {
                purchased_items.append(market_item);
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
                purchased_waist = market_item.id;
            } else if (market_item.slot == Slot::Foot(())
                && purchased_foot == 0
                && market_item.tier == Tier::T5(())) {
                purchased_items.append(market_item);
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
                purchased_foot = market_item.id;
            } else if (market_item.slot == Slot::Hand(())
                && purchased_hand == 0
                && market_item.tier == Tier::T5(())) {
                purchased_items.append(market_item);
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
                purchased_hand = market_item.id;
            } else if (market_item.slot == Slot::Ring(())
                && purchased_ring == 0
                && market_item.tier == Tier::T3(())) {
                purchased_items.append(market_item);
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
                purchased_ring = market_item.id;
            } else if (market_item.slot == Slot::Neck(()) && purchased_necklace == 0) {
                purchased_items.append(market_item);
                shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
                purchased_necklace = market_item.id;
            }
            i += 1;
        };

        let purchased_items_span = purchased_items.span();

        // verify we have at least 2 items in our shopping cart
        assert(shopping_cart.len() >= 2, 'insufficient item purchase');
        // buy items
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // get bag from storage
        let bag = game.get_bag(ADVENTURER_ID);

        let mut items_to_equip = ArrayTrait::<u8>::new();
        // iterate over the items we bought
        let mut i: u32 = 0;
        loop {
            if i >= purchased_items_span.len() {
                break ();
            }
            // verify they are all in our bag
            assert(bag.contains(*purchased_items_span.at(i).id), 'item should be in bag');
            items_to_equip.append(*purchased_items_span.at(i).id);
            i += 1;
        };

        // equip all of the items we bought
        game.equip(ADVENTURER_ID, items_to_equip.clone());

        // get update bag from storage
        let bag = game.get_bag(ADVENTURER_ID);

        /// get updated adventurer
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // iterate over the items we equipped
        let mut i: u32 = 0;
        loop {
            if i >= items_to_equip.len() {
                break ();
            }
            // verify they are no longer in bag
            assert(!bag.contains(*items_to_equip.at(i)), 'item should not be in bag');
            // and equipped on the adventurer
            assert(
                adventurer.is_equipped(*purchased_items_span.at(i).id), 'item should be equipped'
            );
            i += 1;
        };
    }

    #[test]
    #[available_gas(100000000)]
    fn test_buy_potions() {
        let mut game = new_adventurer_lvl2_with_idle_penalty();

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // store original adventurer health and gold before buying potion
        let adventurer_health_pre_potion = adventurer.health;
        let adventurer_gold_pre_potion = adventurer.gold;

        // buy potions
        let number_of_potions = 8;
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, number_of_potions, 1, 0, 0, 0, 0, 0, shopping_cart);

        // get updated adventurer stat
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        // verify potion increased health by POTION_HEALTH_AMOUNT or adventurer health is full
        assert(
            adventurer.health == adventurer_health_pre_potion
                + (POTION_HEALTH_AMOUNT * number_of_potions.into()),
            'potion did not give health'
        );

        // verify potion cost reduced adventurers gold balance by POTION_PRICE * adventurer level (no charisma discount here)
        assert(
            adventurer.gold == adventurer_gold_pre_potion
                - (POTION_PRICE * adventurer.get_level().into() * number_of_potions.into()),
            'potion cost is wrong'
        );
    }

    #[test]
    #[should_panic(expected: ('Health already full', 'ENTRYPOINT_FAILED'))]
    #[available_gas(450000000)]
    fn test_buy_potions_exceed_max_health() {
        let mut game = new_adventurer_lvl2();

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // get number of potions required to reach full health
        let potions_to_full_health: u8 = (POTION_HEALTH_AMOUNT
            / (adventurer.get_max_health() - adventurer.health))
            .try_into()
            .unwrap();

        // attempt to buy one more potion than is required to reach full health
        // this should result in a panic 'Health already full'
        // this test is annotated to expect that panic
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let potions = potions_to_full_health + 1;
        game.upgrade_adventurer(ADVENTURER_ID, potions, 0, 0, 0, 0, 0, 1, shopping_cart);
    }

    #[test]
    #[should_panic(expected: ('Market is closed', 'ENTRYPOINT_FAILED'))]
    #[available_gas(100000000)]
    fn test_cant_buy_potion_without_stat_upgrade() {
        // deploy and start new game
        let mut game = new_adventurer_lvl2();

        // upgrade adventurer
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart.clone());

        // then try to buy potions (should panic with 'Market is closed')
        let potions = 1;
        game.upgrade_adventurer(ADVENTURER_ID, potions, 0, 0, 0, 0, 0, 1, shopping_cart);
    }

    #[test]
    #[should_panic(expected: ('Action not allowed in battle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(100000000)]
    fn test_cant_buy_potion_during_battle() {
        // deploy and start new game
        let mut game = new_adventurer();

        // attempt to immediately buy health before clearing starter beast
        // this should result in contract throwing a panic 'Action not allowed in battle'
        // This test is annotated to expect that panic
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let potions = 1;
        game.upgrade_adventurer(ADVENTURER_ID, potions, 0, 0, 0, 0, 0, 1, shopping_cart);
    }

    #[test]
    #[should_panic(expected: ('Adventurer is not idle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(300000000)]
    fn test_cant_slay_non_idle_adventurer_no_rollover() {
        let STARTING_BLOCK_NUMBER = 1;
        let IDLE_BLOCKS: u64 = Game::IDLE_DEATH_PENALTY_BLOCKS.into() - 1;

        // deploy and start new game
        let mut game = new_adventurer();

        // use 1 for starting block number
        let STARTING_BLOCK_NUMBER = STARTING_BLOCK_NUMBER;
        testing::set_block_number(STARTING_BLOCK_NUMBER);

        // attack starter beast, resulting in adventurer last action block number being 1
        game.attack(ADVENTURER_ID, false);

        // assert adventurers last action is expected value
        assert(
            game
                .get_adventurer(ADVENTURER_ID)
                .last_action == STARTING_BLOCK_NUMBER
                .try_into()
                .unwrap(),
            'unexpected last action block'
        );

        // roll forward blockchain
        testing::set_block_number(STARTING_BLOCK_NUMBER + IDLE_BLOCKS);

        // try to slay adventurer for being idle
        // this should result in contract throwing a panic 'Adventurer is not idle'
        // because the adventurer is not idle for the full IDLE_DEATH_PENALTY_BLOCKS
        // This test is annotated to expect that panic
        game.slay_idle_adventurer(ADVENTURER_ID);
    }

    #[test]
    #[should_panic(expected: ('Adventurer is not idle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(300000000)]
    fn test_cant_slay_non_idle_adventurer_with_rollover() {
        // set starting block to just before the rollover at 511
        let STARTING_BLOCK_NUMBER = 510;
        // adventurer will be idle for one less than the idle death penalty blocks
        let IDLE_BLOCKS: u64 = Game::IDLE_DEATH_PENALTY_BLOCKS.into() - 1;

        // deploy and start new game
        let mut game = new_adventurer();

        // set current block number
        testing::set_block_number(STARTING_BLOCK_NUMBER);

        // attack beast to set adventurer last action block number
        game.attack(ADVENTURER_ID, false);

        // assert adventurers last action is expected value
        assert(
            game
                .get_adventurer(ADVENTURER_ID)
                .last_action == STARTING_BLOCK_NUMBER
                .try_into()
                .unwrap(),
            'unexpected last action'
        );

        // roll forward block chain
        testing::set_block_number(STARTING_BLOCK_NUMBER + IDLE_BLOCKS);

        // try to slay adventurer for being idle
        // this should result in contract throwing a panic 'Adventurer is not idle'
        // because the adventurer is not idle for the full IDLE_DEATH_PENALTY_BLOCKS
        // This test is annotated to expect that panic
        game.slay_idle_adventurer(ADVENTURER_ID);
        game.slay_idle_adventurer(ADVENTURER_ID);
    }

    #[test]
    #[available_gas(60000000)]
    // @dev since we only store 511 blocks, there are two cases for the idle adventurer
    // the first is when the adventurer last action block number is less than the
    // (current_block_number % 511) and the other is when it is greater
    // this test covers the case where the adventurer last action block number is less than the
    // (current_block_number % 511)
    fn test_slay_idle_adventurer_with_block_rollover() {
        let STARTING_BLOCK_NUMBER = 510;

        // deploy and start new game
        let mut game = new_adventurer();

        // set current block number to 510
        testing::set_block_number(STARTING_BLOCK_NUMBER);

        // attack starter beast, resulting in adventurer last action block number being 510
        game.attack(ADVENTURER_ID, false);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // verify last action block number is 1
        assert(
            adventurer.last_action == STARTING_BLOCK_NUMBER.try_into().unwrap(),
            'unexpected last action block'
        );

        // roll forward blockchain to make adventurer idle
        testing::set_block_number(
            adventurer.last_action.into() + Game::IDLE_DEATH_PENALTY_BLOCKS.into()
        );

        // get current block number
        let current_block_number = starknet::get_block_info().unbox().block_number;

        // verify current block number % MAX_BLOCK_COUNT is less than adventurers last action block number
        // this is imperative because this test is testing the case where the adventurer last action block number
        // is less than (current_block_number % MAX_BLOCK_COUNT)
        assert(
            (current_block_number % MAX_BLOCK_COUNT) < adventurer.last_action.into(),
            'last action !> current block'
        );

        // slay idle adventurer
        game.slay_idle_adventurer(ADVENTURER_ID);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // assert adventurer is dead
        assert(adventurer.health == 0, 'adventurer should be dead');
    }

    #[test]
    #[available_gas(70000000)]
    // @dev since we only store 511 blocks, there are two cases for the idle adventurer
    // the first is when the adventurer last action block number is less than the
    // (current_block_number % 511) and the other is when it is greater
    // this test covers the case where the adventurer last action block number is greater than
    // (current_block_number % 511)
    fn test_slay_idle_adventurer_without_block_rollover() {
        let STARTING_BLOCK_NUMBER = 1;

        // deploy and start new game
        let mut game = new_adventurer();

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // set current block number to 1
        testing::set_block_number(STARTING_BLOCK_NUMBER);

        // attack starter beast, resulting in adventurer last action block number being 1
        game.attack(ADVENTURER_ID, false);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // verify last action block number is 1
        assert(
            adventurer.last_action == STARTING_BLOCK_NUMBER.try_into().unwrap(),
            'unexpected last action block'
        );

        // roll forward blockchain to make adventurer idle
        testing::set_block_number(
            adventurer.last_action.into() + Game::IDLE_DEATH_PENALTY_BLOCKS.into()
        );

        // get current block number
        let current_block_number = starknet::get_block_info().unbox().block_number;

        // verify current block number % MAX_BLOCK_COUNT is greater than adventurers last action block number
        // this is imperative because this test is testing the case where the adventurer last action block number
        // is greater than the (current_block_number % MAX_BLOCK_COUNT)
        assert(
            (current_block_number % MAX_BLOCK_COUNT) > adventurer.last_action.into(),
            'last action !> current block'
        );

        // call slay idle adventurer
        game.slay_idle_adventurer(ADVENTURER_ID);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // assert adventurer is dead
        assert(adventurer.health == 0, 'adventurer should be dead');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_entropy() {
        let mut game = new_adventurer();

        game.get_entropy();
    }

    #[test]
    #[available_gas(100000000)]
    fn test_get_potion_price() {
        let mut game = new_adventurer();
        let potion_price = game.get_potion_price(ADVENTURER_ID);
        let adventurer_level = game.get_adventurer(ADVENTURER_ID).get_level();
        assert(potion_price == POTION_PRICE * adventurer_level.into(), 'wrong lvl1 potion price');

        let mut game = new_adventurer_lvl2();
        let potion_price = game.get_potion_price(ADVENTURER_ID);
        let adventurer_level = game.get_adventurer(ADVENTURER_ID).get_level();
        assert(potion_price == POTION_PRICE * adventurer_level.into(), 'wrong lvl2 potion price');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_get_attacking_beast() {
        let mut game = new_adventurer();
        let beast = game.get_attacking_beast(ADVENTURER_ID);
        // our adventurer starts with a wand so the starter beast should be a troll
        assert(beast.id == BeastId::Troll, 'starter beast should be troll');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_get_health() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.health == game.get_health(ADVENTURER_ID), 'wrong adventurer health');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_get_xp() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.xp == game.get_xp(ADVENTURER_ID), 'wrong adventurer xp');
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_level() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == game.get_level(ADVENTURER_ID), 'wrong adventurer level');
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_gold() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.gold == game.get_gold(ADVENTURER_ID), 'wrong gold bal');
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_beast_health() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.beast_health == game.get_beast_health(ADVENTURER_ID), 'wrong beast health'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_stat_upgrades_available() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.stat_points_available == game.get_stat_upgrades_available(ADVENTURER_ID),
            'wrong stat points avail'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_last_action() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.last_action == game.get_last_action(ADVENTURER_ID), 'wrong last action');
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_weapon_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.weapon.get_greatness() == game.get_weapon_greatness(ADVENTURER_ID),
            'wrong weapon greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_chest_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.chest.get_greatness() == game.get_chest_greatness(ADVENTURER_ID),
            'wrong chest greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_head_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.head.get_greatness() == game.get_head_greatness(ADVENTURER_ID),
            'wrong head greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_waist_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.waist.get_greatness() == game.get_waist_greatness(ADVENTURER_ID),
            'wrong waist greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_foot_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.foot.get_greatness() == game.get_foot_greatness(ADVENTURER_ID),
            'wrong foot greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_hand_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.hand.get_greatness() == game.get_hand_greatness(ADVENTURER_ID),
            'wrong hand greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_necklace_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.neck.get_greatness() == game.get_necklace_greatness(ADVENTURER_ID),
            'wrong neck greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_ring_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.ring.get_greatness() == game.get_ring_greatness(ADVENTURER_ID),
            'wrong ring greatness'
        );
    }

    // To run this test we need to increase starting gold so we can buy max number of items
    // We either need to use cheat codes to accomplish this or have the contract take in
    // game settings in the constructor. Commenting this out for now so our CI doesn't run it
    // #[test]
    // #[available_gas(80000000000)]
    // fn test_max_items() {
    //     // start game on level 2 so we have access to the market
    //     let mut game = new_adventurer_max_charisma_level2();

    //     // get items from market
    //     let mut market_items = @game.get_items_on_market(ADVENTURER_ID);

    //     // get first item on the market
    //     let item_id = *market_items.at(0).item.id;

    //     let mut purchased_weapon: u8 = 0;
    //     let mut purchased_chest: u8 = 0;
    //     let mut purchased_head: u8 = 0;
    //     let mut purchased_waist: u8 = 0;
    //     let mut purchased_foot: u8 = 0;
    //     let mut purchased_hand: u8 = 0;
    //     let mut purchased_ring: u8 = 0;
    //     let mut purchased_necklace: u8 = 0;
    //     let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();

    //     let mut i: u32 = 0;
    //     loop {
    //         if i >= market_items.len() {
    //             break ();
    //         }
    //         let market_item = *market_items.at(i).item;

    //         // if the item is a weapon and we haven't purchased a weapon yet
    //         // and the item is a tier 4 or 5 item
    //         // repeat this for everything
    //         if (market_item.slot == Slot::Weapon(())
    //             && purchased_weapon == 0
    //             && market_item.id != 12) {
    //             shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });
    //             purchased_weapon = market_item.id;
    //         } else if (market_item.slot == Slot::Chest(()) && purchased_chest == 0) {
    //             shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: true });
    //             purchased_chest = market_item.id;
    //         } else if (market_item.slot == Slot::Head(()) && purchased_head == 0) {
    //             shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: true });
    //             purchased_head = market_item.id;
    //         } else if (market_item.slot == Slot::Waist(()) && purchased_waist == 0) {
    //             shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: true });
    //             purchased_waist = market_item.id;
    //         } else if (market_item.slot == Slot::Foot(()) && purchased_foot == 0) {
    //             shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: true });
    //             purchased_foot = market_item.id;
    //         } else if (market_item.slot == Slot::Hand(()) && purchased_hand == 0) {
    //             shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: true });
    //             purchased_hand = market_item.id;
    //         } else if (market_item.slot == Slot::Ring(()) && purchased_ring == 0) {
    //             shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: true });
    //             purchased_ring = market_item.id;
    //         } else if (market_item.slot == Slot::Neck(()) && purchased_necklace == 0) {
    //             shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: true });
    //             purchased_necklace = market_item.id;
    //         }
    //         i += 1;
    //     };

    //     assert(
    //         purchased_weapon != 0
    //             && purchased_chest != 0
    //             && purchased_head != 0
    //             && purchased_waist != 0
    //             && purchased_foot != 0
    //             && purchased_hand != 0
    //             && purchased_ring != 0
    //             && purchased_necklace != 0,
    //         'did not purchase all items'
    //     );

    //     let mut i: u32 = 0;
    //     loop {
    //         if i >= market_items.len() {
    //             break ();
    //         }
    //         let market_item = *market_items.at(i).item;

    //         if (market_item.id == purchased_weapon
    //             || market_item.id == purchased_chest
    //             || market_item.id == purchased_head
    //             || market_item.id == purchased_waist
    //             || market_item.id == purchased_foot
    //             || market_item.id == purchased_hand
    //             || market_item.id == purchased_ring
    //             || market_item.id == purchased_necklace
    //             || shopping_cart.len() == 19) {
    //             i += 1;
    //             continue;
    //         }

    //         shopping_cart.append(ItemPurchase { item_id: market_item.id, equip: false });

    //         i += 1;
    //     };

    //     // We intentionally loaded our cart with 19 items which would be one more than max
    //     // when you add our starter weapon. We did this so we could pop one item off the cart
    //     // and into this overflow shopping cart which we'll use later
    //     let mut overflow_item = shopping_cart.pop_front().unwrap();
    //     overflow_item.equip = true;
    //     let mut overflow_shopping_cart = ArrayTrait::<ItemPurchase>::new();
    //     overflow_shopping_cart.append(overflow_item);

    //     // verify we have at least two items in shopping cart
    //     assert(shopping_cart.len() == 18, 'should be max items');

    //     // buy items in shopping cart which will fully equip the adventurer
    //     // and fill their bag
    //     game.buy_items(ADVENTURER_ID, shopping_cart.clone());

    //     // drop our weapon and attempt (should free up an item slow)
    //     let mut items_to_drop = ArrayTrait::<u8>::new();
    //     items_to_drop.append(12);
    //     game.drop(ADVENTURER_ID, items_to_drop);

    //     game.buy_items(ADVENTURER_ID, overflow_shopping_cart.clone());

    //     // get updated adventurer and bag state
    //     let bag = game.get_bag(ADVENTURER_ID);
    //     let adventurer = game.get_adventurer(ADVENTURER_ID);
    // }

    #[test]
    #[available_gas(90000000)]
    fn test_drop_item() {
        // start new game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2();

        // get items from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);

        // get first item on the market
        let purchased_item_id = *market_items.at(0).item.id;
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: purchased_item_id, equip: false });

        // buy first item on market and bag it
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        // get bag state
        let bag = game.get_bag(ADVENTURER_ID);

        // assert adventurer has starting weapon equipped
        assert(adventurer.weapon.id != 0, 'adventurer should have weapon');
        // assert bag has the purchased item
        assert(bag.contains(purchased_item_id), 'item should be in bag');

        // create drop list consisting of adventurers equipped weapon and purchased item that is in bag
        let mut drop_list = ArrayTrait::<u8>::new();
        drop_list.append(adventurer.weapon.id);
        drop_list.append(purchased_item_id);

        // call contract drop
        game.drop_items(ADVENTURER_ID, drop_list);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        // get bag state
        let bag = game.get_bag(ADVENTURER_ID);

        // assert adventurer has no weapon equipped
        assert(adventurer.weapon.id == 0, 'weapon id should be 0');
        assert(adventurer.weapon.xp == 0, 'weapon should have no xp');

        // assert bag does not have the purchased item
        assert(!bag.contains(purchased_item_id), 'item should not be in bag');
    }

    #[test]
    #[should_panic(expected: ('Item not owned by adventurer', 'ENTRYPOINT_FAILED'))]
    #[available_gas(90000000)]
    fn test_drop_item_without_ownership() {
        // start new game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2();

        // intialize an array with 20 items in it
        let mut drop_list = ArrayTrait::<u8>::new();
        drop_list.append(255);

        // try to drop an item the adventurer doesn't own
        // this should result in a panic 'Item not owned by adventurer'
        // this test is annotated to expect that panic
        game.drop_items(ADVENTURER_ID, drop_list);
    }

    #[test]
    #[available_gas(75000000)]
    fn test_upgrade_stats() {
        // deploy and start new game
        let mut game = new_adventurer_lvl2();
        let CHARISMA_STAT = 5;

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let original_charisma = adventurer.stats.charisma;

        // call upgrade_stats with stat upgrades
        // TODO: test with more than one which is challenging
        // because we need a multi-level or G20 stat unlocks
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 1, shopping_cart);

        // get update adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // assert charisma was increased
        assert(adventurer.stats.charisma == original_charisma + 1, 'charisma not increased');
        // assert stat point was used
        assert(adventurer.stat_points_available == 0, 'should have used stat point');
    }

    #[test]
    #[should_panic(expected: ('insufficient stat upgrades', 'ENTRYPOINT_FAILED'))]
    #[available_gas(70000000)]
    fn test_upgrade_stats_not_enough_points() {
        // deploy and start new game
        let mut game = new_adventurer_lvl2();
        let CHARISMA_STAT = 5;

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let original_charisma = adventurer.stats.charisma;

        // try to upgrade charisma x2 with only 1 stat available
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        game.upgrade_adventurer(ADVENTURER_ID, 0, 0, 0, 0, 0, 0, 2, shopping_cart);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_upgrade_adventurer() {
        // deploy and start new game
        let mut game = new_adventurer_lvl2();

        // get original adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let original_charisma = adventurer.stats.charisma;
        let original_health = adventurer.health;

        // potions
        let potions = 1;

        // items to purchase
        let market_items = @game.get_items_on_market(ADVENTURER_ID);
        let item_1 = *market_items.at(0).item.id;
        let item_2 = *market_items.at(1).item.id;
        let mut items_to_purchase = ArrayTrait::<ItemPurchase>::new();
        items_to_purchase.append(ItemPurchase { item_id: item_1, equip: true });
        items_to_purchase.append(ItemPurchase { item_id: item_2, equip: true });

        let strength = 0;
        let dexterity = 0;
        let vitality = 0;
        let intelligence = 0;
        let wisdom = 0;
        let charisma = 1;

        // purchase potions, items, and upgrade stat in single call
        game
            .upgrade_adventurer(
                ADVENTURER_ID,
                potions,
                strength,
                dexterity,
                vitality,
                intelligence,
                wisdom,
                charisma,
                items_to_purchase
            );

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // assert health was increased by one potion
        assert(adventurer.health == original_health + POTION_HEALTH_AMOUNT, 'health not increased');
        // assert charisma was increased
        assert(adventurer.stats.charisma == original_charisma + 1, 'charisma not increased');
        // assert stat point was used
        assert(adventurer.stat_points_available == 0, 'should have used stat point');

        // assert adventurer has the purchased items
        assert(adventurer.is_equipped(item_1), 'item should be equipped');
        assert(adventurer.is_equipped(item_2), 'item should be equipped');
    }
}
