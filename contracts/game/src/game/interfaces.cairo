use starknet::ContractAddress;

use beasts::beast::Beast;
use market::market::{ItemPurchase};
use adventurer::{
    bag::Bag, adventurer::{Adventurer, Stats}, adventurer_meta::AdventurerMetadata,
    leaderboard::Leaderboard, item::{Item}
};

#[starknet::interface]
trait IGame<TContractState> {
    // ------ Game Actions ------
    fn new_game(
        ref self: TContractState,
        client_reward_address: ContractAddress,
        weapon: u8,
        name: felt252,
        golden_token_id: u256,
        delay_reveal: bool,
        custom_renderer: ContractAddress
    ) -> felt252;
    fn explore(ref self: TContractState, adventurer_id: felt252, till_beast: bool);
    fn attack(ref self: TContractState, adventurer_id: felt252, to_the_death: bool);
    fn flee(ref self: TContractState, adventurer_id: felt252, to_the_death: bool);
    fn equip(ref self: TContractState, adventurer_id: felt252, items: Array<u8>);
    fn drop(ref self: TContractState, adventurer_id: felt252, items: Array<u8>);
    fn upgrade(
        ref self: TContractState,
        adventurer_id: felt252,
        potions: u8,
        stat_upgrades: Stats,
        items: Array<ItemPurchase>,
    );
    fn receive_random_words(
        ref self: TContractState,
        requestor_address: ContractAddress,
        request_id: u64,
        random_words: Span<felt252>,
        calldata: Array<felt252>
    );
    fn update_cost_to_play(ref self: TContractState) -> u128;
    fn set_custom_renderer(
        ref self: TContractState, adventurer_id: felt252, render_contract: ContractAddress
    );
    fn increase_vrf_allowance(ref self: TContractState, adventurer_id: felt252, amount: u128);
    fn update_adventurer_name(ref self: TContractState, adventurer_id: felt252, name: felt252);
    fn set_adventurer_obituary(
        ref self: TContractState, adventurer_id: felt252, obituary: ByteArray
    );
    fn slay_expired_adventurers(ref self: TContractState, adventurer_ids: Array<felt252>);

    // ------ View Functions ------

    // adventurer details
    fn get_adventurer(self: @TContractState, adventurer_id: felt252) -> Adventurer;
    fn get_adventurer_name(self: @TContractState, adventurer_id: felt252) -> felt252;
    fn get_adventurer_obituary(self: @TContractState, adventurer_id: felt252) -> ByteArray;
    fn get_adventurer_entropy(self: @TContractState, adventurer_id: felt252) -> felt252;
    fn get_adventurer_no_boosts(self: @TContractState, adventurer_id: felt252) -> Adventurer;
    fn get_adventurer_meta(self: @TContractState, adventurer_id: felt252) -> AdventurerMetadata;
    fn get_health(self: @TContractState, adventurer_id: felt252) -> u16;
    fn get_xp(self: @TContractState, adventurer_id: felt252) -> u16;
    fn get_level(self: @TContractState, adventurer_id: felt252) -> u8;
    fn get_gold(self: @TContractState, adventurer_id: felt252) -> u16;
    fn get_stat_upgrades_available(self: @TContractState, adventurer_id: felt252) -> u8;

    // fn get_starting_stats(self: @TContractState, adventurer_id: felt252) -> Stats;
    // fn equipment_specials_unlocked(self: @TContractState, adventurer_id: felt252) -> bool;
    fn get_item_specials_seed(self: @TContractState, adventurer_id: felt252) -> felt252;
    // fn equipment_stat_boosts(self: @TContractState, adventurer_id: felt252) -> Stats;

    // // item details
    fn get_equipped_items(self: @TContractState, adventurer_id: felt252) -> Array<Item>;

    // item stats
    fn get_weapon_greatness(self: @TContractState, adventurer_id: felt252) -> u8;
    fn get_chest_greatness(self: @TContractState, adventurer_id: felt252) -> u8;
    fn get_head_greatness(self: @TContractState, adventurer_id: felt252) -> u8;
    fn get_waist_greatness(self: @TContractState, adventurer_id: felt252) -> u8;
    fn get_foot_greatness(self: @TContractState, adventurer_id: felt252) -> u8;
    fn get_hand_greatness(self: @TContractState, adventurer_id: felt252) -> u8;
    fn get_necklace_greatness(self: @TContractState, adventurer_id: felt252) -> u8;
    fn get_ring_greatness(self: @TContractState, adventurer_id: felt252) -> u8;

