#[cfg(test)]
mod tests {
    use arcade_account::{Account, TRANSACTION_VERSION};
    use arcade_account::tests::utils::helper_contracts::{
        ISimpleTestContractDispatcher, ISimpleTestContractDispatcherTrait, simple_test_contract,
    };
    use arcade_account::account::interface::{
        IMasterControl, IMasterControlDispatcher, IMasterControlDispatcherTrait,
        ArcadeAccountABIDispatcher, ArcadeAccountABIDispatcherTrait,
        ArcadeAccountCamelABIDispatcher, ArcadeAccountCamelABIDispatcherTrait,
    };
    use game_entropy::game_entropy::IGameEntropy;
    use array::ArrayTrait;
    use core::{result::ResultTrait, traits::Into, array::SpanTrait, serde::Serde, clone::Clone};
    use option::OptionTrait;
    use starknet::{
        syscalls::deploy_syscall, testing, ContractAddress, ContractAddressIntoFelt252,
        contract_address_const
    };
    use traits::TryInto;
    use box::BoxTrait;
    use openzeppelin::token::erc20::interface::{
        IERC20Camel, IERC20CamelDispatcher, IERC20CamelDispatcherTrait, IERC20CamelLibraryDispatcher
    };
    use openzeppelin::token::erc20::erc20::ERC20;
    use market::market::{ImplMarket, LootWithPrice, ItemPurchase};
    use lootitems::{loot::{Loot, ImplLoot, ILoot}, constants::{ItemId}};
    use game::{
        Game,
        game::{
            interfaces::{IGameDispatcherTrait, IGameDispatcher},
            constants::{
                COST_TO_PLAY, BLOCKS_IN_A_WEEK, Rewards, REWARD_DISTRIBUTIONS_PHASE1_BP,
                REWARD_DISTRIBUTIONS_PHASE2_BP, REWARD_DISTRIBUTIONS_PHASE3_BP,
                messages::{STAT_UPGRADES_AVAILABLE}, STARTER_BEAST_ATTACK_DAMAGE,
                MAINNET_REVEAL_DELAY_BLOCKS
            },
        }
    };
    use openzeppelin::utils::serde::SerializedAppend;
    use openzeppelin::tests::mocks::camel20_mock::CamelERC20Mock;
    use openzeppelin::tests::utils;
    use combat::{constants::CombatEnums::{Slot, Tier}, combat::ImplCombat};
    use survivor::{
        stats::Stats, adventurer_meta::{AdventurerMetadata},
        constants::adventurer_constants::{
            STARTING_GOLD, POTION_HEALTH_AMOUNT, POTION_PRICE, STARTING_HEALTH, MAX_BLOCK_COUNT
        },
        adventurer::{Adventurer, ImplAdventurer, IAdventurer}, item_primitive::ItemPrimitive,
        bag::{Bag, IBag}, adventurer_utils::AdventurerUtils
    };
    use beasts::constants::{BeastSettings, BeastId};

    fn INTERFACE_ID() -> ContractAddress {
        contract_address_const::<1>()
    }

    fn DAO() -> ContractAddress {
        contract_address_const::<1>()
    }

    fn COLLECTIBLE_BEASTS() -> ContractAddress {
        contract_address_const::<1>()
    }

    const ADVENTURER_ID: felt252 = 1;

    const MAX_LORDS: u256 = 10000000000000000000000000000000000000000;
    const APPROVE: u256 = 10000000000000000000000000000000000000000;
    const NAME: felt252 = 111;
    const SYMBOL: felt252 = 222;

    const DEFAULT_NO_GOLDEN_TOKEN: felt252 = 0;

    const DAY: u64 = 86400;

    fn OWNER() -> ContractAddress {
        contract_address_const::<10>()
    }

    use goldenToken::ERC721::{
        GoldenToken, GoldenTokenDispatcher, GoldenTokenDispatcherTrait, GoldenTokenLibraryDispatcher
    };


