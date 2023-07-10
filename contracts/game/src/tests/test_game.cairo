use core::box::BoxTrait;
#[cfg(test)]
mod tests {
    use array::ArrayTrait;
    use core::result::ResultTrait;
    use core::traits::Into;
    use option::OptionTrait;
    use starknet::syscalls::deploy_syscall;
    use starknet::testing;
    use traits::TryInto;
    use core::serde::Serde;
    use box::BoxTrait;
    use starknet::{ContractAddress, ContractAddressIntoFelt252, contract_address_const};

    use market::market::{ImplMarket, LootWithPrice};
    use lootitems::loot::{Loot, ImplLoot, ILoot};
    use lootitems::statistics::constants::{ItemId};
    use game::game::interfaces::{IGameDispatcherTrait, IGameDispatcher};
    use game::{Game};
    use survivor::adventurer_meta::AdventurerMetadata;
    use survivor::constants::adventurer_constants::{
        STARTING_GOLD, POTION_HEALTH_AMOUNT, POTION_PRICE, STARTING_HEALTH
    };
    use survivor::adventurer::{Adventurer, ImplAdventurer, IAdventurer};

    use game::game::constants::messages::{STAT_UPGRADES_AVAILABLE};
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
            name: 'Loaf'.try_into().unwrap(), home_realm: 1, race: 1, entropy: 1
        };

        game.start(INTERFACE_ID(), ItemId::Wand, adventurer_meta);

        game
    }

    fn lvl_2_adventurer() -> IGameDispatcher {
        let mut game = new_adventurer();

        game.attack(ADVENTURER_ID);
        game.attack(ADVENTURER_ID);
        game
    }

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
        assert(adventurer_meta_1.race == 1, 'race');

        adventurer_meta_1.entropy;
    }

    #[test]
    #[should_panic(expected: ('Action not allowed in battle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(30000000)]
    fn test_no_explore_during_battle() {
        let mut game = new_adventurer();
        let original_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(original_adventurer.xp == 0, 'should start with 0 xp');
        assert(original_adventurer.health == 100, 'should start with 100hp');
        assert(original_adventurer.weapon.id == ItemId::Wand, 'adventurer should have a wand');
        assert(
            original_adventurer.beast_health == BeastSettings::STARTER_BEAST_HEALTH,
            'adventurer should have a wand'
        );

        // try to explore before defeating start beast
        // should result in a panic 'In battle cannot explore' which
        // is annotated in the test
        game.explore(ADVENTURER_ID);
    }

    #[test]
    #[should_panic]
    #[available_gas(700000)]
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
        game.attack(ADVENTURER_ID);

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
            game.attack(ADVENTURER_ID);
        } // if the beast was not killed in one hit
        else {
            assert(updated_adventurer.xp == adventurer_start.xp, 'should have same xp');
            assert(updated_adventurer.gold == adventurer_start.gold, 'should have same gold');
            assert(updated_adventurer.health != 100, 'should have taken dmg');

            // attack again (will take out starter beast with current settings regardless of critical hit)
            game.attack(ADVENTURER_ID);

            // recheck adventurer stats
            let updated_adventurer = game.get_adventurer(ADVENTURER_ID);
            assert(updated_adventurer.beast_health == 0, 'beast should be dead');
            assert(updated_adventurer.xp > adventurer_start.xp, 'should have same xp');
            assert(updated_adventurer.gold > adventurer_start.gold, 'should have same gold');

            // attack again after the beast is dead which should
            // result in a panic. This test is annotated to expect a panic
            // so if it doesn't, this test will fail
            game.attack(ADVENTURER_ID);
        }
    }

    #[test]
    #[should_panic(expected: ('Cant flee starter beast', 'ENTRYPOINT_FAILED'))]
    #[available_gas(15000000)]
    fn test_cant_flee_starter_beast() {
        // start new game
        let mut game = new_adventurer();

        // immediately attempt to flee starter beast
        // which is not allowed and should result in a panic 'Cant flee starter beast'
        // which is annotated in the test
        game.flee(ADVENTURER_ID);
    }

    #[test]
    #[should_panic(expected: ('Not in battle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(65000000)]
    fn test_cant_flee_outside_battle() {
        // start adventuer and advance to level 2
        let mut game = lvl_2_adventurer();

        // get adventurer state
        let adventurer = game.get_adventurer(0);

        // assert adventurer is not in a battle
        assert(adventurer.beast_health == 0, 'should not be in battle');

        // attempt to flee despite not being in a battle
        // this should trigger a panic 'Not in battle' which is
        // annotated in the test
        game.flee(ADVENTURER_ID);
    }

    #[test]
    #[available_gas(15000000000)]
    fn test_flee() {
        let mut game = lvl_2_adventurer();

        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(updated_adventurer.beast_health == 0, 'beast should be dead');

        // use stat upgrade
        game.upgrade_stat(ADVENTURER_ID, 0);

        // manipulate game entrop so we discover another beast
        testing::set_block_number(1004);
        game.explore(ADVENTURER_ID);

        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(updated_adventurer.beast_health == 0, 'should have found a beast');

        testing::set_block_number(1005);
        game.explore(ADVENTURER_ID);

        // explore again to find a beast
        testing::set_block_number(1006);
        game.explore(ADVENTURER_ID);

        game.flee(ADVENTURER_ID);
        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(updated_adventurer.beast_health == 0, 'should have fled beast');
    }

    #[test]
    #[should_panic(expected: ('Stat upgrade available', 'ENTRYPOINT_FAILED'))]
    #[available_gas(8000000000)]
    fn test_explore_not_allowed_with_avail_stat_upgrade() {
        let mut game = new_adventurer();

        // take out starter beast
        game.attack(ADVENTURER_ID);
        game.attack(ADVENTURER_ID);

        // get updated adventurer
        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);

        // assert adventurer is now level 2 and has 1 stat upgrade available
        assert(updated_adventurer.get_level() == 2, 'advntr should be lvl 2');
        assert(updated_adventurer.stat_points_available == 1, 'advntr should have 1 stat avl');

        // verify adventurer is unable to explore with stat upgrade available
        // this test is annotated to expect a panic so if it doesn't, this test will fail
        game.explore(ADVENTURER_ID);
    }

    #[test]
    #[should_panic(expected: ('Action not allowed in battle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(1800000000)]
    fn test_cant_buy_items_during_battle() {
        // mint new adventurer (will start in battle with starter beast)
        let mut game = new_adventurer();

        // get valid item from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);
        let item_id = *market_items.at(0).item.id;
        let item_price = *market_items.at(0).price.into();

        // attempt to buy item during battle - should_panic with message 'Action not allowed in battle'
        // this test is annotated to expect a panic so if it doesn't, this test will fail
        game.buy_item(ADVENTURER_ID, item_id, true);
    }

    #[test]
    #[should_panic(expected: ('Market is closed', 'ENTRYPOINT_FAILED'))]
    #[available_gas(65000000)]
    fn test_cant_buy_items_without_stat_upgrade() {
        // mint adventurer and advance to level 2
        let mut game = lvl_2_adventurer();

        // use the adventurers available stat
        game.upgrade_stat(ADVENTURER_ID, 1);

        // get valid item from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);
        let item_id = *market_items.at(0).item.id;

        // attempt to buy item
        game.buy_item(ADVENTURER_ID, item_id, true);
    // Since we have already used our stat upgrade the market should be closed
    // resulting in a 'Market is closed' panic
    // this test is annotated to expect that specific panic so if it doesn't, this test will fail
    }

    #[test]
    #[should_panic(expected: ('Market item does not exist', 'ENTRYPOINT_FAILED'))]
    #[available_gas(65000000)]
    fn test_buy_unavailable_item() {
        let mut game = lvl_2_adventurer();
        game.buy_item(ADVENTURER_ID, 200, true);
    }

    #[test]
    #[available_gas(70000000)]
    fn test_buy_and_equip_item() {
        let mut game = lvl_2_adventurer();
        let market_items = @game.get_items_on_market(ADVENTURER_ID);
        let item_id = *market_items.at(0).item.id;
        let item_price = *market_items.at(0).price.into();

        game.buy_item(ADVENTURER_ID, item_id, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);

        assert(
            adventurer.gold == (STARTING_GOLD + 8)
                - item_price,
            'gold'
        );
    }

    #[test]
    #[available_gas(65000000)]
    fn test_buy_and_bag_item() {
        let mut game = lvl_2_adventurer();
        let market_items = @game.get_items_on_market(ADVENTURER_ID);

        game.buy_item(ADVENTURER_ID, *market_items.at(0).item.id, false);

        let bag = game.get_bag(ADVENTURER_ID);

        assert(bag.item_1.id == *market_items.at(0).item.id, 'sash in bag');
    }

    #[test]
    #[available_gas(4000000000)]
    fn test_equip_item_from_bag() {
        let mut game = lvl_2_adventurer();
        let market_items = @game.get_items_on_market(ADVENTURER_ID);

        market_items.at(0).item.id;

        game.buy_item(ADVENTURER_ID, *market_items.at(0).item.id, false);

        let bag = game.get_bag(ADVENTURER_ID);
        assert(bag.item_1.id == *market_items.at(0).item.id, 'in bag');
    }

    #[test]
    #[should_panic(expected: ('Health already full', 'ENTRYPOINT_FAILED'))]
    #[available_gas(70000000)]
    fn test_buy_potion() {
        // deploy and start new game
        let mut game = new_adventurer();

        // Clear starter beast
        game.attack(ADVENTURER_ID);
        game.attack(ADVENTURER_ID);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // verify adventurer took damage from starter beast
        assert(adventurer.health < STARTING_HEALTH, 'should take dmg from beast');

        // get adventurer health and gold before buying potion
        let adventurer_health_pre_potion = adventurer.health;
        let adventurer_gold_pre_potion = adventurer.gold;

        // buy potion
        game.buy_potion(ADVENTURER_ID);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // verify potion increased health by POTION_HEALTH_AMOUNT or adventurer health is full
        assert(
            adventurer.health == 100 || adventurer.health == adventurer_health_pre_potion
                + POTION_HEALTH_AMOUNT,
            'potion did not give health'
        );

        // verify potion cost reduced adventurers gold balance by POTION_PRICE * adventurer level (no charisma discount here)
        assert(
            adventurer.gold == adventurer_gold_pre_potion
                - (POTION_PRICE * adventurer.get_level().into()),
            'potion cost is wrong'
        );

        // buy potions with full health
        // this should throw a panic 'Health already full' and this test is annotated to expect that panic
        // if it doesn't throw a panic, this test will fail.
        // @dev buying five potions here to account for the possibility of game settings changing such that
        // multiple potions are needed after started beast to fill up health
        game.buy_potion(ADVENTURER_ID);
        game.buy_potion(ADVENTURER_ID);
        game.buy_potion(ADVENTURER_ID);
    }

    #[test]
    #[should_panic(expected: ('Action not allowed in battle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(100000000)]
    fn test_cant_buy_health_during_battle() {
        // deploy and start new game
        let mut game = new_adventurer();

        // attempt to immediately buy health before clearing starter beast
        // this should result in contract throwing a panic 'Action not allowed in battle'
        // This test is annotated to expect that panic
        game.buy_potion(ADVENTURER_ID);
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
        game.attack(ADVENTURER_ID);

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
        game.attack(ADVENTURER_ID);

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
    #[available_gas(50000000)]
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
        game.attack(ADVENTURER_ID);

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

        // verify current block number % MAX_STORAGE_BLOCKS is less than adventurers last action block number
        // this is imperative because this test is testing the case where the adventurer last action block number
        // is less than (current_block_number % MAX_STORAGE_BLOCKS)
        assert(
            (current_block_number % Game::MAX_STORAGE_BLOCKS) < adventurer.last_action.into(),
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
    #[available_gas(50000000)]
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
        game.attack(ADVENTURER_ID);

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

        // verify current block number % MAX_STORAGE_BLOCKS is greater than adventurers last action block number
        // this is imperative because this test is testing the case where the adventurer last action block number
        // is greater than the (current_block_number % MAX_STORAGE_BLOCKS)
        assert(
            (current_block_number % Game::MAX_STORAGE_BLOCKS) > adventurer.last_action.into(),
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
    #[available_gas(300000000)]
    fn test_entropy() {
        let mut game = new_adventurer();

        game.get_entropy();
    }

    #[test]
    #[available_gas(300000000)]
    fn test_get_potion_price() {
        let mut game = new_adventurer();
        let potion_price = game.get_potion_price(ADVENTURER_ID);
        let adventurer_level = game.get_adventurer(ADVENTURER_ID).get_level();
        assert(potion_price == POTION_PRICE * adventurer_level.into(), 'wrong lvl1 potion price');

        let mut game = lvl_2_adventurer();
        let potion_price = game.get_potion_price(ADVENTURER_ID);
        let adventurer_level = game.get_adventurer(ADVENTURER_ID).get_level();
        assert(potion_price == POTION_PRICE * adventurer_level.into(), 'wrong lvl2 potion price');
    }

    #[test]
    #[available_gas(800000000)]
    fn test_get_attacking_beast() {
        let mut game = new_adventurer();
        let beast = game.get_attacking_beast(ADVENTURER_ID);
        // our adventurer starts with a wand so the starter beast should be a troll
        assert(beast.id == BeastId::Troll, 'starter beast should be troll');
    }

    #[test]
    #[available_gas(800000000)]
    fn test_get_health() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.health == game.get_health(ADVENTURER_ID), 'wrong adventurer health');
    }

    #[test]
    #[available_gas(800000000)]
    fn test_get_xp() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.xp == game.get_xp(ADVENTURER_ID), 'wrong adventurer xp');
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_level() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == game.get_level(ADVENTURER_ID), 'wrong adventurer level');
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_gold() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.gold == game.get_gold(ADVENTURER_ID), 'wrong gold bal');
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_beast_health() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.beast_health == game.get_beast_health(ADVENTURER_ID), 'wrong beast health'
        );
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_stat_points_available() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.stat_points_available == game.get_stat_points_available(ADVENTURER_ID),
            'wrong stat points avail'
        );
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_last_action() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.last_action == game.get_last_action(ADVENTURER_ID), 'wrong last action');
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_weapon_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.weapon.get_greatness() == game
                .get_weapon_greatness(ADVENTURER_ID),
            'wrong weapon greatness'
        );
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_chest_armor_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.chest.get_greatness() == game
                .get_chest_armor_greatness(ADVENTURER_ID),
            'wrong chest greatness'
        );
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_head_armor_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.head.get_greatness() == game
                .get_head_armor_greatness(ADVENTURER_ID),
            'wrong head greatness'
        );
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_waist_armor_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.waist.get_greatness() == game
                .get_waist_armor_greatness(ADVENTURER_ID),
            'wrong waist greatness'
        );
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_foot_armor_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.foot.get_greatness() == game
                .get_foot_armor_greatness(ADVENTURER_ID),
            'wrong foot greatness'
        );
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_hand_armor_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.hand.get_greatness() == game
                .get_hand_armor_greatness(ADVENTURER_ID),
            'wrong hand greatness'
        );
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_necklace_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.neck.get_greatness() == game
                .get_necklace_greatness(ADVENTURER_ID),
            'wrong neck greatness'
        );
    }
    #[test]
    #[available_gas(800000000)]
    fn test_get_ring_greatness() {
        let mut game = new_adventurer();
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.ring.get_greatness() == game
                .get_ring_greatness(ADVENTURER_ID),
            'wrong ring greatness'
        );
    }
}
