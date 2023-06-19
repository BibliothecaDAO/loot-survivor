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
    use lootitems::loot::constants::{ItemId};

    use game::game::interfaces::{IGameDispatcherTrait, IGameDispatcher};
    use game::game::game::{Game};
    use survivor::adventurer_meta::{
        AdventurerMetadata, ImplAdventurerMetadata, IAdventurerMetadata
    };

    use survivor::constants::adventurer_constants::{
        STARTING_GOLD, POTION_HEALTH_AMOUNT, POTION_PRICE, STARTING_HEALTH
    };

    use game::game::messages::messages;

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

        adventurer_meta_1.entropy.print();
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
        assert(updated_adventurer.xp > 0, 'advntr should have gained xp');
        assert(updated_adventurer.weapon.xp > 0, 'weapon should have gained xp');
        assert(updated_adventurer.head.xp == 0, 'head should not have gained xp');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_attack() {
        let mut deployed_game = new_adventurer();
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
    #[available_gas(30000000)]
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

        bag.item_1.id.print();

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
    #[should_panic(expected: ('Not enough gold', ))]
    fn test_buy_too_much_health() {
        let mut deployed_game = new_adventurer();

        let mut i = 0;
        loop {
            if i == 21 {
                break;
            }
            deployed_game.purchase_health(0);
            i += 1;
        };
    }
}