    // bag and specials
    fn get_bag(self: @TContractState, adventurer_id: felt252) -> Bag;

    // // market details
    fn get_market(self: @TContractState, adventurer_id: felt252) -> Array<u8>;
    fn get_potion_price(self: @TContractState, adventurer_id: felt252) -> u16;
    fn get_item_price(self: @TContractState, adventurer_id: felt252, item_id: u8) -> u16;

    // beast details
    fn get_attacking_beast(self: @TContractState, adventurer_id: felt252) -> Beast;
    fn get_beast_health(self: @TContractState, adventurer_id: felt252) -> u16;
    // fn get_beast_type(self: @TContractState, beast_id: u8) -> u8;
    // fn get_beast_tier(self: @TContractState, beast_id: u8) -> u8;

    // game settings
    // fn starting_gold(self: @TContractState) -> u16;
    // fn starting_health(self: @TContractState) -> u16;
    // fn base_potion_price(self: @TContractState) -> u16;
    // fn potion_health_amount(self: @TContractState) -> u16;
    // fn minimum_potion_price(self: @TContractState) -> u16;
    // fn charisma_potion_discount(self: @TContractState) -> u16;
    // fn items_per_stat_upgrade(self: @TContractState) -> u8;
    // fn item_tier_price_multiplier(self: @TContractState) -> u16;
    // fn charisma_item_discount(self: @TContractState) -> u16;
    // fn minimum_item_price(self: @TContractState) -> u16;
    // fn minimum_damage_to_beasts(self: @TContractState) -> u8;
    // fn minimum_damage_from_beasts(self: @TContractState) -> u8;
    // fn minimum_damage_from_obstacles(self: @TContractState) -> u8;
    fn obstacle_critical_hit_chance(self: @TContractState, adventurer_id: felt252) -> u8;
    fn beast_critical_hit_chance(
        self: @TContractState, adventurer_id: felt252, is_ambush: bool
    ) -> u8;
    // fn stat_upgrades_per_level(self: @TContractState) -> u8;
    // fn beast_special_name_unlock_level(self: @TContractState) -> u16;
    // fn item_xp_multiplier_beasts(self: @TContractState) -> u16;
    // fn item_xp_multiplier_obstacles(self: @TContractState) -> u16;
    // fn strength_bonus_damage(self: @TContractState) -> u8;

    // contract details
    // fn owner_of(self: @TContractState, adventurer_id: felt252) -> ContractAddress;
    fn get_game_count(self: @TContractState) -> felt252;
    fn get_dao_address(self: @TContractState) -> ContractAddress;
    fn get_pg_address(self: @TContractState) -> ContractAddress;
    fn get_lords_address(self: @TContractState) -> ContractAddress;
    fn get_leaderboard(self: @TContractState) -> Leaderboard;
    fn get_cost_to_play(self: @TContractState) -> u128;
    fn can_play(self: @TContractState, golden_token_id: u256) -> bool;
    fn get_randomness_address(self: @TContractState) -> ContractAddress;
    fn uses_custom_renderer(self: @TContractState, adventurer_id: felt252) -> bool;
    fn get_custom_renderer(self: @TContractState, adventurer_id: felt252) -> ContractAddress;
    fn get_player_vrf_allowance(self: @TContractState, adventurer_id: felt252) -> u128;
}

#[starknet::interface]
trait IERC721Metadata<TState> {
    fn name(self: @TState) -> ByteArray;
    fn symbol(self: @TState) -> ByteArray;
    fn token_uri(self: @TState, adventurer_id: u256) -> ByteArray;
}

#[starknet::interface]
trait IERC721MetadataCamelOnly<TState> {
    fn tokenURI(self: @TState, adventurerId: felt252) -> ByteArray;
}


#[starknet::interface]
trait ILeetLoot<T> {
    fn mint(
        ref self: T, to: ContractAddress, beast: u8, prefix: u8, suffix: u8, level: u16, health: u16
    );
    fn isMinted(self: @T, beast: u8, prefix: u8, suffix: u8) -> bool;
    fn getMinter(self: @T) -> ContractAddress;
}
