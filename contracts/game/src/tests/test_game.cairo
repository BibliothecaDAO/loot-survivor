#[cfg(test)]
mod tests {
    use array::ArrayTrait;
    use core::result::ResultTrait;
    use core::traits::Into;
    use option::OptionTrait;
    use starknet::syscalls::deploy_syscall;
    use traits::TryInto;
    use debug::PrintTrait;
    use core::serde::Serde;

    use market::market::{ImplMarket};

    use lootitems::loot::{Loot, ImplLoot, ILoot};
    use lootitems::statistics::constants::{ItemId};

    use game::game::interfaces::{IGameDispatcherTrait, IGameDispatcher};
    use game::game::game::{Game};
    use survivor::adventurer_meta::{
        AdventurerMetadata, ImplAdventurerMetadata, IAdventurerMetadata,
    };

    use survivor::constants::adventurer_constants::{
        STARTING_GOLD, POTION_HEALTH_AMOUNT, POTION_PRICE, STARTING_HEALTH
    };

    use survivor::adventurer::{Adventurer, ImplAdventurer, IAdventurer};

    use game::game::messages::messages;
    use beasts::constants::BeastSettings;

    fn setup() -> IGameDispatcher {
        let mut calldata = Default::default();

        // lords
        calldata.append(100);

        // dao
        calldata.append(200);

        let (address0, _) = deploy_syscall(
            Game::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();
        IGameDispatcher { contract_address: address0 }
    }

    fn new_adventurer() -> IGameDispatcher {
        let mut deployed_game = setup();

        let adventurer_meta = AdventurerMetadata {
            name: 'Loaf'.try_into().unwrap(), home_realm: 1, race: 1, order: 2, entropy: 0
        };

        deployed_game.start(ItemId::Wand, adventurer_meta);

        deployed_game
    }

    fn adventurer_market_items() -> Array<Loot> {
        let mut deployed_game = new_adventurer();

        deployed_game.get_items_on_market(0)
    }

    #[test]
    #[available_gas(30000000)]
    fn test_start() {
        let mut deployed_game = new_adventurer();

        let adventurer_1 = deployed_game.get_adventurer(0);
        let adventurer_meta_1 = deployed_game.get_adventurer_meta(0);

        // check adventurer
        assert(adventurer_1.weapon.id == ItemId::Wand, 'weapon');
        assert(adventurer_1.beast_health > 0, 'beast_health');

        // check meta
        assert(adventurer_meta_1.name == 'Loaf', 'name');
        assert(adventurer_meta_1.home_realm == 1, 'home_realm');
        assert(adventurer_meta_1.race == 1, 'race');
        assert(adventurer_meta_1.order == 2, 'order');

        adventurer_meta_1.entropy;
    }

    #[test]
    #[available_gas(30000000)]
    fn test_explore() {
        let mut deployed_game = new_adventurer();
        let original_adventurer = deployed_game.get_adventurer(0);
        assert(original_adventurer.xp == 0, 'should start with 0 xp');
        assert(original_adventurer.health == 100, 'should start with 100hp');
        assert(original_adventurer.weapon.id == ItemId::Wand, 'adventurer should have a wand');

        // Go exploring an encounter an obstacle (explore is currently hard coded for an obstacle)
        deployed_game.explore(0);
        let updated_adventurer = deployed_game.get_adventurer(0);
        assert(updated_adventurer.health == 100, 'should have dodged obstacle');
    }

    #[test]
    #[should_panic]
    #[available_gas(700000)]
    fn test_attack() {
        let mut game = new_adventurer();
        let adventurer_start = game.get_adventurer(0);

        // verify starting state
        assert(adventurer_start.health == 100, 'advtr should start with 100hp');
        assert(adventurer_start.xp == 0, 'advtr should start with 0xp');
        assert(
            adventurer_start.beast_health == BeastSettings::STARTER_BEAST_HEALTH,
            'wrong beast starting health'
        );

        // attack beast
        game.attack(0);

        // verify beast and adventurer took damage
        let updated_adventurer = game.get_adventurer(0);
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
            game.attack(0);
        } // if the beast was not killed in one hit 
        else {
            assert(updated_adventurer.xp == adventurer_start.xp, 'should have same xp');
            assert(updated_adventurer.gold == adventurer_start.gold, 'should have same gold');
            assert(updated_adventurer.health != 100, 'should have taken dmg');

            // attack again (will take out starter beast with current settings regardless of critical hit)
            game.attack(0);

            // recheck adventurer stats
            let updated_adventurer = game.get_adventurer(0);
            assert(updated_adventurer.beast_health == 0, 'beast should be dead');
            assert(updated_adventurer.xp > adventurer_start.xp, 'should have same xp');
            assert(updated_adventurer.gold > adventurer_start.gold, 'should have same gold');

            // attack again after the beast is dead which should
            // result in a panic. This test is annotated to expect a panic
            // so if it doesn't, this test will fail
            game.attack(0);
        }
    }

