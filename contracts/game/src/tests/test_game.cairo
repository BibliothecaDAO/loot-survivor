#[cfg(test)]
mod tests {
    use array::ArrayTrait;
    use core::result::ResultTrait;
    use core::traits::Into;
    use option::OptionTrait;
    use starknet::syscalls::deploy_syscall;
    use traits::TryInto;
    use debug::PrintTrait;

    use lootitems::loot::constants::{ItemId};

    use game::game::game::{IGame, Game, IGameDispatcher, IGameDispatcherTrait};
    use survivor::adventurer_meta::{
        AdventurerMetadata, ImplAdventurerMetadata, IAdventurerMetadata
    };

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

        deployed_game.explore(0);
    }
}
