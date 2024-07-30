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
    use loot::{loot::{Loot, ImplLoot, ILoot}, constants::{ItemId}};
    use game::{
        Game,
        game::{
            interfaces::{IGameDispatcherTrait, IGameDispatcher},
            constants::{
                COST_TO_PLAY, Rewards, REWARD_DISTRIBUTIONS_BP, messages::{STAT_UPGRADES_AVAILABLE},
                STARTER_BEAST_ATTACK_DAMAGE,
            },
        }
    };

    use game::tests::mock_randomness::{
        MockRandomness, IMockRandomnessDispatcher, IMockRandomnessDispatcherTrait
    };
    use combat::{constants::CombatEnums::{Slot, Tier}, combat::ImplCombat};
    use adventurer::{
        stats::Stats, adventurer_meta::{AdventurerMetadata},
        constants::adventurer_constants::{
            STARTING_GOLD, POTION_HEALTH_AMOUNT, BASE_POTION_PRICE, STARTING_HEALTH
        },
        constants::discovery_constants::DiscoveryEnums::ExploreResult,
        adventurer::{Adventurer, ImplAdventurer, IAdventurer}, item::{Item, ImplItem},
        bag::{Bag, IBag}
    };
    use beasts::constants::{BeastSettings, BeastId};

    use game::tests::oz_constants::{
        ZERO, OWNER, SPENDER, RECIPIENT, NAME, SYMBOL, DECIMALS, SUPPLY, VALUE, DATA, OPERATOR,
        OTHER, BASE_URI, TOKEN_ID
    };

    use openzeppelin::tests::utils;
    use openzeppelin::token::erc20::dual20::{DualCaseERC20, DualCaseERC20Trait};
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::utils::serde::SerializedAppend;
    use openzeppelin::token::erc721::dual721::{DualCaseERC721, DualCaseERC721Trait};
    use openzeppelin::token::erc721::interface::IERC721_ID;

    use openzeppelin::token::erc721::interface::{
        IERC721, IERC721Dispatcher, IERC721DispatcherTrait, IERC721LibraryDispatcher,
        IERC721CamelOnlyDispatcher, IERC721CamelOnlyDispatcherTrait
    };

    use starknet::testing::set_caller_address;
    use starknet::testing::set_contract_address;

    const ADVENTURER_ID: felt252 = 1;
    const MAX_LORDS: u256 = 10000000000000000000000000000000000000000;
    const APPROVE: u256 = 10000000000000000000000000000000000000000;
    const DEFAULT_NO_GOLDEN_TOKEN: felt252 = 0;
    const DAY: u64 = 86400;

    fn INTERFACE_ID() -> ContractAddress {
        contract_address_const::<1>()
    }

    fn DAO() -> ContractAddress {
        contract_address_const::<1>()
    }

    fn PG() -> ContractAddress {
        contract_address_const::<1>()
    }

    fn COLLECTIBLE_BEASTS() -> ContractAddress {
        contract_address_const::<1>()
    }

    fn ORACLE_ADDRESS() -> ContractAddress {
        contract_address_const::<1>()
    }

    fn RENDER_CONTRACT() -> ContractAddress {
        contract_address_const::<1>()
    }

    fn ZERO_ADDRESS() -> ContractAddress {
        contract_address_const::<0>()
    }

    fn OWNER_TWO() -> ContractAddress {
        contract_address_const::<2>()
    }

    const PUBLIC_KEY: felt252 = 0x333333;
    const NEW_PUBKEY: felt252 = 0x789789;
    const SALT: felt252 = 123;
    #[derive(Drop)]
    struct SignedTransactionData {
        private_key: felt252,
        public_key: felt252,
        transaction_hash: felt252,
        r: felt252,
        s: felt252
    }

    fn SIGNED_TX_DATA() -> SignedTransactionData {
        SignedTransactionData {
            private_key: 1234,
            public_key: 883045738439352841478194533192765345509759306772397516907181243450667673002,
            transaction_hash: 2717105892474786771566982177444710571376803476229898722748888396642649184538,
            r: 3068558690657879390136740086327753007413919701043650133111397282816679110801,
            s: 3355728545224320878895493649495491771252432631648740019139167265522817576501
        }
    }

    fn setup_lords() -> (DualCaseERC20, IERC20Dispatcher) {
        let lords_name: ByteArray = "LORDS";
        let lords_symbol: ByteArray = "LORDS";
        let lords_supply: u256 = 10000000000000000000000000000000000000000;

        let mut calldata = array![];
        calldata.append_serde(lords_name);
        calldata.append_serde(lords_symbol);
        calldata.append_serde(lords_supply);
        calldata.append_serde(OWNER());
        let target = utils::deploy(SnakeERC20Mock::TEST_CLASS_HASH, calldata);
        (DualCaseERC20 { contract_address: target }, IERC20Dispatcher { contract_address: target })
    }

    fn setup_eth() -> (DualCaseERC20, IERC20Dispatcher) {
        let eth_name: ByteArray = "ETH";
        let eth_symbol: ByteArray = "ETH";
        let eth_supply: u256 = 10000000000000000000000000000000000000000;

        let mut calldata = array![];
        calldata.append_serde(eth_name);
        calldata.append_serde(eth_symbol);
        calldata.append_serde(eth_supply);
        calldata.append_serde(OWNER());
        let target = utils::deploy(SnakeERC20Mock::TEST_CLASS_HASH, calldata);
        (DualCaseERC20 { contract_address: target }, IERC20Dispatcher { contract_address: target })
    }

    fn setup_golden_token() -> (DualCaseERC721, IERC721Dispatcher) {
        let golden_token_name: ByteArray = "GOLDEN_TOKEN";
        let golden_token_symbol: ByteArray = "GLDTKN";
        let TOKEN_ID: u256 = 1;

        let mut calldata = array![];
        calldata.append_serde(golden_token_name);
        calldata.append_serde(golden_token_symbol);
        calldata.append_serde(BASE_URI());
        calldata.append_serde(OWNER());
        calldata.append_serde(TOKEN_ID);
        set_contract_address(OWNER());
        let target = utils::deploy(SnakeERC721Mock::TEST_CLASS_HASH, calldata);
        (
            DualCaseERC721 { contract_address: target },
            IERC721Dispatcher { contract_address: target }
        )
    }

    fn deploy_randomness() -> IMockRandomnessDispatcher {
        let mut calldata = ArrayTrait::<felt252>::new();
        calldata.append(123);
        let contract_address = utils::deploy(MockRandomness::TEST_CLASS_HASH, calldata);
        IMockRandomnessDispatcher { contract_address }
    }

    fn deploy_game(
        lords: ContractAddress,
        eth: ContractAddress,
        golden_token: ContractAddress,
        terminal_block: u64,
        randomness: ContractAddress
    ) -> IGameDispatcher {
        let vrf_level_interval = 3;
        let mut calldata = ArrayTrait::<felt252>::new();
        calldata.append(lords.into());
        calldata.append(eth.into());
        calldata.append(DAO().into());
        calldata.append(PG().into());
        calldata.append(COLLECTIBLE_BEASTS().into());
        calldata.append(golden_token.into());
        calldata.append(terminal_block.into());
        calldata.append(randomness.into());
        calldata.append(vrf_level_interval);
        calldata.append(ORACLE_ADDRESS().into());
        calldata.append(RENDER_CONTRACT().into());

        IGameDispatcher { contract_address: utils::deploy(Game::TEST_CLASS_HASH, calldata) }
    }

    fn setup(
        starting_block: u64, starting_timestamp: u64, terminal_block: u64
    ) -> (IGameDispatcher, IERC20Dispatcher, IERC20Dispatcher, IERC721Dispatcher, ContractAddress) {
        testing::set_block_number(starting_block);
        testing::set_block_timestamp(starting_timestamp);
        testing::set_contract_address(OWNER());

        // deploy lords, eth, and golden token
        let (_, lords) = setup_lords();

        // deploy eth   
        let (_, eth) = setup_eth();

        // deploy golden token
        let (_, golden_token) = setup_golden_token();

        // randomness
        let randomness = deploy_randomness();

        // deploy game
        let game = deploy_game(
            lords.contract_address,
            eth.contract_address,
            golden_token.contract_address,
            terminal_block,
            randomness.contract_address
        );

        // transfer lords to caller address and approve 
        lords.transfer(OWNER(), 100000000000000000000000000000000);
        eth.transfer(OWNER(), 100000000000000000000000000000000);

        // give golden token contract approval to access ETH
        eth.approve(golden_token.contract_address, APPROVE.into());

        lords.transfer(OWNER(), 1000000000000000000000000);

        testing::set_contract_address(OWNER());
        lords.approve(game.contract_address, APPROVE.into());

        (game, lords, eth, golden_token, OWNER())
    }

    fn add_adventurer_to_game(
        ref game: IGameDispatcher, golden_token_id: u256, starting_weapon: u8
    ) -> felt252 {
        let adventurer_id = game
            .new_game(
                INTERFACE_ID(), starting_weapon, 'loothero', golden_token_id, false, ZERO_ADDRESS()
            );

        let new_adventurer = game.get_adventurer(adventurer_id);
        assert(new_adventurer.xp == 0, 'wrong starting xp');
        assert(new_adventurer.equipment.weapon.id == starting_weapon, 'wrong starting weapon');
        assert(
            new_adventurer.beast_health == BeastSettings::STARTER_BEAST_HEALTH.into(),
            'wrong starter beast health '
        );
        adventurer_id
    }

    fn add_level_2_adventurer_to_game(
        ref game: IGameDispatcher, golden_token_id: u256, starting_weapon: u8
    ) -> felt252 {
        let adventurer_id = game
            .new_game(
                INTERFACE_ID(), starting_weapon, 'loothero', golden_token_id, false, ZERO_ADDRESS()
            );

        let new_adventurer = game.get_adventurer(adventurer_id);
        assert(new_adventurer.xp == 0, 'wrong starting xp');
        assert(new_adventurer.equipment.weapon.id == ItemId::Wand, 'wrong starting weapon');
        assert(
            new_adventurer.beast_health == BeastSettings::STARTER_BEAST_HEALTH.into(),
            'wrong starter beast health '
        );
        game.attack(adventurer_id, false);
        adventurer_id
    }

    fn new_adventurer(starting_block: u64, starting_time: u64) -> IGameDispatcher {
        let terminal_block = 0;
        let (mut game, _, _, _, _) = setup(starting_block, starting_time, terminal_block);
        let starting_weapon = ItemId::Wand;
        let name = 'abcdefghijklmno';

        // start new game
        game
            .new_game(
                INTERFACE_ID(),
                starting_weapon,
                name,
                DEFAULT_NO_GOLDEN_TOKEN.into(),
                false,
                ZERO_ADDRESS()
            );

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let adventurer_name = game.get_adventurer_name(ADVENTURER_ID);
        let adventurer_meta_data = game.get_adventurer_meta(ADVENTURER_ID);

        // verify starting weapon
        assert(adventurer.equipment.weapon.id == starting_weapon, 'wrong starting weapon');
        assert(adventurer_name == name, 'wrong player name');
        assert(adventurer_meta_data.birth_date == starting_time, 'wrong birth date');
        assert(adventurer.xp == 0, 'should start with 0 xp');
        assert(
            adventurer.beast_health == BeastSettings::STARTER_BEAST_HEALTH.into(),
            'wrong starter beast health '
        );

        game
    }

    fn new_adventurer_lvl2(
        starting_block: u64, starting_time: u64, starting_entropy: felt252
    ) -> IGameDispatcher {
        // start game
        let mut game = new_adventurer(starting_block, starting_time);

        // attack starter beast
        game.attack(ADVENTURER_ID, false);

        // assert starter beast is dead
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.beast_health == 0, 'should not be in battle');
        assert(adventurer.get_level() == 2, 'should be level 2');
        assert(adventurer.stat_upgrades_available == 1, 'should have 1 stat available');

        // return game
        game
    }

    fn new_adventurer_lvl3(
        starting_block: u64, starting_time: u64, starting_entropy: felt252
    ) -> IGameDispatcher {
        let mut game = new_adventurer_lvl2(starting_block, starting_time, starting_entropy);

        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());

        // go explore
        game.explore(ADVENTURER_ID, true);
        game.flee(ADVENTURER_ID, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 3, 'adventurer should be lvl 3');
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

        // return game
        game
    }

    fn new_adventurer_lvl4(stat: u8) -> IGameDispatcher {
        // start game on lvl 4
        let starting_time = 1696201757;
        let mut game = new_adventurer_lvl3(123, starting_time, 0);

        // upgrade charisma
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: stat,
            dexterity: 0,
            vitality: 0,
            intelligence: 0,
            wisdom: 0,
            charisma: 1,
            luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

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
        let stat_upgrades = Stats {
            strength: stat,
            dexterity: 0,
            vitality: 0,
            intelligence: 0,
            wisdom: 0,
            charisma: 1,
            luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

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

    // fn new_adventurer_lvl6_equipped(stat: u8) -> IGameDispatcher {
    //     let mut game = new_adventurer_lvl5(stat);

    //     let weapon_inventory = @game
    //         .get_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Weapon(())));
    //     let chest_inventory = @game
    //         .get_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Chest(())));
    //     let head_inventory = @game
    //         .get_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Head(())));
    //     let waist_inventory = @game
    //         .get_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Waist(())));
    //     let foot_inventory = @game
    //         .get_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Foot(())));
    //     let hand_inventory = @game
    //         .get_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Hand(())));

    //     let purchase_weapon_id = *weapon_inventory.at(0);
    //     let purchase_chest_id = *chest_inventory.at(2);
    //     let purchase_head_id = *head_inventory.at(2);
    //     let purchase_waist_id = *waist_inventory.at(0);
    //     let purchase_foot_id = *foot_inventory.at(0);
    //     let purchase_hand_id = *hand_inventory.at(0);

    //     let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
    //     shopping_cart.append(ItemPurchase { item_id: purchase_weapon_id, equip: true });
    //     shopping_cart.append(ItemPurchase { item_id: purchase_chest_id, equip: true });
    //     shopping_cart.append(ItemPurchase { item_id: purchase_head_id, equip: true });
    //     shopping_cart.append(ItemPurchase { item_id: purchase_waist_id, equip: true });
    //     shopping_cart.append(ItemPurchase { item_id: purchase_foot_id, equip: true });
    //     shopping_cart.append(ItemPurchase { item_id: purchase_hand_id, equip: true });

    //     let adventurer = game.get_adventurer(ADVENTURER_ID);
    //     assert(
    //         adventurer.equipment.weapon.id == purchase_weapon_id, 'new weapon should be equipped'
    //     );
    //     assert(adventurer.equipment.chest.id == purchase_chest_id, 'new chest should be equipped');
    //     assert(adventurer.equipment.head.id == purchase_head_id, 'new head should be equipped');
    //     assert(adventurer.equipment.waist.id == purchase_waist_id, 'new waist should be equipped');
    //     assert(adventurer.equipment.foot.id == purchase_foot_id, 'new foot should be equipped');
    //     assert(adventurer.equipment.hand.id == purchase_hand_id, 'new hand should be equipped');
    //     assert(adventurer.gold < STARTING_GOLD, 'items should not be free');

    //     // upgrade stats

    //     let stat_upgrades = Stats {
    //         strength: stat,
    //         dexterity: 0,
    //         vitality: 0,
    //         intelligence: 0,
    //         wisdom: 0,
    //         charisma: 1,
    //         luck: 0
    //     };
    //     game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

    //     // go explore
    //     game.explore(ADVENTURER_ID, true);

    //     // verify adventurer is now level 6
    //     let adventurer = game.get_adventurer(ADVENTURER_ID);
    //     assert(adventurer.get_level() == 6, 'adventurer should be lvl 6');

    //     game
    // }

    // fn new_adventurer_lvl7_equipped(stat: u8) -> IGameDispatcher {
    //     let mut game = new_adventurer_lvl6_equipped(stat);
    //     let shopping_cart = ArrayTrait::<ItemPurchase>::new();
    //     let stat_upgrades = Stats {
    //         strength: stat,
    //         dexterity: 0,
    //         vitality: 0,
    //         intelligence: 0,
    //         wisdom: 0,
    //         charisma: 1,
    //         luck: 0
    //     };
    //     game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

    //     // go explore
    //     game.explore(ADVENTURER_ID, true);

    //     let adventurer = game.get_adventurer(ADVENTURER_ID);
    //     assert(adventurer.get_level() == 7, 'adventurer should be lvl 7');

    //     game
    // }

    // fn new_adventurer_lvl8_equipped(stat: u8) -> IGameDispatcher {
    //     let mut game = new_adventurer_lvl7_equipped(stat);
    //     let shopping_cart = ArrayTrait::<ItemPurchase>::new();
    //     let stat_upgrades = Stats {
    //         strength: stat,
    //         dexterity: 0,
    //         vitality: 0,
    //         intelligence: 0,
    //         wisdom: 0,
    //         charisma: 1,
    //         luck: 0
    //     };
    //     game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

    //     // go explore
    //     game.explore(ADVENTURER_ID, true);

    //     let adventurer = game.get_adventurer(ADVENTURER_ID);
    //     assert(adventurer.get_level() == 8, 'adventurer should be lvl 8');

    //     game
    // }

    // fn new_adventurer_lvl9_equipped(stat: u8) -> IGameDispatcher {
    //     let mut game = new_adventurer_lvl8_equipped(stat);
    //     let shopping_cart = ArrayTrait::<ItemPurchase>::new();
    //     let stat_upgrades = Stats {
    //         strength: stat,
    //         dexterity: 0,
    //         vitality: 0,
    //         intelligence: 0,
    //         wisdom: 0,
    //         charisma: 1,
    //         luck: 0
    //     };
    //     game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

    //     // go explore
    //     game.explore(ADVENTURER_ID, true);

    //     let adventurer = game.get_adventurer(ADVENTURER_ID);
    //     assert(adventurer.get_level() == 9, 'adventurer should be lvl 9');

    //     game
    // }

    // fn new_adventurer_lvl10_equipped(stat: u8) -> IGameDispatcher {
    //     let mut game = new_adventurer_lvl9_equipped(stat);
    //     let shopping_cart = ArrayTrait::<ItemPurchase>::new();
    //     let stat_upgrades = Stats {
    //         strength: stat,
    //         dexterity: 0,
    //         vitality: 0,
    //         intelligence: 0,
    //         wisdom: 0,
    //         charisma: 1,
    //         luck: 0
    //     };
    //     game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

    //     // go explore
    //     game.explore(ADVENTURER_ID, true);
    //     game.flee(ADVENTURER_ID, false);
    //     game.explore(ADVENTURER_ID, true);
    //     game.explore(ADVENTURER_ID, true);

    //     let adventurer = game.get_adventurer(ADVENTURER_ID);
    //     assert(adventurer.get_level() == 10, 'adventurer should be lvl 10');

    //     game
    // }

    // fn new_adventurer_lvl11_equipped(stat: u8) -> IGameDispatcher {
    //     let mut game = new_adventurer_lvl10_equipped(stat);
    //     let shopping_cart = ArrayTrait::<ItemPurchase>::new();
    //     let stat_upgrades = Stats {
    //         strength: stat,
    //         dexterity: 0,
    //         vitality: 0,
    //         intelligence: 0,
    //         wisdom: 0,
    //         charisma: 1,
    //         luck: 0
    //     };
    //     game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

    //     // go explore
    //     game.explore(ADVENTURER_ID, true);
    //     game.explore(ADVENTURER_ID, true);
    //     game.explore(ADVENTURER_ID, true);

    //     let adventurer = game.get_adventurer(ADVENTURER_ID);
    //     assert(adventurer.get_level() == 11, 'adventurer should be lvl 11');

    //     game
    // }

    fn new_adventurer_with_lords(starting_block: u64) -> (IGameDispatcher, IERC20Dispatcher) {
        let starting_timestamp = 1;
        let terminal_timestamp = 0;
        let (mut game, lords, _, _, _) = setup(
            starting_block, starting_timestamp, terminal_timestamp
        );
        let starting_weapon = ItemId::Wand;
        let name = 'abcdefghijklmno';

        // start new game
        game
            .new_game(
                INTERFACE_ID(),
                starting_weapon,
                name,
                DEFAULT_NO_GOLDEN_TOKEN.into(),
                false,
                ZERO_ADDRESS()
            );

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let adventurer_name = game.get_adventurer_name(ADVENTURER_ID);
        let adventurer_meta_data = game.get_adventurer_meta(ADVENTURER_ID);

        // verify starting weapon
        assert(adventurer.equipment.weapon.id == starting_weapon, 'wrong starting weapon');
        assert(adventurer_name == name, 'wrong player name');
        assert(adventurer_meta_data.birth_date == starting_timestamp, 'wrong birth date');
        assert(adventurer.xp == 0, 'should start with 0 xp');
        assert(
            adventurer.beast_health == BeastSettings::STARTER_BEAST_HEALTH.into(),
            'wrong starter beast health '
        );

        (game, lords)
    }

    // TODO: need to figure out how to make this more durable
    // #[test]
    // #[available_gas(3000000000000)]
    // fn test_full_game() {
    //     let mut game = new_adventurer_lvl11_equipped(5);
    // }

    #[test]
    #[available_gas(300000000000)]
    fn test_start() {
        let game = new_adventurer(1000, 1696201757);
        game.get_adventurer(ADVENTURER_ID);
        game.get_adventurer_meta(ADVENTURER_ID);
    }

    #[test]
    #[should_panic(expected: ('Action not allowed in battle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(900000000)]
    fn test_no_explore_during_battle() {
        let mut game = new_adventurer(1000, 1696201757);

        // try to explore before defeating start beast
        // should result in a panic 'In battle cannot explore' which
        // is annotated in the test
        game.explore(ADVENTURER_ID, true);
    }
    #[test]
    #[should_panic]
    #[available_gas(90000000)]
    fn test_attack() {
        let mut game = new_adventurer(1000, 1696201757);

        testing::set_block_number(1002);

        let adventurer_start = game.get_adventurer(ADVENTURER_ID);

        // verify starting state
        assert(adventurer_start.health == 100, 'advtr should start with 100hp');
        assert(adventurer_start.xp == 0, 'advtr should start with 0xp');
        assert(
            adventurer_start.beast_health == BeastSettings::STARTER_BEAST_HEALTH.into(),
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
    #[available_gas(23000000)]
    fn test_cant_flee_starter_beast() {
        // start new game
        let mut game = new_adventurer(1000, 1696201757);

        // immediately attempt to flee starter beast
        // which is not allowed and should result in a panic 'Cant flee starter beast'
        // which is annotated in the test
        game.flee(ADVENTURER_ID, false);
    }

    #[test]
    #[should_panic(expected: ('Not in battle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(63000000)]
    fn test_cant_flee_outside_battle() {
        // start adventuer and advance to level 2
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // attempt to flee despite not being in a battle
        // this should trigger a panic 'Not in battle' which is
        // annotated in the test
        game.flee(ADVENTURER_ID, false);
    }

    #[test]
    #[available_gas(247617069000)]
    fn test_explore_distributions() {
        let number_of_games: u16 = 100;
        let mut game = new_adventurer_lvl2(1003, 1696201757, 0);
        let mut game_ids = ArrayTrait::<felt252>::new();
        game_ids.append(1);

        // create 255 new games
        let mut i: u16 = 1;
        loop {
            if (i == number_of_games) {
                break;
            }
            game_ids.append(add_level_2_adventurer_to_game(ref game, 0, ItemId::Wand));
            i += 1;
        };

        // upgrade players in all games
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 1, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        let potions = 0;
        let mut i: u16 = 1;
        loop {
            if (i == number_of_games) {
                break;
            }
            game.upgrade(i.into(), potions, stat_upgrades, shopping_cart.clone());
            i += 1;
        };

        // explore all players in all games
        let mut beasts = 0;
        let mut obstacles = 0;
        let mut discoveries = 0;
        let mut i: u16 = 1;
        loop {
            if (i == number_of_games) {
                break;
            }
            let mut result = game.explore(i.into(), false);
            loop {
                match result.pop_front() {
                    Option::Some(outcome) => {
                        match outcome {
                            ExploreResult::Beast(()) => beasts += 1,
                            ExploreResult::Obstacle(()) => obstacles += 1,
                            ExploreResult::Discovery(()) => discoveries += 1,
                        }
                    },
                    Option::None(_) => { break; }
                };
            };
            i += 1;
        };

        // output results
        // println!("beasts: {}", beasts);
        // println!("obstacles: {}", obstacles);
        // println!("discoveries: {}", discoveries);

        // assert distribution is reasonably close to 33% for each outcome
        let lower_bound = number_of_games / 3 - 10;
        let upper_bound = number_of_games / 3 + 10;
        assert(beasts > lower_bound && beasts < upper_bound, 'beasts distribution is sus');
        assert(obstacles > lower_bound && obstacles < upper_bound, 'obstacles distribution is sus');
        assert(
            discoveries > lower_bound && discoveries < upper_bound,
            'discoveries distribution is sus'
        );
    }

    #[test]
    #[available_gas(13000000000)]
    fn test_flee() {
        // start game on level 2
        let mut game = new_adventurer_lvl2(1003, 1696201757, 0);

        // perform upgrade
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 1, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());

        // go exploring
        game.explore(ADVENTURER_ID, true);

        // verify we found a beast
        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(updated_adventurer.beast_health != 0, 'should have found a beast');

        // flee from beast
        game.flee(ADVENTURER_ID, true);
        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            updated_adventurer.beast_health == 0 || updated_adventurer.health == 0, 'flee or die'
        );
    }

    #[test]
    #[should_panic(expected: ('Stat upgrade available', 'ENTRYPOINT_FAILED'))]
    #[available_gas(7800000000)]
    fn test_explore_not_allowed_with_avail_stat_upgrade() {
        let mut game = new_adventurer(1000, 1696201757);

        // take out starter beast
        game.attack(ADVENTURER_ID, false);

        // get updated adventurer
        let updated_adventurer = game.get_adventurer(ADVENTURER_ID);

        // assert adventurer is now level 2 and has 1 stat upgrade available
        assert(updated_adventurer.get_level() == 2, 'advntr should be lvl 2');
        assert(updated_adventurer.stat_upgrades_available == 1, 'advntr should have 1 stat avl');

        // verify adventurer is unable to explore with stat upgrade available
        // this test is annotated to expect a panic so if it doesn't, this test will fail
        game.explore(ADVENTURER_ID, true);
    }

    #[test]
    #[should_panic(expected: ('level seed not set', 'ENTRYPOINT_FAILED'))]
    fn test_buy_items_during_battle() {
        // mint new adventurer (will start in battle with starter beast)
        let mut game = new_adventurer(1000, 1696201757);

        // get valid item from market
        let market_items = @game.get_market(ADVENTURER_ID);
        let item_id = *market_items.at(0);

        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: true });

        // attempt to buy item during battle - should_panic with message 'Action not allowed in battle'
        // this test is annotated to expect a panic so if it doesn't, this test will fail
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);
    }

    #[test]
    #[should_panic(expected: ('Market is closed', 'ENTRYPOINT_FAILED'))]
    #[available_gas(73000000)]
    fn test_buy_items_without_stat_upgrade() {
        // mint adventurer and advance to level 2
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // get valid item from market
        let market_items = @game.get_market(ADVENTURER_ID);
        let item_id = *market_items.at(0);
        let mut shoppping_cart = ArrayTrait::<ItemPurchase>::new();

        shoppping_cart.append(ItemPurchase { item_id: item_id, equip: true });

        // upgrade adventurer and don't buy anything
        let mut empty_shoppping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, empty_shoppping_cart.clone());

        // after upgrade try to buy item
        // should panic with message 'Market is closed'
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shoppping_cart);
    }

    #[test]
    #[should_panic(expected: ('Item already owned', 'ENTRYPOINT_FAILED'))]
    fn test_buy_duplicate_item_equipped() {
        // start new game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // get items from market
        let market_items = @game.get_market(ADVENTURER_ID);

        // get first item on the market
        let item_id = *market_items.at(3);
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: true });
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: true });

        // submit an upgrade with duplicate items in the shopping cart
        // 'Item already owned' which is annotated in the test
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);
    }

    #[test]
    #[should_panic(expected: ('Item already owned', 'ENTRYPOINT_FAILED'))]
    #[available_gas(61000000)]
    fn test_buy_duplicate_item_bagged() {
        // start new game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // get items from market
        let market_items = @game.get_market(ADVENTURER_ID);

        // try to buy same item but equip one and put one in bag
        let item_id = *market_items.at(0);
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: true });

        // should throw 'Item already owned' panic
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);
    }

    #[test]
    #[should_panic(expected: ('Market item does not exist', 'ENTRYPOINT_FAILED'))]
    #[available_gas(65000000)]
    fn test_buy_item_not_on_market() {
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: 255, equip: false });
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);
    }

    #[test]
    #[available_gas(65000000)]
    fn test_buy_and_bag_item() {
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);
        let market_items = @game.get_market(ADVENTURER_ID);
        let item_id = *market_items.at(0);
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);
        let bag = game.get_bag(ADVENTURER_ID);
        assert(bag.item_1.id == *market_items.at(0), 'item should be in bag');
    }

    #[test]
    #[available_gas(71000000)]
    fn test_buy_items() {
        // start game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // get items from market
        let market_items = @game.get_market(ADVENTURER_ID);

        let mut purchased_weapon: u8 = 0;
        let mut purchased_chest: u8 = 0;
        let mut purchased_head: u8 = 0;
        let mut purchased_waist: u8 = 0;
        let mut purchased_foot: u8 = 0;
        let mut purchased_hand: u8 = 0;
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();

        let mut i: u32 = 0;
        loop {
            if i == market_items.len() {
                break ();
            }
            let market_item_id = *market_items.at(i);
            let market_item_tier = ImplLoot::get_tier(market_item_id);

            if (market_item_tier != Tier::T5(()) && market_item_tier != Tier::T4(())) {
                i += 1;
                continue;
            }

            let market_item_slot = ImplLoot::get_slot(market_item_id);

            // if the item is a weapon and we haven't purchased a weapon yet
            // and the item is a tier 4 or 5 item
            // repeat this for everything
            if (market_item_slot == Slot::Weapon(())
                && purchased_weapon == 0
                && market_item_id != 12) {
                shopping_cart.append(ItemPurchase { item_id: market_item_id, equip: true });
                purchased_weapon = market_item_id;
            } else if (market_item_slot == Slot::Chest(()) && purchased_chest == 0) {
                shopping_cart.append(ItemPurchase { item_id: market_item_id, equip: true });
                purchased_chest = market_item_id;
            } else if (market_item_slot == Slot::Head(()) && purchased_head == 0) {
                shopping_cart.append(ItemPurchase { item_id: market_item_id, equip: true });
                purchased_head = market_item_id;
            } else if (market_item_slot == Slot::Waist(()) && purchased_waist == 0) {
                shopping_cart.append(ItemPurchase { item_id: market_item_id, equip: false });
                purchased_waist = market_item_id;
            } else if (market_item_slot == Slot::Foot(()) && purchased_foot == 0) {
                shopping_cart.append(ItemPurchase { item_id: market_item_id, equip: false });
                purchased_foot = market_item_id;
            } else if (market_item_slot == Slot::Hand(()) && purchased_hand == 0) {
                shopping_cart.append(ItemPurchase { item_id: market_item_id, equip: false });
                purchased_hand = market_item_id;
            }
            i += 1;
        };

        // verify we have at least two items in shopping cart
        let shopping_cart_length = shopping_cart.len();
        assert(shopping_cart_length > 1, 'need more items to buy');

        // buy items in shopping cart
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());

        // get updated adventurer and bag state
        let bag = game.get_bag(ADVENTURER_ID);
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        let mut buy_and_equip_tested = false;
        let mut buy_and_bagged_tested = false;

        // iterate over the items we bought
        let mut i: u32 = 0;
        loop {
            if i == shopping_cart.len() {
                break ();
            }
            let item_purchase = *shopping_cart.at(i);

            // if the item was purchased with equip flag set to true
            if item_purchase.equip {
                // assert it's equipped
                assert(
                    adventurer.equipment.is_equipped(item_purchase.item_id), 'item not equipped'
                );
                buy_and_equip_tested = true;
            } else {
                // if equip was false, verify item is in bag
                let (contains, _) = bag.contains(item_purchase.item_id);
                assert(contains, 'item not in bag');
                buy_and_bagged_tested = true;
            }
            i += 1;
        };

        assert(buy_and_equip_tested, 'did not test buy and equip');
        assert(buy_and_bagged_tested, 'did not test buy and bag');
    }

    #[test]
    #[should_panic(expected: ('Item not in bag', 'ENTRYPOINT_FAILED'))]
    #[available_gas(26022290)]
    fn test_equip_not_in_bag() {
        // start new game
        let mut game = new_adventurer(1000, 1696201757);

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
        let mut game = new_adventurer(1000, 1696201757);

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
    fn test_equip() {
        // start game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2(1002, 1696201757, 0);

        // get items from market
        let market_items = @game.get_market(ADVENTURER_ID);

        let mut purchased_weapon: u8 = 0;
        let mut purchased_chest: u8 = 0;
        let mut purchased_head: u8 = 0;
        let mut purchased_waist: u8 = 0;
        let mut purchased_foot: u8 = 0;
        let mut purchased_hand: u8 = 0;
        let mut purchased_ring: u8 = 0;
        let mut purchased_necklace: u8 = 0;
        let mut purchased_items = ArrayTrait::<u8>::new();
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();

        let mut i: u32 = 0;
        loop {
            if i == market_items.len() {
                break ();
            }
            let item_id = *market_items.at(i);
            let item_slot = ImplLoot::get_slot(item_id);
            let item_tier = ImplLoot::get_tier(item_id);

            // if the item is a weapon and we haven't purchased a weapon yet
            // and the item is a tier 4 or 5 item
            // repeat this for everything
            if (item_slot == Slot::Weapon(())
                && item_tier == Tier::T5(())
                && purchased_weapon == 0
                && item_id != 12) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_weapon = item_id;
            } else if (item_slot == Slot::Chest(())
                && item_tier == Tier::T5(())
                && purchased_chest == 0) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_chest = item_id;
            } else if (item_slot == Slot::Head(())
                && item_tier == Tier::T5(())
                && purchased_head == 0) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_head = item_id;
            } else if (item_slot == Slot::Waist(())
                && item_tier == Tier::T5(())
                && purchased_waist == 0) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_waist = item_id;
            } else if (item_slot == Slot::Foot(())
                && item_tier == Tier::T5(())
                && purchased_foot == 0) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_foot = item_id;
            } else if (item_slot == Slot::Hand(())
                && item_tier == Tier::T5(())
                && purchased_hand == 0) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_hand = item_id;
            } else if (item_slot == Slot::Ring(())
                && purchased_ring == 0
                && item_tier == Tier::T3(())) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_ring = item_id;
            } else if (item_slot == Slot::Neck(()) && purchased_necklace == 0) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_necklace = item_id;
            }
            i += 1;
        };

        let purchased_items_span = purchased_items.span();

        // verify we have at least 2 items in our shopping cart
        assert(shopping_cart.len() >= 2, 'insufficient item purchase');
        // buy items
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

        // get bag from storage
        let bag = game.get_bag(ADVENTURER_ID);

        let mut items_to_equip = ArrayTrait::<u8>::new();
        // iterate over the items we bought
        let mut i: u32 = 0;
        loop {
            if i == purchased_items_span.len() {
                break ();
            }
            // verify they are all in our bag
            let (contains, _) = bag.contains(*purchased_items_span.at(i));
            assert(contains, 'item should be in bag');
            items_to_equip.append(*purchased_items_span.at(i));
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
            if i == items_to_equip.len() {
                break ();
            }
            let (contains, _) = bag.contains(*purchased_items_span.at(i));
            // verify they are no longer in bag
            assert(!contains, 'item should not be in bag');
            // and equipped on the adventurer
            assert(
                adventurer.equipment.is_equipped(*purchased_items_span.at(i)),
                'item should be equipped1'
            );
            i += 1;
        };
    }

    #[test]
    #[available_gas(100000000)]
    fn test_buy_potions() {
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // store original adventurer health and gold before buying potion
        let adventurer_health_pre_potion = adventurer.health;
        let adventurer_gold_pre_potion = adventurer.gold;

        // buy potions
        let number_of_potions = 1;
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 1, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        game.upgrade(ADVENTURER_ID, number_of_potions, stat_upgrades, shopping_cart);

        // get updated adventurer stat
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        // verify potion increased health by POTION_HEALTH_AMOUNT or adventurer health is full
        assert(
            adventurer.health == adventurer_health_pre_potion
                + (POTION_HEALTH_AMOUNT.into() * number_of_potions.into()),
            'potion did not give health'
        );

        // verify potion cost reduced adventurers gold balance
        assert(adventurer.gold < adventurer_gold_pre_potion, 'potion cost is wrong');
    }

    #[test]
    #[should_panic(expected: ('Health already full', 'ENTRYPOINT_FAILED'))]
    #[available_gas(450000000)]
    fn test_buy_potions_exceed_max_health() {
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // get number of potions required to reach full health
        let potions_to_full_health: u8 = (POTION_HEALTH_AMOUNT.into()
            / (adventurer.stats.get_max_health() - adventurer.health))
            .try_into()
            .unwrap();

        // attempt to buy one more potion than is required to reach full health
        // this should result in a panic 'Health already full'
        // this test is annotated to expect that panic
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let potions = potions_to_full_health + 1;
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, potions, stat_upgrades, shopping_cart);
    }

    #[test]
    #[should_panic(expected: ('Market is closed', 'ENTRYPOINT_FAILED'))]
    #[available_gas(100000000)]
    fn test_cant_buy_potion_without_stat_upgrade() {
        // deploy and start new game
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // upgrade adventurer
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());

        // then try to buy potions (should panic with 'Market is closed')
        let potions = 1;
        game.upgrade(ADVENTURER_ID, potions, stat_upgrades, shopping_cart);
    }

    #[test]
    #[should_panic(expected: ('Action not allowed in battle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(100000000)]
    fn test_cant_buy_potion_during_battle() {
        // deploy and start new game
        let mut game = new_adventurer(1000, 1696201757);

        // attempt to immediately buy health before clearing starter beast
        // this should result in contract throwing a panic 'Action not allowed in battle'
        // This test is annotated to expect that panic
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let potions = 1;
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, potions, stat_upgrades, shopping_cart);
    }

    #[test]
    fn test_get_potion_price_underflow() {
        let mut game = new_adventurer(1000, 1696201757);
        let potion_price = game.get_potion_price(ADVENTURER_ID);
        let adventurer_level = game.get_adventurer(ADVENTURER_ID).get_level();
        assert(
            potion_price == BASE_POTION_PRICE.into() * adventurer_level.into(),
            'wrong lvl1 potion price'
        );

        // defeat starter beast and advance to level 2
        game.attack(ADVENTURER_ID, true);

        // get level 2 potion price
        let potion_price = game.get_potion_price(ADVENTURER_ID);
        let mut adventurer = game.get_adventurer(ADVENTURER_ID);
        let adventurer_level = adventurer.get_level();

        // verify potion price
        assert(
            potion_price == (BASE_POTION_PRICE.into() * adventurer_level.into())
                - adventurer.stats.charisma.into(),
            'wrong lvl2 potion price'
        );
    }
    fn already_owned(item_id: u8, adventurer: Adventurer, bag: Bag) -> bool {
        item_id == adventurer.equipment.weapon.id
            || item_id == adventurer.equipment.chest.id
            || item_id == adventurer.equipment.head.id
            || item_id == adventurer.equipment.waist.id
            || item_id == adventurer.equipment.foot.id
            || item_id == adventurer.equipment.hand.id
            || item_id == adventurer.equipment.ring.id
            || item_id == adventurer.equipment.neck.id
            || item_id == bag.item_1.id
            || item_id == bag.item_2.id
            || item_id == bag.item_3.id
            || item_id == bag.item_4.id
            || item_id == bag.item_5.id
            || item_id == bag.item_6.id
            || item_id == bag.item_7.id
            || item_id == bag.item_8.id
            || item_id == bag.item_9.id
            || item_id == bag.item_10.id
            || item_id == bag.item_11.id
            || item_id == bag.item_12.id
            || item_id == bag.item_13.id
            || item_id == bag.item_14.id
            || item_id == bag.item_15.id
    }

    #[test]
    #[available_gas(83000000)]
    fn test_drop_item() {
        // start new game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // get items from market
        let market_items = @game.get_market(ADVENTURER_ID);

        // get first item on the market
        let purchased_item_id = *market_items.at(0);
        let mut shopping_cart = ArrayTrait::<ItemPurchase>::new();
        shopping_cart.append(ItemPurchase { item_id: purchased_item_id, equip: false });

        // buy first item on market and bag it
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        // get bag state
        let bag = game.get_bag(ADVENTURER_ID);

        // assert adventurer has starting weapon equipped
        assert(adventurer.equipment.weapon.id != 0, 'adventurer should have weapon');
        // assert bag has the purchased item
        let (contains, _) = bag.contains(purchased_item_id);
        assert(contains, 'item should be in bag');

        // create drop list consisting of adventurers equipped weapon and purchased item that is in bag
        let mut drop_list = ArrayTrait::<u8>::new();
        drop_list.append(adventurer.equipment.weapon.id);
        drop_list.append(purchased_item_id);

        // call contract drop
        game.drop(ADVENTURER_ID, drop_list);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        // get bag state
        let bag = game.get_bag(ADVENTURER_ID);

        // assert adventurer has no weapon equipped
        assert(adventurer.equipment.weapon.id == 0, 'weapon id should be 0');
        assert(adventurer.equipment.weapon.xp == 0, 'weapon should have no xp');

        // assert bag does not have the purchased item
        let (contains, _) = bag.contains(purchased_item_id);
        assert(!contains, 'item should not be in bag');
    }

    #[test]
    #[should_panic(expected: ('Item not owned by adventurer', 'ENTRYPOINT_FAILED'))]
    #[available_gas(90000000)]
    fn test_drop_item_without_ownership() {
        // start new game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // intialize an array with 20 items in it
        let mut drop_list = ArrayTrait::<u8>::new();
        drop_list.append(255);

        // try to drop an item the adventurer doesn't own
        // this should result in a panic 'Item not owned by adventurer'
        // this test is annotated to expect that panic
        game.drop(ADVENTURER_ID, drop_list);
    }

    #[test]
    #[available_gas(75000000)]
    fn test_upgrade_stats() {
        // deploy and start new game
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let original_charisma = adventurer.stats.charisma;

        // call upgrade_stats with stat upgrades
        // TODO: test with more than one which is challenging
        // because we need a multi-level or G20 stat unlocks
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

        // get update adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // assert charisma was increased
        assert(adventurer.stats.charisma == original_charisma + 1, 'charisma not increased');
        // assert stat point was used
        assert(adventurer.stat_upgrades_available == 0, 'should have used stat point');
    }

    #[test]
    #[should_panic(expected: ('insufficient stat upgrades', 'ENTRYPOINT_FAILED'))]
    #[available_gas(70000000)]
    fn test_upgrade_stats_not_enough_points() {
        // deploy and start new game
        let mut game = new_adventurer_lvl2(1000, 1696201757, 0);

        // try to upgrade charisma x2 with only 1 stat available
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 2, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);
    }

    #[test]
    #[available_gas(75000000)]
    fn test_upgrade_adventurer() {
        // deploy and start new game
        let mut game = new_adventurer_lvl2(1006, 1696201757, 0);

        // get original adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let original_charisma = adventurer.stats.charisma;
        let original_health = adventurer.health;

        // buy a potion
        let potions = 1;

        // buy two items
        let market_inventory = @game.get_market(ADVENTURER_ID);
        let mut items_to_purchase = ArrayTrait::<ItemPurchase>::new();
        let purchase_and_equip = ItemPurchase { item_id: *market_inventory.at(4), equip: true };
        let purchase_and_not_equip = ItemPurchase {
            item_id: *market_inventory.at(3), equip: false
        };
        items_to_purchase.append(purchase_and_equip);
        items_to_purchase.append(purchase_and_not_equip);

        // stat upgrades
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };

        // call upgrade
        game.upgrade(ADVENTURER_ID, potions, stat_upgrades, items_to_purchase);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // assert health was increased by one potion
        assert(
            adventurer.health == original_health + POTION_HEALTH_AMOUNT.into(),
            'health not increased'
        );
        // assert charisma was increased
        assert(adventurer.stats.charisma == original_charisma + 1, 'charisma not increased');
        // assert stat point was used
        assert(adventurer.stat_upgrades_available == 0, 'should have used stat point');
        // assert adventurer has the purchased items
        assert(
            adventurer.equipment.is_equipped(purchase_and_equip.item_id),
            'purchase should be equipped'
        );
        assert(
            !adventurer.equipment.is_equipped(purchase_and_not_equip.item_id),
            'purchase should not be equipped'
        );
    }

    fn _calculate_payout(bp: u256, price: u128) -> u256 {
        (bp * price.into()) / 1000
    }

    // TODO: re-enable this test once we move to Foundry
    // #[test]
    // #[available_gas(90000000)]
    // fn test_bp_distribution() {
    //     let (_, lords) = new_adventurer_with_lords(1000);

    //     // stage 0
    //     assert(lords.balance_of(DAO()) == COST_TO_PLAY.into(), 'wrong stage 1 balance');

    //     // stage 1
    //     testing::set_block_number(1001 + BLOCKS_IN_A_WEEK * 2);

    //     // spawn new

    //     // DAO doesn't get anything more until stage 2
    //     assert(lords.balance_of(DAO()) == COST_TO_PLAY.into(), 'wrong stage 1 balance');

    //     let mut _rewards = Rewards {
    //         BIBLIO: _calculate_payout(REWARD_DISTRIBUTIONS_BP::CREATOR, COST_TO_PLAY),
    //         PG: _calculate_payout(REWARD_DISTRIBUTIONS_BP::CREATOR, COST_TO_PLAY),
    //         CLIENT_PROVIDER: _calculate_payout(
    //             REWARD_DISTRIBUTIONS_BP::CLIENT_PROVIDER, COST_TO_PLAY
    //         ),
    //         FIRST_PLACE: _calculate_payout(REWARD_DISTRIBUTIONS_BP::FIRST_PLACE, COST_TO_PLAY),
    //         SECOND_PLACE: _calculate_payout(REWARD_DISTRIBUTIONS_BP::SECOND_PLACE, COST_TO_PLAY),
    //         THIRD_PLACE: _calculate_payout(REWARD_DISTRIBUTIONS_BP::THIRD_PLACE, COST_TO_PLAY)
    //     };
    // // week.FIRST_PLACE.print();

    // // assert(lords.balance_of(DAO()) == COST_TO_PLAY, 'wrong DAO payout');
    // // assert(week.INTERFACE == 0, 'no payout in stage 1');
    // // assert(week.FIRST_PLACE == _calculate_payout(
    // //         REWARD_DISTRIBUTIONS_PHASE1_BP::FIRST_PLACE, cost_to_play
    // //     ), 'wrong FIRST_PLACE payout 1');
    // // assert(week.SECOND_PLACE == 0x6f05b59d3b200000, 'wrong SECOND_PLACE payout 1');
    // // assert(week.THIRD_PLACE == 0x6f05b59d3b20000, 'wrong THIRD_PLACE payout 1');

    // // (COST_TO_PLAY * 11 / 10).print();
    // // (COST_TO_PLAY * 9 / 10).print();
    // }

    #[test]
    #[available_gas(9000000000)]
    fn test_update_cost_to_play() {}

    #[test]
    #[available_gas(9000000000)]
    #[should_panic(expected: ('terminal time reached', 'ENTRYPOINT_FAILED'))]
    fn test_terminal_timestamp_reached() {
        let starting_block = 1;
        let starting_timestamp = 1;
        let terminal_timestamp = 100;
        let (mut game, _, _, _, _) = setup(starting_block, starting_timestamp, terminal_timestamp);

        // add a player to the game
        add_adventurer_to_game(ref game, 0, ItemId::Wand);
        // advance blockchain timestamp beyond terminal timestamp
        starknet::testing::set_block_timestamp(terminal_timestamp + 1);

        // try to start a new game
        // should panic with 'terminal time reached'
        // which test is annotated to expect
        add_adventurer_to_game(ref game, 0, ItemId::Wand);
    }

    #[test]
    #[available_gas(9000000000)]
    fn test_terminal_timestamp_not_set() {
        let starting_block = 1;
        let starting_timestamp = 1;
        let terminal_timestamp = 0;
        let (mut game, _, _, _, _) = setup(starting_block, starting_timestamp, terminal_timestamp);

        // add a player to the game
        add_adventurer_to_game(ref game, 0, ItemId::Wand);

        // advance blockchain timestamp to max u64
        let max_u64_timestamp = 18446744073709551615;
        starknet::testing::set_block_timestamp(max_u64_timestamp);

        // verify we can still start a new game
        add_adventurer_to_game(ref game, 0, ItemId::Wand);
    }

    #[test]
    #[available_gas(9000000000)]
    fn test_golden_token_new_game() {
        let starting_block = 364063;
        let starting_timestamp = 1698678554;
        let terminal_timestamp = 0;
        let (mut game, _, _, _, _) = setup(starting_block, starting_timestamp, terminal_timestamp);
        add_adventurer_to_game(ref game, 1, ItemId::Wand);
        testing::set_block_timestamp(starting_timestamp + DAY);
        add_adventurer_to_game(ref game, 1, ItemId::Wand);
    }

    // TODO: re-enable this test once we move to Foundry
    // #[test]
    // #[available_gas(9000000000)]
    // fn test_golden_token_can_play() {
    //     let golden_token_id = 1;
    //     let starting_block = 364063;
    //     let starting_timestamp = 1698678554;
    //     let terminal_timestamp = 0;
    //     let (mut game, _, _, _, _) = setup(starting_block, starting_timestamp, terminal_timestamp);
    //     assert(game.can_play(1), 'should be able to play');
    //     add_adventurer_to_game(ref game, golden_token_id, ItemId::Wand);
    //     assert(!game.can_play(1), 'should not be able to play');
    //     testing::set_block_timestamp(starting_timestamp + DAY);
    //     assert(game.can_play(1), 'should be able to play again');
    // }

    // TODO: re-enable this test once we move to Foundry
    // #[test]
    // #[available_gas(9000000000)]
    // #[should_panic(
    //     expected: ('ERC721: invalid token ID', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED')
    // )]
    // fn test_golden_token_unminted_token() {
    //     let golden_token_id = 500;
    //     let starting_block = 364063;
    //     let starting_timestamp = 1698678554;
    //     let terminal_timestamp = 0;
    //     let (mut game, _, _, _, _) = setup(starting_block, starting_timestamp, terminal_timestamp);
    //     add_adventurer_to_game(ref game, golden_token_id, ItemId::Wand);
    // }

    // TODO: re-enable this test once we move to Foundry
    // #[test]
    // #[available_gas(9000000000)]
    // #[should_panic(expected: ('Token already used today', 'ENTRYPOINT_FAILED'))]
    // fn test_golden_token_double_play() {
    //     let golden_token_id = 1;
    //     let starting_block = 364063;
    //     let starting_timestamp = 1698678554;
    //     let terminal_timestamp = 0;
    //     let (mut game, _, _, _, _) = setup(starting_block, starting_timestamp, terminal_timestamp);
    //     add_adventurer_to_game(ref game, golden_token_id, ItemId::Wand);

    //     // roll blockchain forward 1 second less than a day
    //     testing::set_block_timestamp(starting_timestamp + (DAY - 1));

    //     // try to play again with golden token which should cause panic
    //     add_adventurer_to_game(ref game, golden_token_id, ItemId::Wand);
    // }

    #[test]
    #[should_panic(expected: ('Cant drop during starter beast', 'ENTRYPOINT_FAILED'))]
    fn test_no_dropping_starter_weapon_during_starter_beast() {
        let mut game = new_adventurer(1000, 1696201757);

        // try to drop starter weapon during starter beast battle
        let mut drop_items = array![ItemId::Wand];
        game.drop(ADVENTURER_ID, drop_items);
    }

    #[test]
    fn test_drop_starter_item_after_starter_beast() {
        let mut game = new_adventurer(1000, 1696201757);
        game.attack(ADVENTURER_ID, true);

        // try to drop starter weapon during starter beast battle
        let mut drop_items = array![ItemId::Wand];
        game.drop(ADVENTURER_ID, drop_items);
    }

    #[test]
    fn test_different_starter_beasts() {
        let starting_block = 364063;
        let starting_timestamp = 1698678554;
        let (mut game, _, _, _, _) = setup(starting_block, starting_timestamp, 0);
        let mut game_count = game.get_game_count();
        assert(game_count == 0, 'game count should be 0');

        let player1 = add_adventurer_to_game(ref game, 0, ItemId::Wand);
        let starter_beast_game_one = game.get_attacking_beast(player1).id;

        let player2 = add_adventurer_to_game(ref game, 0, ItemId::Wand);
        let starter_beast_game_two = game.get_attacking_beast(player2).id;

        let player3 = add_adventurer_to_game(ref game, 0, ItemId::Wand);
        let starter_beast_game_three = game.get_attacking_beast(player3).id;

        let player4 = add_adventurer_to_game(ref game, 0, ItemId::Wand);
        let starter_beast_game_four = game.get_attacking_beast(player4).id;

        let player5 = add_adventurer_to_game(ref game, 0, ItemId::Wand);
        let starter_beast_game_five = game.get_attacking_beast(player5).id;

        let player6 = add_adventurer_to_game(ref game, 0, ItemId::Wand);
        let starter_beast_game_six = game.get_attacking_beast(player6).id;

        // assert all games starting with a Wand get a T5 Brute for starter beast
        assert(
            starter_beast_game_one >= BeastId::Troll && starter_beast_game_one <= BeastId::Skeleton,
            'wrong starter beast game 1'
        );
        assert(
            starter_beast_game_two >= BeastId::Troll && starter_beast_game_one <= BeastId::Skeleton,
            'wrong starter beast game 2'
        );
        assert(
            starter_beast_game_three >= BeastId::Troll
                && starter_beast_game_one <= BeastId::Skeleton,
            'wrong starter beast game 3'
        );
        assert(
            starter_beast_game_four >= BeastId::Troll
                && starter_beast_game_one <= BeastId::Skeleton,
            'wrong starter beast game 4'
        );
        assert(
            starter_beast_game_five >= BeastId::Troll
                && starter_beast_game_one <= BeastId::Skeleton,
            'wrong starter beast game 5'
        );

        // assert first five games are all unique
        assert(starter_beast_game_one != starter_beast_game_two, 'same starter beast game 1 & 2');
        assert(starter_beast_game_one != starter_beast_game_three, 'same starter beast game 1 & 3');
        assert(starter_beast_game_one != starter_beast_game_four, 'same starter beast game 1 & 4');
        assert(starter_beast_game_one != starter_beast_game_five, 'same starter beast game 1 & 5');
        assert(starter_beast_game_two != starter_beast_game_three, 'same starter beast game 2 & 3');
        assert(starter_beast_game_two != starter_beast_game_four, 'same starter beast game 2 & 4');
        assert(starter_beast_game_two != starter_beast_game_five, 'same starter beast game 2 & 5');
        assert(
            starter_beast_game_three != starter_beast_game_four, 'same starter beast game 3 & 4'
        );
        assert(
            starter_beast_game_three != starter_beast_game_five, 'same starter beast game 3 & 5'
        );
        assert(starter_beast_game_four != starter_beast_game_five, 'same starter beast game 4 & 5');

        // sixth game wraps around and gets same beast as the first game
        assert(starter_beast_game_one == starter_beast_game_six, 'game 1 and 6 should be same');

        // Assert Book start gets T5 Brutes
        add_adventurer_to_game(ref game, 0, ItemId::Book);
        game_count = game.get_game_count();
        let starter_beast_book_start = game.get_attacking_beast(game_count).id;
        assert(game_count == 7, 'game count should be 7');
        assert(
            starter_beast_book_start >= BeastId::Troll
                && starter_beast_book_start <= BeastId::Skeleton,
            'wrong starter beast for book'
        );

        // Assert Club start gets T5 Hunter
        add_adventurer_to_game(ref game, 0, ItemId::Club);
        game_count = game.get_game_count();
        let starter_beast_club_start = game.get_attacking_beast(game_count).id;
        assert(game_count == 8, 'game count should be 8');
        assert(
            starter_beast_club_start >= BeastId::Bear && starter_beast_club_start <= BeastId::Rat,
            'wrong starter beast for club'
        );

        // Assert Club start gets T5 Hunter
        add_adventurer_to_game(ref game, 0, ItemId::ShortSword);
        game_count = game.get_game_count();
        let starter_beast_sword_start = game.get_attacking_beast(game_count).id;
        assert(game_count == 9, 'game count should be 9');
        assert(
            starter_beast_sword_start >= BeastId::Fairy
                && starter_beast_sword_start <= BeastId::Gnome,
            'wrong starter beast for sword'
        );
    }

    fn transfer_ownership(mut game: IGameDispatcher, from: ContractAddress, to: ContractAddress) {
        // Some weird conflict when using the game interface ?? using direct ERC721Dispatcher for now. This is not a problem in blockexplorers, I suspect issue in Scarb compiler.
        IERC721Dispatcher { contract_address: game.contract_address }
            .transfer_from(from, to, ADVENTURER_ID.into());
    }

    #[test]
    fn test_transfered_attack() {
        let mut game = new_adventurer(364063, 1698678554);
        transfer_ownership(game, OWNER(), OWNER_TWO());
        testing::set_contract_address(OWNER_TWO());
        game.attack(ADVENTURER_ID, false);
    }


    #[test]
    #[should_panic(expected: ('Not authorized to act', 'ENTRYPOINT_FAILED'))]
    fn test_original_owner_attack() {
        let mut game = new_adventurer(364063, 1698678554);
        transfer_ownership(game, OWNER(), OWNER_TWO());
        game.attack(ADVENTURER_ID, false);
    }


    #[test]
    #[should_panic(expected: ('Not authorized to act', 'ENTRYPOINT_FAILED'))]
    fn test_original_owner_upgrade() {
        let mut game = new_adventurer_lvl2(364063, 1698678554, 0);
        transfer_ownership(game, OWNER(), OWNER_TWO());

        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());
    }

    #[test]
    #[should_panic(expected: ('Not authorized to act', 'ENTRYPOINT_FAILED'))]
    fn test_original_owner_explore() {
        let mut game = new_adventurer_lvl2(364063, 1698678554, 0);
        transfer_ownership(game, OWNER(), OWNER_TWO());
        testing::set_contract_address(OWNER_TWO());

        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());

        testing::set_contract_address(OWNER());

        game.explore(ADVENTURER_ID, true);
    }

    #[test]
    #[should_panic(expected: ('Not authorized to act', 'ENTRYPOINT_FAILED'))]
    fn test_original_owner_flee() {
        let mut game = new_adventurer_lvl2(364063, 1698678554, 0);
        transfer_ownership(game, OWNER(), OWNER_TWO());
        testing::set_contract_address(OWNER_TWO());

        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());

        // go explore
        game.explore(ADVENTURER_ID, true);

        testing::set_contract_address(OWNER());

        game.flee(ADVENTURER_ID, true);
    }


    #[test]
    fn test_transfered_upgrade_explore_flee() {
        let mut game = new_adventurer_lvl2(123, 1696201757, 0);
        transfer_ownership(game, OWNER(), OWNER_TWO());
        testing::set_contract_address(OWNER_TWO());

        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 1, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());

        // go explore
        game.explore(ADVENTURER_ID, true);
        game.flee(ADVENTURER_ID, true);
    }

    // verify tokens transferred to transfered owner not original owner
    #[test]
    fn test_transfered_transfer() {
        let mut game = new_adventurer(364063, 1698678554);
        transfer_ownership(game, OWNER(), OWNER_TWO());
    }


    #[starknet::contract]
    mod SnakeERC20Mock {
        use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
        use starknet::ContractAddress;

        component!(path: ERC20Component, storage: erc20, event: ERC20Event);

        #[abi(embed_v0)]
        impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
        #[abi(embed_v0)]
        impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
        impl InternalImpl = ERC20Component::InternalImpl<ContractState>;

        #[storage]
        struct Storage {
            #[substorage(v0)]
            erc20: ERC20Component::Storage
        }

        #[event]
        #[derive(Drop, starknet::Event)]
        enum Event {
            #[flat]
            ERC20Event: ERC20Component::Event
        }

        #[constructor]
        fn constructor(
            ref self: ContractState,
            name: ByteArray,
            symbol: ByteArray,
            initial_supply: u256,
            recipient: ContractAddress
        ) {
            self.erc20.initializer(name, symbol);
            self.erc20.mint(recipient, initial_supply);
        }
    }

    #[starknet::contract]
    mod SnakeERC721Mock {
        use openzeppelin::introspection::src5::SRC5Component;
        use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
        use starknet::ContractAddress;

        component!(path: ERC721Component, storage: erc721, event: ERC721Event);
        component!(path: SRC5Component, storage: src5, event: SRC5Event);

        // ERC721
        #[abi(embed_v0)]
        impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
        #[abi(embed_v0)]
        impl ERC721MetadataImpl =
            ERC721Component::ERC721MetadataImpl<ContractState>;
        impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

        // SRC5
        #[abi(embed_v0)]
        impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

        #[storage]
        struct Storage {
            #[substorage(v0)]
            erc721: ERC721Component::Storage,
            #[substorage(v0)]
            src5: SRC5Component::Storage
        }

        #[event]
        #[derive(Drop, starknet::Event)]
        enum Event {
            #[flat]
            ERC721Event: ERC721Component::Event,
            #[flat]
            SRC5Event: SRC5Component::Event
        }

        #[constructor]
        fn constructor(
            ref self: ContractState,
            name: ByteArray,
            symbol: ByteArray,
            base_uri: ByteArray,
            recipient: ContractAddress,
            token_id: u256
        ) {
            self.erc721.initializer(name, symbol, base_uri);
            self.erc721.mint(recipient, token_id);
        }
    }

    #[test]
    fn test_set_adventurer_obituary() {
        // Setup
        let starting_block = 1000;
        let starting_time = 1696201757;
        let (mut game, _, _, _, _) = setup(starting_block, starting_time, 0);

        // Create a new adventurer
        let adventurer_id = 1;
        add_adventurer_to_game(ref game, 0, ItemId::Wand);

        // defeat starter beast
        game.attack(adventurer_id, false);

        // don't buy anything from market
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(adventurer_id, 0, stat_upgrades, shopping_cart.clone());
        game.explore(adventurer_id, true);
        let death_date = starting_time + 1000;
        testing::set_block_timestamp(death_date);
        game.attack(adventurer_id, true);

        let mut metadata = game.get_adventurer_meta(adventurer_id);
        assert(metadata.death_date == death_date, 'Death date not set correctly');

        // Set obituary
        let obituary: ByteArray = "Brave adventurer fell to a mighty beast";
        game.set_adventurer_obituary(adventurer_id, obituary.clone());

        // Verify obituary was set
        let stored_obituary = game.get_adventurer_obituary(adventurer_id);
        assert(obituary == stored_obituary, 'Obituary not set correctly');
    }

    #[test]
    #[should_panic(expected: ('obituary already set', 'ENTRYPOINT_FAILED'))]
    fn test_set_adventurer_obituary_twice() {
        // Setup
        let starting_block = 1000;
        let starting_time = 1696201757;
        let (mut game, _, _, _, _) = setup(starting_block, starting_time, 0);

        // Create a new adventurer
        let adventurer_id = 1;
        add_adventurer_to_game(ref game, 0, ItemId::Wand);

        // defeat starter beast
        game.attack(adventurer_id, false);

        // don't buy anything from market
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(adventurer_id, 0, stat_upgrades, shopping_cart.clone());
        game.explore(adventurer_id, true);
        let death_date = starting_time + 1000;
        testing::set_block_timestamp(death_date);
        game.attack(adventurer_id, true);

        let mut metadata = game.get_adventurer_meta(adventurer_id);
        assert(metadata.death_date == death_date, 'Death date not set correctly');

        // Set obituary
        let obituary: ByteArray = "Brave adventurer fell to a mighty beast";
        game.set_adventurer_obituary(adventurer_id, obituary.clone());

        // Attempt to set obituary again
        // should panic
        let obituary_two: ByteArray = "Brave adventurer fell to a mighty obstacle";
        game.set_adventurer_obituary(adventurer_id, obituary_two.clone());
    }

    #[test]
    #[should_panic(expected: ('obituary window closed', 'ENTRYPOINT_FAILED'))]
    fn test_set_adventurer_obituary_after_window_closed() {
        // Setup
        let starting_block = 1000;
        let starting_time = 1696201757;
        let (mut game, _, _, _, _) = setup(starting_block, starting_time, 0);

        // Create a new adventurer
        let adventurer_id = 1;
        add_adventurer_to_game(ref game, 0, ItemId::Wand);

        // defeat starter beast
        game.attack(adventurer_id, false);

        // don't buy anything from market
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(adventurer_id, 0, stat_upgrades, shopping_cart.clone());
        game.explore(adventurer_id, true);
        let death_date = starting_time + 1000;
        testing::set_block_timestamp(death_date);
        game.attack(adventurer_id, true);

        let mut metadata = game.get_adventurer_meta(adventurer_id);
        assert(metadata.death_date == death_date, 'Death date not set correctly');

        // increase the blockchain to 1s past the obituary window
        testing::set_block_timestamp(
            death_date + (Game::OBITUARY_EXPIRY_DAYS.into() * Game::SECONDS_IN_DAY.into()) + 1
        );

        // attempt to set obituary
        // should panic
        let obituary: ByteArray = "Brave adventurer fell to a mighty beast";
        game.set_adventurer_obituary(adventurer_id, obituary.clone());
    }

    #[test]
    #[should_panic(expected: ('Adventurer is still alive', 'ENTRYPOINT_FAILED'))]
    fn test_set_adventurer_obituary_still_alive() {
        // Setup
        let starting_block = 1000;
        let starting_time = 1696201757;
        let (mut game, _, _, _, _) = setup(starting_block, starting_time, 0);

        // Create a new adventurer
        let adventurer_id = 1;
        add_adventurer_to_game(ref game, 0, ItemId::Wand);

        // defeat starter beast
        game.attack(adventurer_id, false);

        // attempt to set obituary
        // should panic
        let obituary: ByteArray = "Brave adventurer fell to a mighty beast";
        game.set_adventurer_obituary(adventurer_id, obituary.clone());
    }

    #[test]
    fn test_dead_adventurer_metadata() {
        // Setup
        let starting_block = 1000;
        let starting_time = 1696201757;
        let (mut game, _, _, _, _) = setup(starting_block, starting_time, 0);

        // Create a new adventurer
        let adventurer_id = 1;
        add_adventurer_to_game(ref game, 0, ItemId::Wand);

        // defeat starter beast
        game.attack(adventurer_id, false);

        // don't buy anything from market
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(adventurer_id, 0, stat_upgrades, shopping_cart.clone());
        game.explore(adventurer_id, true);
        let death_date = starting_time + 1000;
        testing::set_block_timestamp(death_date);
        game.attack(adventurer_id, true);

        // check adventurer metadata to ensure birth date and death date are correct
        let mut metadata = game.get_adventurer_meta(adventurer_id);
        assert(metadata.death_date == death_date, 'Death date not set correctly');
        assert(metadata.birth_date == starting_time, 'Birth date not set correctly');
    }

    #[test]
    fn test_adventurer_death_ranking() {
        // Setup
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        let starting_block = 1000;
        let mut current_block_time = 1696201757;
        let (mut game, _, _, _, _) = setup(starting_block, current_block_time, 0);

        // Create a new adventurer
        current_block_time += 777;
        let player1_birth_date = current_block_time;
        testing::set_block_timestamp(current_block_time);
        let player1 = add_adventurer_to_game(ref game, 0, ItemId::Wand);
        game.attack(player1, false);
        game.upgrade(player1, 0, stat_upgrades, shopping_cart.clone());
        game.explore(player1, true);
        current_block_time += 1000;
        let player1_death_date = current_block_time; 
        testing::set_block_timestamp(current_block_time);
        game.attack(player1, true);

        // assert adventurer metadata and leaderboard
        let player1_metadata = game.get_adventurer_meta(player1);
        let leaderboard = game.get_leaderboard();
        assert(player1_metadata.birth_date == player1_birth_date, 'Birth date not set correctly');
        assert(player1_metadata.death_date == player1_death_date, 'Death date not set correctly');
        assert(player1_metadata.rank_at_death == 1, 'Rank at death not set correctly');
        assert(leaderboard.first.adventurer_id.into() == player1, 'player1 should be 1st place');

        // introduce second player (new top score)
        current_block_time += 777;
        let player2_birth_date = current_block_time;
        testing::set_block_timestamp(current_block_time);
        let player2 = add_adventurer_to_game(ref game, 0, ItemId::Wand);
        game.attack(player2, false);
        game.upgrade(player2, 1, stat_upgrades, shopping_cart.clone());
        game.explore(player2, true);
        current_block_time += 777;
        let player2_death_date = current_block_time;
        testing::set_block_timestamp(current_block_time);
        game.upgrade(player2, 1, stat_upgrades, shopping_cart.clone());
        game.explore(player2, true);
        game.attack(player2, true);

        // assert adventurer metadata and leaderboard
        let player1_metadata = game.get_adventurer_meta(player1);
        let player2_metadata = game.get_adventurer_meta(player2);
        let leaderboard = game.get_leaderboard();
        assert(player2_metadata.birth_date == player2_birth_date, 'Birth date not set correctly');
        assert(player2_metadata.death_date == player2_death_date, 'Death date not set correctly');
        assert(player2_metadata.rank_at_death == 1, 'P2 should be death rank 1');
        assert(player1_metadata.rank_at_death == 1, 'P1 should be death rank 1');
        assert(leaderboard.first.adventurer_id.into() == player2, 'P2 should be 1st on LB');
        assert(leaderboard.second.adventurer_id.into() == player1, 'P1 should be 2nd on LB');

        // introduce third player (new top score)
        current_block_time += 777;
        let player3_birth_date = current_block_time;
        testing::set_block_timestamp(current_block_time);
        let player3 = add_adventurer_to_game(ref game, 0, ItemId::Wand);
        game.attack(player3, false);
        let stat_upgrades = Stats {
            strength: 0, dexterity: 1, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        game.upgrade(player3, 1, stat_upgrades, shopping_cart.clone());
        game.explore(player3, true);
        game.flee(player3, true);
        game.explore(player3, true);
        game.upgrade(player3, 0, stat_upgrades, shopping_cart.clone());
        game.explore(player3, true);
        game.upgrade(player3, 0, stat_upgrades, shopping_cart.clone());
        game.explore(player3, true);
        game.attack(player3, true);
        game.explore(player3, true);
        game.upgrade(player3, 0, stat_upgrades, shopping_cart.clone());
        game.explore(player3, true);
        current_block_time += 777;
        let player3_death_date = current_block_time;
        testing::set_block_timestamp(current_block_time);
        game.attack(player3, true);

        // assert adventurer metadata and leaderboard
        let player3_metadata = game.get_adventurer_meta(player3);
        let player2_metadata = game.get_adventurer_meta(player2);
        let player1_metadata = game.get_adventurer_meta(player1);
        let leaderboard = game.get_leaderboard();
        assert(player3_metadata.death_date == player3_death_date, 'P3 death date not set correctly');
        assert(player3_metadata.birth_date == player3_birth_date, 'P3 birth date not set correctly');
        assert(player3_metadata.rank_at_death == 1, 'P3 should be death rank 1');
        assert(player2_metadata.rank_at_death == 1, 'P2 should be death rank 1');
        assert(player1_metadata.rank_at_death == 1, 'P1 should be death rank 1');
        assert(leaderboard.first.adventurer_id.into() == player3, 'P3 should be 1st on LB');
        assert(leaderboard.second.adventurer_id.into() == player2, 'P2 should be 2nd on LB');
        assert(leaderboard.third.adventurer_id.into() == player1, 'P1 should be 3rd on LB');

        // introduce fourth player (2nd place finish)
        current_block_time += 777;
        let player4_birth_date = current_block_time;
        testing::set_block_timestamp(current_block_time);
        let player4 = add_adventurer_to_game(ref game, 0, ItemId::Wand);
        game.attack(player4, false);
        game.upgrade(player4, 0, stat_upgrades, shopping_cart.clone());
        game.explore(player4, true);
        game.upgrade(player4, 0, stat_upgrades, shopping_cart.clone());
        game.explore(player4, true);
        game.attack(player4, true);
        game.explore(player4, true);
        game.upgrade(player4, 0, stat_upgrades, shopping_cart.clone());
        game.explore(player4, true);
        current_block_time += 777;
        let player4_death_date = current_block_time;
        testing::set_block_timestamp(current_block_time);
        game.attack(player4, true);

        // assert adventurer metadata and leaderboard
        let player1_metadata = game.get_adventurer_meta(player1);
        let player2_metadata = game.get_adventurer_meta(player2);
        let player3_metadata = game.get_adventurer_meta(player3);
        let player4_metadata = game.get_adventurer_meta(player4);
        let leaderboard = game.get_leaderboard();
        assert(player4_metadata.birth_date == player4_birth_date, 'P4 birth date not set correctly');
        assert(player4_metadata.death_date == player4_death_date, 'P4 death date not set correctly');
        assert(player4_metadata.rank_at_death == 2, 'P4 should be death rank 2');
        assert(player3_metadata.rank_at_death == 1, 'P3 should be death rank 1');
        assert(player2_metadata.rank_at_death == 1, 'P2 should be death rank 1');
        assert(player1_metadata.rank_at_death == 1, 'P1 should be death rank 1');
        assert(leaderboard.first.adventurer_id.into() == player3, 'P3 should be 1st on LB');
        assert(leaderboard.second.adventurer_id.into() == player4, 'P4 should be 2nd on LB');
        assert(leaderboard.third.adventurer_id.into() == player2, 'P2 should be 3rd on LB');
    }
}