    #[test]
    #[should_panic]
    #[available_gas(10000000)]
    fn test_flee_starter_beast() {
        let mut game = new_adventurer();
        let adventurer_start = game.get_adventurer(0);

        // attempt to flee starter beast - should_panic
        game.flee(0);
    }

    #[test]
    #[available_gas(90000000)]
    fn test_flee() {
        let mut game = new_adventurer();
        let adventurer_start = game.get_adventurer(0);

        // double tap the first beast
        // TODO: Need to determine why starter beast
        // takes 5 attacks to take down on this test
        // in test_attack  it only takes two which is
        // expected. For now my goal is to test flee so going to just
        // send the 5x attack so I can discover a non-starter beast
        game.attack(0);
        game.attack(0);
        game.attack(0);
        game.attack(0);
        game.attack(0);

        let updated_adventurer = game.get_adventurer(0);
        assert(updated_adventurer.beast_health == 0, 'beast should be dead');

        // use stat upgrade
        game.upgrade_stat(0, 0);

        // manipulate game entrop so we discover another beast
        game.set_entropy(2);
        game.explore(0);
        let updated_adventurer = game.get_adventurer(0);
        assert(updated_adventurer.beast_health != 0, 'should have found a beast');

        game.set_entropy(4);
        game.flee(0);
        let updated_adventurer = game.get_adventurer(0);
        assert(updated_adventurer.beast_health == 0, 'should have fled beast');
    }

    #[test]
    #[should_panic]
    #[available_gas(80000000)]
    fn test_explore_not_allowed_with_stat() {
        let mut game = new_adventurer();
        let adventurer_start = game.get_adventurer(0);

        // TODO: Need to determine why starter beast
        // takes 5 attacks to take down on this test
        // in the test_attack above it only takes two which is
        // expected. For now my goal is to test flee so going to just
        // send the 5x attack so I can discover a non-starter beast
        game.attack(0);
        game.attack(0);
        game.attack(0);
        game.attack(0);
        game.attack(0);

        let updated_adventurer = game.get_adventurer(0);
        assert(updated_adventurer.get_level() == 2, 'advntr should be lvl 2');
        assert(updated_adventurer.stat_upgrade_available == 1, 'advntr should have 1 stat avl');

        // adventurer trying to explore should cause panic because they have stat upgrade available
        // using #[should_panic] to verify this
        game.explore(0);
    }


    #[test]
    #[available_gas(30000000)]
    fn test_buy_equip() {
        let mut deployed_game = new_adventurer();
        let market_items = @adventurer_market_items();

        let item = ImplLoot::get_item(*market_items.at(0).id);
        let item_price = ImplMarket::get_price(item.tier);

        deployed_game.buy_item(0, *market_items.at(0).id, true);

        let adventurer = deployed_game.get_adventurer(0);

        assert(adventurer.gold == STARTING_GOLD - item_price, 'gold');
        assert(adventurer.waist.id == *market_items.at(0).id, 'sash is equiped');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_get_market_items() {
        let mut deployed_game = new_adventurer();

        let market_items = @adventurer_market_items();

        assert(market_items.len() == 20, 'market items');

        assert(*market_items.at(0).id == 31, 'sash');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_buy_and_bag_item() {
        let mut deployed_game = new_adventurer();
        let market_items = @adventurer_market_items();

        deployed_game.buy_item(0, *market_items.at(0).id, false);

        let bag = deployed_game.get_bag(0);

        assert(bag.item_1.id == *market_items.at(0).id, 'sash in bag');
    }

    #[test]
    #[available_gas(40000000)]
    fn test_equip_item_from_bag() {
        let mut deployed_game = new_adventurer();
        let market_items = @adventurer_market_items();

        deployed_game.buy_item(0, *market_items.at(0).id, false);

        let bag = deployed_game.get_bag(0);
        assert(bag.item_1.id == *market_items.at(0).id, 'sash in bag');

        deployed_game.equip(0, *market_items.at(0).id);

        let adventurer = deployed_game.get_adventurer(0);
        assert(adventurer.waist.id == *market_items.at(0).id, 'sash is equiped');

        // refetch bag to make sure it's empty
        let bag = deployed_game.get_bag(0);

        bag.item_1.id;

        assert(bag.item_1.id == 0, 'sash is still in bag');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_buy_health() {
        let mut deployed_game = new_adventurer();

        deployed_game.purchase_health(0);

        let adventurer = deployed_game.get_adventurer(0);

        assert(adventurer.health == POTION_HEALTH_AMOUNT + STARTING_HEALTH, 'health');
        assert(adventurer.gold == STARTING_GOLD - POTION_PRICE, 'gold');
    }

    #[test]
    #[available_gas(300000000)]
    fn test_entropy() {
        let mut deployed_game = new_adventurer();

        deployed_game.get_entropy();
    }
}
