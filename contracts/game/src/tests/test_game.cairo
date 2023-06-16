#[cfg(test)]
mod tests {
    use array::ArrayTrait;
    use core::result::ResultTrait;
    use core::traits::Into;
    use option::OptionTrait;
    use starknet::syscalls::deploy_syscall;
    use traits::TryInto;

    use test::test_utils::assert_eq;

    use lootitems::loot::constants::{ItemId};

    use game::game::game::{IGame, Game, IGameDispatcher, IGameDispatcherTrait};

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

        deployed_game.start(ItemId::Wand);

        let adventurer_1 = @deployed_game.get_adventurer(0);

        deployed_game
    }

    #[test]
    #[available_gas(30000000)]
    fn test_start() {
        let mut deployed_game = new_adventurer();

        let adventurer_1 = @deployed_game.get_adventurer(0);

        // check adventurer
        assert_eq(adventurer_1.weapon.id, @ItemId::Wand, 'weapon');

        // check beast has been assigned
        assert(*adventurer_1.beast_health > 0, 'beast_health');
    // TODO:
    // Check beast is correct
    }

    #[test]
    #[available_gas(30000000)]
    fn test_explore() {
        let mut deployed_game = new_adventurer();

        deployed_game.explore(0);
    }
}