    fn deploy_golden_token(eth: ContractAddress) -> GoldenTokenDispatcher {
        let mut calldata = ArrayTrait::new();
        calldata.append(NAME);
        calldata.append(SYMBOL);
        calldata.append(OWNER().into());
        calldata.append(DAO().into());
        calldata.append(eth.into());

        let (golden_token, _) = deploy_syscall(
            goldenToken::ERC721::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();

        GoldenTokenDispatcher { contract_address: golden_token }
    }

    fn deploy_lords() -> ContractAddress {
        let mut calldata = array![];
        calldata.append_serde(NAME);
        calldata.append_serde(SYMBOL);
        calldata.append_serde(MAX_LORDS);
        calldata.append_serde(OWNER());

        let lords0 = utils::deploy(CamelERC20Mock::TEST_CLASS_HASH, calldata);

        lords0
    }

    fn deploy_eth() -> ContractAddress {
        let mut calldata = array![];
        // we just need an erc20 for ETH, details don't matter for test purposes
        calldata.append_serde(NAME);
        calldata.append_serde(SYMBOL);
        calldata.append_serde(MAX_LORDS);
        calldata.append_serde(OWNER());
        utils::deploy(CamelERC20Mock::TEST_CLASS_HASH, calldata)
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

    fn AA_CLASS_HASH() -> felt252 {
        Account::TEST_CLASS_HASH
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

    fn deploy_arcade_account(data: Option<@SignedTransactionData>) -> ContractAddress {
        // Set the transaction version
        testing::set_version(TRANSACTION_VERSION);

        let mut calldata = array![];
        let mut public_key = PUBLIC_KEY;

        if data.is_some() {
            // set public key
            let _data = data.unwrap();
            public_key = *_data.public_key;

            // Set the signature and transaction hash
            let mut signature = array![];
            signature.append(*_data.r);
            signature.append(*_data.s);
            testing::set_signature(signature.span());
            testing::set_transaction_hash(*_data.transaction_hash);
        }

        // add constructor parameters to calldata
        Serde::serialize(@public_key, ref calldata);
        Serde::serialize(@starknet::get_contract_address(), ref calldata);

        // Deploy the account contract
        utils::deploy(AA_CLASS_HASH(), calldata)
    }

    fn setup(
        starting_block: u64, starting_timestamp: u64, terminal_block: u64
    ) -> (IGameDispatcher, IERC20CamelDispatcher, GoldenTokenDispatcher, ContractAddress) {
        testing::set_block_number(starting_block);
        testing::set_block_timestamp(starting_timestamp);

        // deploy lords, eth, and golden token
        let lords = deploy_lords();
        let eth = deploy_eth();
        let golden_token = deploy_golden_token(eth);

        // format call data and deploy loot survivor
        let mut calldata = ArrayTrait::new();
        calldata.append(lords.into());
        calldata.append(DAO().into());
        calldata.append(COLLECTIBLE_BEASTS().into());
        calldata.append(golden_token.contract_address.into());
        calldata.append(terminal_block.into());
        let (address0, _) = deploy_syscall(
            Game::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();

        // set contract address (aka caller) to specific address
        testing::set_contract_address(OWNER());

        // transfer lords to caller address and approve 
        let lords_contract = IERC20CamelDispatcher { contract_address: lords };
        let eth_contract = IERC20CamelDispatcher { contract_address: eth };
        lords_contract.transfer(OWNER(), 100000000000000000000000000000000);
        eth_contract.transfer(OWNER(), 100000000000000000000000000000000);

        // give golden token contract approval to access ETH
        eth_contract.approve(golden_token.contract_address, APPROVE.into());
        // open golden token open edition
        golden_token.open();
        // mint golden token
        golden_token.mint();

        let arcade_account = ArcadeAccountABIDispatcher {
            contract_address: deploy_arcade_account(Option::None(()))
        };
        let master_control_dispatcher = IMasterControlDispatcher {
            contract_address: arcade_account.contract_address
        };

        master_control_dispatcher.update_whitelisted_contracts(array![(address0, true)]);

        lords_contract.transfer(arcade_account.contract_address, 1000000000000000000000000);

        testing::set_contract_address(arcade_account.contract_address);
        lords_contract.approve(address0, APPROVE.into());
        (
            IGameDispatcher { contract_address: address0 },
            lords_contract,
            golden_token,
            arcade_account.contract_address
        )
    }

    fn add_adventurer_to_game(ref game: IGameDispatcher, golden_token_id: u256) {
        game.new_game(INTERFACE_ID(), ItemId::Wand, 'loothero', golden_token_id, false);

        let original_adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(original_adventurer.xp == 0, 'wrong starting xp');
        assert(original_adventurer.weapon.id == ItemId::Wand, 'wrong starting weapon');
        assert(
            original_adventurer.beast_health == BeastSettings::STARTER_BEAST_HEALTH,
            'wrong starter beast health '
        );
    }

    fn new_adventurer(starting_block: u64, starting_time: u64) -> IGameDispatcher {
        let terminal_block = 0;
        let (mut game, lords, _, _) = setup(starting_block, starting_time, terminal_block);
        let starting_weapon = ItemId::Wand;
        let name = 'abcdefghijklmno';

        // start new game
        game.new_game(INTERFACE_ID(), starting_weapon, name, DEFAULT_NO_GOLDEN_TOKEN.into(), false);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let adventurer_meta_data = game.get_adventurer_meta(ADVENTURER_ID);

        // verify starting weapon
        assert(adventurer.weapon.id == starting_weapon, 'wrong starting weapon');
        assert(adventurer_meta_data.name == name, 'wrong player name');
        assert(adventurer.xp == 0, 'should start with 0 xp');
        assert(
            adventurer.beast_health == BeastSettings::STARTER_BEAST_HEALTH,
            'wrong starter beast health '
        );

        game
    }

    fn new_adventurer_lvl2_with_idle_penalty() -> IGameDispatcher {
        // start game on block number 1
        let mut game = new_adventurer(1000, 1696201757);

        // fast forward chain to block number 400
        testing::set_block_number(1002);

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

    fn new_adventurer_lvl2(starting_block: u64, starting_time: u64) -> IGameDispatcher {
        // start game
        let mut game = new_adventurer(starting_block, starting_time);

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

    fn new_adventurer_lvl3(starting_block: u64) -> IGameDispatcher {
        // start game on lvl 2
        let starting_time = 1696201757;
        let mut game = new_adventurer_lvl2(starting_block, starting_time);

        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);

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
        let mut game = new_adventurer_lvl3(123);

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

    fn new_adventurer_lvl6_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl5(stat);
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        let weapon_inventory = @game
            .get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Weapon(())));
        let chest_inventory = @game
            .get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Chest(())));
        let head_inventory = @game
            .get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Head(())));
        let waist_inventory = @game
            .get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Waist(())));
        let foot_inventory = @game
            .get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Foot(())));
        let hand_inventory = @game
            .get_items_on_market_by_slot(ADVENTURER_ID, ImplCombat::slot_to_u8(Slot::Hand(())));

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

        // verify adventurer is now level 6
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 6, 'adventurer should be lvl 6');

        game
    }

    fn new_adventurer_lvl7_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl6_equipped(stat);
        let STRENGTH: u8 = 0;
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

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 7, 'adventurer should be lvl 7');

        game
    }

    fn new_adventurer_lvl8_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl7_equipped(stat);
        let STRENGTH: u8 = 0;
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

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 8, 'adventurer should be lvl 8');

        game
    }

    fn new_adventurer_lvl9_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl8_equipped(stat);
        let STRENGTH: u8 = 0;
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

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 9, 'adventurer should be lvl 9');

        game
    }

    fn new_adventurer_lvl10_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl9_equipped(stat);
        let STRENGTH: u8 = 0;
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
        game.explore(ADVENTURER_ID, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 10, 'adventurer should be lvl 10');

        game
    }

    fn new_adventurer_lvl11_equipped(stat: u8) -> IGameDispatcher {
        let mut game = new_adventurer_lvl10_equipped(stat);
        let STRENGTH: u8 = 0;
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
        game.explore(ADVENTURER_ID, true);

        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == 11, 'adventurer should be lvl 11');

        game
    }

    fn new_adventurer_with_lords(starting_block: u64) -> (IGameDispatcher, IERC20CamelDispatcher) {
        let starting_timestamp = 1;
        let terminal_timestamp = 0;
        let (mut game, lords, _, _) = setup(starting_block, starting_timestamp, terminal_timestamp);
        let starting_weapon = ItemId::Wand;
        let name = 'abcdefghijklmno';

        // start new game
        game.new_game(INTERFACE_ID(), starting_weapon, name, DEFAULT_NO_GOLDEN_TOKEN.into(), false);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let adventurer_meta_data = game.get_adventurer_meta(ADVENTURER_ID);

        // verify starting weapon
        assert(adventurer.weapon.id == starting_weapon, 'wrong starting weapon');
        assert(adventurer_meta_data.name == name, 'wrong player name');
        assert(adventurer.xp == 0, 'should start with 0 xp');
        assert(
            adventurer.beast_health == BeastSettings::STARTER_BEAST_HEALTH,
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
        let mut game = new_adventurer(1000, 1696201757);

        let adventurer_1 = game.get_adventurer(ADVENTURER_ID);
        let adventurer_meta_1 = game.get_adventurer_meta(ADVENTURER_ID);
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
        let mut game = new_adventurer_lvl2(1000, 1696201757);

        // attempt to flee despite not being in a battle
        // this should trigger a panic 'Not in battle' which is
        // annotated in the test
        game.flee(ADVENTURER_ID, false);
    }

    #[test]
    #[available_gas(13000000000)]
    fn test_flee() {
        // start game on level 2
        let mut game = new_adventurer_lvl2(1003, 1696201757);

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
        assert(updated_adventurer.stat_points_available == 1, 'advntr should have 1 stat avl');

        // verify adventurer is unable to explore with stat upgrade available
        // this test is annotated to expect a panic so if it doesn't, this test will fail
        game.explore(ADVENTURER_ID, true);
    }

    #[test]
    #[should_panic(expected: ('Market is closed', 'ENTRYPOINT_FAILED'))]
    #[available_gas(100000000)]
    fn test_buy_items_during_battle() {
        // mint new adventurer (will start in battle with starter beast)
        let mut game = new_adventurer(1000, 1696201757);

        // get valid item from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);
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
        let mut game = new_adventurer_lvl2(1000, 1696201757);

        // get valid item from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);
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
    #[available_gas(62000000)]
    fn test_buy_duplicate_item_equipped() {
        // start new game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2(1000, 1696201757);

        // get items from market
        let market_items = @game.get_items_on_market_by_tier(ADVENTURER_ID, 5);

        // get first item on the market
        let item_id = *market_items.at(0);
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
        let mut game = new_adventurer_lvl2(1000, 1696201757);

        // get items from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);

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
        let mut game = new_adventurer_lvl2(1000, 1696201757);
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
        let mut game = new_adventurer_lvl2(1000, 1696201757);
        let market_items = @game.get_items_on_market(ADVENTURER_ID);
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
        let mut game = new_adventurer_lvl2(1000, 1696201757);

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

        let mut items_to_equip = ArrayTrait::<u8>::new();
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
                assert(adventurer.is_equipped(item_purchase.item_id), 'item not equipped');
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
    #[available_gas(26009820)]
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
    #[available_gas(92000000)]
    fn test_equip() {
        // start game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2(1002, 1696201757);

        // get items from market
        let market_items = @game.get_items_on_market_by_tier(ADVENTURER_ID, 5);

        // get first item on the market
        let item_id = *market_items.at(0);

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
            if (item_slot == Slot::Weapon(()) && purchased_weapon == 0 && item_id != 12) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_weapon = item_id;
            } else if (item_slot == Slot::Chest(()) && purchased_chest == 0) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_chest = item_id;
            } else if (item_slot == Slot::Head(()) && purchased_head == 0) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_head = item_id;
            } else if (item_slot == Slot::Waist(()) && purchased_waist == 0) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_waist = item_id;
            } else if (item_slot == Slot::Foot(()) && purchased_foot == 0) {
                purchased_items.append(item_id);
                shopping_cart.append(ItemPurchase { item_id: item_id, equip: false });
                purchased_foot = item_id;
            } else if (item_slot == Slot::Hand(()) && purchased_hand == 0) {
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
            assert(adventurer.is_equipped(*purchased_items_span.at(i)), 'item should be equipped1');
            i += 1;
        };
    }

    #[test]
    #[available_gas(100000000)]
    fn test_buy_potions() {
        let mut game = new_adventurer_lvl2(1000, 1696201757);

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
                + (POTION_HEALTH_AMOUNT * number_of_potions.into()),
            'potion did not give health'
        );

        // verify potion cost reduced adventurers gold balance
        assert(adventurer.gold < adventurer_gold_pre_potion, 'potion cost is wrong');
    }

    #[test]
    #[should_panic(expected: ('Health already full', 'ENTRYPOINT_FAILED'))]
    #[available_gas(450000000)]
    fn test_buy_potions_exceed_max_health() {
        let mut game = new_adventurer_lvl2(1000, 1696201757);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // get number of potions required to reach full health
        let potions_to_full_health: u8 = (POTION_HEALTH_AMOUNT
            / (AdventurerUtils::get_max_health(adventurer.stats.vitality) - adventurer.health))
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
        let mut game = new_adventurer_lvl2(1000, 1696201757);

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
    #[should_panic(expected: ('Adventurer is not idle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(300000000)]
    fn test_cant_slay_non_idle_adventurer_no_rollover() {
        let STARTING_BLOCK_NUMBER = 513;

        // deploy and start new game
        let mut game = new_adventurer(STARTING_BLOCK_NUMBER, 1696201757);

        // get game entropy
        let game_entropy = game.get_game_entropy();

        // attack starter beast, resulting in adventurer last action block number being 1
        game.attack(ADVENTURER_ID, false);

        // roll forward block chain but not enough to qualify for idle death penalty
        testing::set_block_number(
            STARTING_BLOCK_NUMBER
                + MAINNET_REVEAL_DELAY_BLOCKS.into()
                + game_entropy.get_idle_penalty_blocks()
                - 1
        );

        // try to slay adventurer for being idle
        // this should result in contract throwing a panic 'Adventurer is not idle'
        // because the adventurer is not idle for the full IDLE_DEATH_PENALTY_BLOCKS
        // This test is annotated to expect that panic
        let idle_adventurers = array![ADVENTURER_ID];
        game.slay_idle_adventurers(idle_adventurers);
    }

    #[test]
    #[should_panic(expected: ('Adventurer is not idle', 'ENTRYPOINT_FAILED'))]
    #[available_gas(300000000)]
    fn test_cant_slay_non_idle_adventurer_with_rollover() {
        let STARTING_BLOCK_NUMBER = 510;
        let mut game = new_adventurer(STARTING_BLOCK_NUMBER, 1696201757);

        let game_entropy = game.get_game_entropy();

        // attack beast to set adventurer last action block number
        game.attack(ADVENTURER_ID, false);

        // roll forward block chain but not enough to qualify for idle death penalty
        testing::set_block_number(
            STARTING_BLOCK_NUMBER
                + MAINNET_REVEAL_DELAY_BLOCKS.into()
                + game_entropy.get_idle_penalty_blocks()
                - 1
        );

        // try to slay adventurer for being idle
        // this should result in contract throwing a panic 'Adventurer is not idle'
        // because the adventurer is not idle for the full IDLE_DEATH_PENALTY_BLOCKS
        // This test is annotated to expect that panic
        let idle_adventurers = array![ADVENTURER_ID];
        game.slay_idle_adventurers(idle_adventurers);
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
        let mut game = new_adventurer(STARTING_BLOCK_NUMBER, 1696201757);

        // attack starter beast, resulting in adventurer last action block number being 510
        game.attack(ADVENTURER_ID, false);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let game_entropy = game.get_game_entropy();

        // verify last action block number is correct
        assert(
            adventurer.last_action_block == STARTING_BLOCK_NUMBER.try_into().unwrap(),
            'unexpected last action block'
        );

        // roll forward blockchain to make adventurer idle
        testing::set_block_number(
            STARTING_BLOCK_NUMBER
                + MAINNET_REVEAL_DELAY_BLOCKS.into()
                + game_entropy.get_idle_penalty_blocks()
                + 1
        );

        // get current block number
        let current_block_number = starknet::get_block_info().unbox().block_number;

        // verify current block number % MAX_BLOCK_COUNT is less than adventurers last action block number
        // this is imperative because this test is testing the case where the adventurer last action block number
        // is less than (current_block_number % MAX_BLOCK_COUNT)
        assert(
            (current_block_number % MAX_BLOCK_COUNT) < adventurer.last_action_block.into(),
            'last action !> current block'
        );

        // slay idle adventurer
        let idle_adventurers = array![ADVENTURER_ID];
        game.slay_idle_adventurers(idle_adventurers);

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
        let STARTING_BLOCK_NUMBER = 512;

        // deploy and start new game
        let mut game = new_adventurer(STARTING_BLOCK_NUMBER, 1696201757);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // attack starter beast, resulting in adventurer last action block number being 1
        game.attack(ADVENTURER_ID, false);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let game_entropy = game.get_game_entropy();

        // roll forward blockchain to make adventurer idle
        testing::set_block_number(
            STARTING_BLOCK_NUMBER
                + MAINNET_REVEAL_DELAY_BLOCKS.into()
                + game_entropy.get_idle_penalty_blocks()
                + 1
        );

        // get current block number
        let current_block_number = starknet::get_block_info().unbox().block_number;

        // verify current block number % MAX_BLOCK_COUNT is greater than adventurers last action block number
        // this is imperative because this test is testing the case where the adventurer last action block number
        // is greater than the (current_block_number % MAX_BLOCK_COUNT)
        assert(
            (current_block_number % MAX_BLOCK_COUNT) > adventurer.last_action_block.into(),
            'last action !> current block'
        );

        // call slay idle adventurer
        let idle_adventurers = array![ADVENTURER_ID];
        game.slay_idle_adventurers(idle_adventurers);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // assert adventurer is dead
        assert(adventurer.health == 0, 'adventurer should be dead');
    }

    #[test]
    #[available_gas(142346872)]
    #[should_panic(expected: ('Adventurer is not idle', 'ENTRYPOINT_FAILED'))]
    fn test_slay_idle_adventurer_before_reveal_block() {
        let STARTING_BLOCK_NUMBER = 100;

        // deploy and start new game
        let mut game = new_adventurer(STARTING_BLOCK_NUMBER, 1696201757);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // roll the blockchain back 1 block to simulate mainnet start_game scenario
        // where the adventurers last_action will be set to 11 blocks in the future
        // to account for the commit-and-reveal delay
        testing::set_block_number(STARTING_BLOCK_NUMBER - 1);
        game.slay_idle_adventurers(array![ADVENTURER_ID]);
    }

    #[test]
    #[available_gas(142346872)]
    fn test_multi_slay_adventurers() {
        let STARTING_BLOCK_NUMBER = 512;

        let ADVENTURER2_ID = 2;
        let ADVENTURER3_ID = 3;

        // deploy and start new game
        let mut game = new_adventurer(STARTING_BLOCK_NUMBER, 1696201757);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let adventurer2 = add_adventurer_to_game(ref game, 0);
        let adventurer3 = add_adventurer_to_game(ref game, 0);

        // attack starter beast, resulting in adventurer last action block number being 1
        game.attack(ADVENTURER_ID, false);
        game.attack(ADVENTURER2_ID, false);
        game.attack(ADVENTURER3_ID, false);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let game_entropy = game.get_game_entropy();

        // roll forward blockchain to make adventurer idle
        testing::set_block_number(
            STARTING_BLOCK_NUMBER
                + MAINNET_REVEAL_DELAY_BLOCKS.into()
                + game_entropy.get_idle_penalty_blocks()
                + 1
        );

        // get current block number
        let current_block_number = starknet::get_block_info().unbox().block_number;

        // verify current block number % MAX_BLOCK_COUNT is greater than adventurers last action block number
        // this is imperative because this test is testing the case where the adventurer last action block number
        // is greater than the (current_block_number % MAX_BLOCK_COUNT)
        assert(
            (current_block_number % MAX_BLOCK_COUNT) > adventurer.last_action_block.into(),
            'last action !> current block'
        );

        // call slay idle adventurer
        let idle_adventurers = array![ADVENTURER_ID, ADVENTURER2_ID, ADVENTURER3_ID];
        game.slay_idle_adventurers(idle_adventurers);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let adventurer2 = game.get_adventurer(ADVENTURER2_ID);
        let adventurer3 = game.get_adventurer(ADVENTURER3_ID);

        // assert adventurer is dead
        assert(adventurer.health == 0, 'adventurer should be dead');
        assert(adventurer2.health == 0, 'adventurer2 should be dead');
        assert(adventurer3.health == 0, 'adventurer3 should be dead');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_get_game_entropy() {
        let mut game = new_adventurer(1000, 1696201757);
        let game_entropy = game.get_game_entropy();
        assert(game_entropy.last_updated_block == 0x3e8, 'wrong entropy last update block');
        assert(game_entropy.last_updated_time == 0x6519fc1d, 'wrong entropy last update time');
        assert(game_entropy.next_update_block == 0x3ee, 'wrong entropy next update block');
    }

    #[test]
    #[available_gas(100000000)]
    fn test_get_potion_price() {
        let mut game = new_adventurer(1000, 1696201757);
        let potion_price = game.get_potion_price(ADVENTURER_ID);
        let adventurer_level = game.get_adventurer(ADVENTURER_ID).get_level();
        assert(potion_price == POTION_PRICE * adventurer_level.into(), 'wrong lvl1 potion price');

        let mut game = new_adventurer_lvl2(1000, 1696201757);
        let potion_price = game.get_potion_price(ADVENTURER_ID);
        let adventurer_level = game.get_adventurer(ADVENTURER_ID).get_level();
        assert(potion_price == POTION_PRICE * adventurer_level.into(), 'wrong lvl2 potion price');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_get_attacking_beast() {
        let mut game = new_adventurer(1000, 1696201757);
        let beast = game.get_attacking_beast(ADVENTURER_ID);
        // our adventurer starts with a wand so the starter beast should be a troll
        assert(beast.id == BeastId::Troll, 'starter beast should be troll');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_get_health() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.health == game.get_health(ADVENTURER_ID), 'wrong adventurer health');
    }

    #[test]
    #[available_gas(90000000)]
    fn test_get_xp() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.xp == game.get_xp(ADVENTURER_ID), 'wrong adventurer xp');
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_level() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.get_level() == game.get_level(ADVENTURER_ID), 'wrong adventurer level');
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_gold() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(adventurer.gold == game.get_gold(ADVENTURER_ID), 'wrong gold bal');
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_beast_health() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.beast_health == game.get_beast_health(ADVENTURER_ID), 'wrong beast health'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_stat_upgrades_available() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.stat_points_available == game.get_stat_upgrades_available(ADVENTURER_ID),
            'wrong stat points avail'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_last_action_block() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.last_action_block == game.get_last_action_block(ADVENTURER_ID),
            'wrong last action'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_weapon_greatness() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.weapon.get_greatness() == game.get_weapon_greatness(ADVENTURER_ID),
            'wrong weapon greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_chest_greatness() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.chest.get_greatness() == game.get_chest_greatness(ADVENTURER_ID),
            'wrong chest greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_head_greatness() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.head.get_greatness() == game.get_head_greatness(ADVENTURER_ID),
            'wrong head greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_waist_greatness() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.waist.get_greatness() == game.get_waist_greatness(ADVENTURER_ID),
            'wrong waist greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_foot_greatness() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.foot.get_greatness() == game.get_foot_greatness(ADVENTURER_ID),
            'wrong foot greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_hand_greatness() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.hand.get_greatness() == game.get_hand_greatness(ADVENTURER_ID),
            'wrong hand greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_necklace_greatness() {
        let mut game = new_adventurer(1000, 1696201757);
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        assert(
            adventurer.neck.get_greatness() == game.get_necklace_greatness(ADVENTURER_ID),
            'wrong neck greatness'
        );
    }
    #[test]
    #[available_gas(20000000)]
    fn test_get_ring_greatness() {
        let mut game = new_adventurer(1000, 1696201757);
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
    //     let mut game = new_adventurer_lvl2(1000,1696201757);

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
    #[available_gas(83000000)]
    fn test_drop_item() {
        // start new game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2(1000, 1696201757);

        // get items from market
        let market_items = @game.get_items_on_market(ADVENTURER_ID);

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
        assert(adventurer.weapon.id != 0, 'adventurer should have weapon');
        // assert bag has the purchased item
        let (contains, _) = bag.contains(purchased_item_id);
        assert(contains, 'item should be in bag');

        // create drop list consisting of adventurers equipped weapon and purchased item that is in bag
        let mut drop_list = ArrayTrait::<u8>::new();
        drop_list.append(adventurer.weapon.id);
        drop_list.append(purchased_item_id);

        // call contract drop
        game.drop(ADVENTURER_ID, drop_list);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        // get bag state
        let bag = game.get_bag(ADVENTURER_ID);

        // assert adventurer has no weapon equipped
        assert(adventurer.weapon.id == 0, 'weapon id should be 0');
        assert(adventurer.weapon.xp == 0, 'weapon should have no xp');

        // assert bag does not have the purchased item
        let (contains, _) = bag.contains(purchased_item_id);
        assert(!contains, 'item should not be in bag');
    }

    #[test]
    #[should_panic(expected: ('Item not owned by adventurer', 'ENTRYPOINT_FAILED'))]
    #[available_gas(90000000)]
    fn test_drop_item_without_ownership() {
        // start new game on level 2 so we have access to the market
        let mut game = new_adventurer_lvl2(1000, 1696201757);

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
        let mut game = new_adventurer_lvl2(1000, 1696201757);
        let CHARISMA_STAT = 5;

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
        assert(adventurer.stat_points_available == 0, 'should have used stat point');
    }

    #[test]
    #[should_panic(expected: ('insufficient stat upgrades', 'ENTRYPOINT_FAILED'))]
    #[available_gas(70000000)]
    fn test_upgrade_stats_not_enough_points() {
        // deploy and start new game
        let mut game = new_adventurer_lvl2(1000, 1696201757);

        // get adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let original_charisma = adventurer.stats.charisma;

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
        let mut game = new_adventurer_lvl2(1006, 1696201757);

        // get original adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);
        let game_entropy = game.get_game_entropy();
        let original_charisma = adventurer.stats.charisma;
        let original_health = adventurer.health;

        // potion purchases
        let potions = 1;

        // item purchases
        let chests_armor_on_market = @game.get_items_on_market_by_slot(ADVENTURER_ID, 2);
        let mut chests_armor_id = 0;
        let head_armor_on_market = @game.get_items_on_market_by_slot(ADVENTURER_ID, 3);
        let mut head_armor_id = 0;
        let waist_armor_on_market = @game.get_items_on_market_by_slot(ADVENTURER_ID, 4);
        let mut waist_armor_id = 0;
        let mut items_to_purchase = ArrayTrait::<ItemPurchase>::new();

        if chests_armor_on_market.len() > 0 {
            chests_armor_id = *chests_armor_on_market.at(0);
            items_to_purchase.append(ItemPurchase { item_id: chests_armor_id, equip: true });
        }
        if head_armor_on_market.len() > 0 {
            head_armor_id = *head_armor_on_market.at(0);
            items_to_purchase.append(ItemPurchase { item_id: head_armor_id, equip: false });
        }

        if waist_armor_on_market.len() > 0 {
            waist_armor_id = *waist_armor_on_market.at(0);
            items_to_purchase.append(ItemPurchase { item_id: waist_armor_id, equip: false });
        }

        // stat upgrades
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };

        // call upgrade
        game.upgrade(ADVENTURER_ID, potions, stat_upgrades, items_to_purchase);

        // get updated adventurer state
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // assert health was increased by one potion
        assert(adventurer.health == original_health + POTION_HEALTH_AMOUNT, 'health not increased');
        // assert charisma was increased
        assert(adventurer.stats.charisma == original_charisma + 1, 'charisma not increased');
        // assert stat point was used
        assert(adventurer.stat_points_available == 0, 'should have used stat point');
        // assert adventurer has the purchased items
        if chests_armor_id > 0 {
            assert(adventurer.is_equipped(chests_armor_id), 'chest should be equipped');
        }
        if head_armor_id > 0 {
            assert(!adventurer.is_equipped(head_armor_id), 'head should not be equipped');
        }
        if waist_armor_id > 0 {
            assert(!adventurer.is_equipped(waist_armor_id), 'waist should not be equipped');
        }
    }

    #[test]
    #[available_gas(570778841)]
    #[should_panic(expected: ('rate limit exceeded', 'ENTRYPOINT_FAILED'))]
    fn test_exceed_rate_limit() {
        let starting_block = 388630;
        let starting_time = 1699532315;
        let mut game = new_adventurer_lvl2(starting_block, starting_time);

        testing::set_block_number(starting_block + 1);
        testing::set_block_timestamp(starting_time + 15);
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };

        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());
        testing::set_block_number(starting_block + 2);
        testing::set_block_timestamp(starting_time + 30);
        game.explore(ADVENTURER_ID, false);
        testing::set_block_number(starting_block + 3);
        testing::set_block_timestamp(starting_time + 45);
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());
        game.explore(ADVENTURER_ID, false);
        testing::set_block_number(starting_block + 4);
        testing::set_block_timestamp(starting_time + 60);
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());
        testing::set_block_number(starting_block + 5);
        testing::set_block_timestamp(starting_time + 75);
        game.explore(ADVENTURER_ID, false);
        testing::set_block_number(starting_block + 6);
        testing::set_block_timestamp(starting_time + 90);
        game.explore(ADVENTURER_ID, false);
        testing::set_block_number(starting_block + 7);
        testing::set_block_timestamp(starting_time + 105);
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());
        testing::set_block_number(starting_block + 8);
        testing::set_block_timestamp(starting_time + 120);
        game.explore(ADVENTURER_ID, false);
        testing::set_block_number(starting_block + 9);
        testing::set_block_timestamp(starting_time + 135);
        game.explore(ADVENTURER_ID, false);
        testing::set_block_number(starting_block + 10);
        testing::set_block_timestamp(starting_time + 150);
        game.explore(ADVENTURER_ID, false);
        testing::set_block_number(starting_block + 11);
        testing::set_block_timestamp(starting_time + 165);
        game.explore(ADVENTURER_ID, false);
        testing::set_block_number(starting_block + 12);
        testing::set_block_timestamp(starting_time + 180);

        // with 15s block intervals, the rate limit will be 2 actions per block
        // try to do three actions in a single block and verify contract panics
        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart.clone());
        game.explore(ADVENTURER_ID, false);
        game.attack(ADVENTURER_ID, false);
    }

    #[test]
    #[available_gas(944417814)]
    fn test_exceed_rate_limit_block_rotation() {
        let starting_block = 1003;
        let mut game = new_adventurer_lvl2(starting_block, 1696201757);
        let shopping_cart = ArrayTrait::<ItemPurchase>::new();
        let stat_upgrades = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 1, luck: 0
        };

        game.upgrade(ADVENTURER_ID, 0, stat_upgrades, shopping_cart);
        game.explore(ADVENTURER_ID, false);
        game.explore(ADVENTURER_ID, false);

        // advancing block resets players action per block
        starknet::testing::set_block_number(starting_block + 1);

        // player can continue playing
        game.attack(ADVENTURER_ID, false);
        game.attack(ADVENTURER_ID, false);
        game.attack(ADVENTURER_ID, false);
        game.attack(ADVENTURER_ID, false);
    }

    fn _calculate_payout(bp: u256, price: u128) -> u256 {
        (bp * price.into()) / 1000
    }

    #[test]
    #[available_gas(90000000)]
    fn test_bp_distribution() {
        let (mut game, lords) = new_adventurer_with_lords(1000);
        let adventurer = game.get_adventurer(ADVENTURER_ID);

        // stage 0
        assert(lords.balanceOf(DAO()) == COST_TO_PLAY.into(), 'wrong stage 1 balance');

        // stage 1
        testing::set_block_number(1001 + BLOCKS_IN_A_WEEK * 2);

        // spawn new

        // DAO doesn't get anything more until stage 2
        assert(lords.balanceOf(DAO()) == COST_TO_PLAY.into(), 'wrong stage 1 balance');

        let mut rewards = Rewards {
            DAO: _calculate_payout(REWARD_DISTRIBUTIONS_PHASE1_BP::DAO, COST_TO_PLAY),
            INTERFACE: _calculate_payout(REWARD_DISTRIBUTIONS_PHASE1_BP::INTERFACE, COST_TO_PLAY),
            FIRST_PLACE: _calculate_payout(
                REWARD_DISTRIBUTIONS_PHASE1_BP::FIRST_PLACE, COST_TO_PLAY
            ),
            SECOND_PLACE: _calculate_payout(
                REWARD_DISTRIBUTIONS_PHASE1_BP::SECOND_PLACE, COST_TO_PLAY
            ),
            THIRD_PLACE: _calculate_payout(
                REWARD_DISTRIBUTIONS_PHASE1_BP::THIRD_PLACE, COST_TO_PLAY
            )
        };
    // week.FIRST_PLACE.print();

    // assert(lords.balanceOf(DAO()) == COST_TO_PLAY, 'wrong DAO payout');
    // assert(week.INTERFACE == 0, 'no payout in stage 1');
    // assert(week.FIRST_PLACE == _calculate_payout(
    //         REWARD_DISTRIBUTIONS_PHASE1_BP::FIRST_PLACE, cost_to_play
    //     ), 'wrong FIRST_PLACE payout 1');
    // assert(week.SECOND_PLACE == 0x6f05b59d3b200000, 'wrong SECOND_PLACE payout 1');
    // assert(week.THIRD_PLACE == 0x6f05b59d3b20000, 'wrong THIRD_PLACE payout 1');

    // (COST_TO_PLAY * 11 / 10).print();
    // (COST_TO_PLAY * 9 / 10).print();
    }

    #[test]
    #[available_gas(90000000)]
    #[should_panic(expected: ('price change already initiated', 'ENTRYPOINT_FAILED'))]
    fn test_initiate_price_change_too_fast() {
        let (mut game, lords, _, _) = setup(1000, 1, 0);
        game.initiate_price_change();
        game.initiate_price_change();
    }

    #[test]
    #[available_gas(9000000000)]
    fn test_update_cost_to_play() {
        let (mut game, lords, _, _) = setup(1000, 1, 0);
        let original_cost_to_play = game.get_cost_to_play();

        // create 10 games during opening week
        let mut i = 0;
        loop {
            if i == 10 {
                break ();
            }
            game
                .new_game(
                    INTERFACE_ID(), ItemId::Wand, 'phase1', DEFAULT_NO_GOLDEN_TOKEN.into(), false
                );
            i += 1;
        };
        testing::set_block_timestamp(starknet::get_block_timestamp() + (DAY * 7));

        // then a price change is initiated
        game.initiate_price_change();

        // during price change snapshot, 10 games played (same as opening week)
        let mut i = 0;
        loop {
            if i == 10 {
                break ();
            }
            game
                .new_game(
                    INTERFACE_ID(), ItemId::Wand, 'phase1', DEFAULT_NO_GOLDEN_TOKEN.into(), false
                );
            i += 1;
        };
        testing::set_block_timestamp(starknet::get_block_timestamp() + (DAY * 7));

        // update cost to play is called
        game.update_cost_to_play();

        // since games 10 games were played first week and 10 games were played second week during snapshot, no price change is warranted
        assert(game.get_cost_to_play() == original_cost_to_play, 'game cost should be same');

        // someone initiates a new price change
        game.initiate_price_change();

        // during price change snapshot, 20 games played
        let mut i = 0;
        loop {
            if i == 20 {
                break ();
            }
            game
                .new_game(
                    INTERFACE_ID(), ItemId::Wand, 'phase1', DEFAULT_NO_GOLDEN_TOKEN.into(), false
                );
            i += 1;
        };

        // roll blockchain forward a week
        testing::set_block_timestamp(starknet::get_block_timestamp() + (DAY * 7));

        // call update cost to play
        game.update_cost_to_play();

        // verify cost to play game has been increased
        assert(game.get_cost_to_play() > original_cost_to_play, 'game cost should be higher');

        // record previous cost to play
        let previous_cost_to_play = game.get_cost_to_play();

        // initiate another price change
        game.initiate_price_change();

        // this time only 10 games are played during a two week snapshot
        // roll blockchain forward three weeks without adding any new games
        let mut i = 0;
        loop {
            if i == 10 {
                break ();
            }
            game
                .new_game(
                    INTERFACE_ID(), ItemId::Wand, 'phase1', DEFAULT_NO_GOLDEN_TOKEN.into(), false
                );
            i += 1;
        };
        testing::set_block_timestamp(starknet::get_block_timestamp() + (DAY * 14));
        game.update_cost_to_play();

        // since average number of games played during snapshot is considerably less than average
        // price of game should have been reduced
        assert(game.get_cost_to_play() < previous_cost_to_play, 'game cost should be lower');
    }

    #[test]
    #[available_gas(9000000000)]
    #[should_panic(expected: ('terminal time reached', 'ENTRYPOINT_FAILED'))]
    fn test_terminal_timestamp_reached() {
        let starting_block = 1;
        let starting_timestamp = 1;
        let terminal_timestamp = 100;
        let (mut game, lords, _, _) = setup(starting_block, starting_timestamp, terminal_timestamp);

        // add a player to the game
        add_adventurer_to_game(ref game, 0);
        // advance blockchain timestamp beyond terminal timestamp
        starknet::testing::set_block_timestamp(terminal_timestamp + 1);

        // try to start a new game
        // should panic with 'terminal time reached'
        // which test is annotated to expect
        add_adventurer_to_game(ref game, 0);
    }

    #[test]
    #[available_gas(9000000000)]
    fn test_terminal_timestamp_not_set() {
        let starting_block = 1;
        let starting_timestamp = 1;
        let terminal_timestamp = 0;
        let (mut game, lords, _, _) = setup(starting_block, starting_timestamp, terminal_timestamp);

        // add a player to the game
        add_adventurer_to_game(ref game, 0);

        // advance blockchain timestamp to max u64
        let max_u64_timestamp = 18446744073709551615;
        starknet::testing::set_block_timestamp(max_u64_timestamp);

        // verify we can still start a new game
        add_adventurer_to_game(ref game, 0);
    }

    #[test]
    #[available_gas(9000000000)]
    fn test_golden_token_new_game() {
        let starting_block = 364063;
        let starting_timestamp = 1698678554;
        let terminal_timestamp = 0;
        let (mut game, lords, golden_token, arcade_account_address) = setup(
            starting_block, starting_timestamp, terminal_timestamp
        );
        add_adventurer_to_game(ref game, 1);
        testing::set_block_timestamp(starting_timestamp + DAY);
        add_adventurer_to_game(ref game, 1);
    }

    #[test]
    #[available_gas(9000000000)]
    fn test_golden_token_can_play() {
        let golden_token_id = 1;
        let starting_block = 364063;
        let starting_timestamp = 1698678554;
        let terminal_timestamp = 0;
        let (mut game, lords, golden_token, arcade_account_address) = setup(
            starting_block, starting_timestamp, terminal_timestamp
        );
        assert(game.can_play(1), 'should be able to play');
        add_adventurer_to_game(ref game, golden_token_id);
        assert(!game.can_play(1), 'should not be able to play');
        testing::set_block_timestamp(starting_timestamp + DAY);
        assert(game.can_play(1), 'should be able to play again');
    }

    #[test]
    #[available_gas(9000000000)]
    #[should_panic(
        expected: ('ERC721: invalid token ID', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED')
    )]
    fn test_golden_token_unminted_token() {
        let golden_token_id = 500;
        let starting_block = 364063;
        let starting_timestamp = 1698678554;
        let terminal_timestamp = 0;
        let (mut game, lords, golden_token, arcade_account_address) = setup(
            starting_block, starting_timestamp, terminal_timestamp
        );
        add_adventurer_to_game(ref game, golden_token_id);
    }

    #[test]
    #[available_gas(9000000000)]
    #[should_panic(expected: ('Token already used today', 'ENTRYPOINT_FAILED'))]
    fn test_golden_token_double_play() {
        let golden_token_id = 1;
        let starting_block = 364063;
        let starting_timestamp = 1698678554;
        let terminal_timestamp = 0;
        let (mut game, lords, golden_token, arcade_account_address) = setup(
            starting_block, starting_timestamp, terminal_timestamp
        );
        add_adventurer_to_game(ref game, golden_token_id);

        // roll blockchain forward 1 second less than a day
        testing::set_block_timestamp(starting_timestamp + (DAY - 1));

        // try to play again with golden token which should cause panic
        add_adventurer_to_game(ref game, golden_token_id);
    }

    #[test]
    #[available_gas(60000000)]
    fn test_is_idle_view_function() {
        let STARTING_BLOCK_NUMBER = 510;
        let mut game = new_adventurer(STARTING_BLOCK_NUMBER, 1696201757);
        game.attack(ADVENTURER_ID, false);

        // verify adventurer is not idle
        let (is_idle, _) = game.is_idle(ADVENTURER_ID);
        assert(!is_idle, 'should not be idle');

        // roll forward blockchain to make adventurer idle
        let game_entropy = game.get_game_entropy();
        testing::set_block_number(
            STARTING_BLOCK_NUMBER
                + MAINNET_REVEAL_DELAY_BLOCKS.into()
                + game_entropy.get_idle_penalty_blocks()
                + 1
        );

        // verify adventurer is now idle
        let (is_idle, _) = game.is_idle(ADVENTURER_ID);
        assert(is_idle, 'should be idle');
    }
}
