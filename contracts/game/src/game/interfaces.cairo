use starknet::ContractAddress;
use survivor::{
    bag::Bag, adventurer::{Adventurer, Stats}, adventurer_meta::AdventurerMetadata,
    item_meta::ItemSpecials
};
use lootitems::loot::{Loot};
use market::market::LootWithPrice;
use beasts::beast::Beast;

#[starknet::interface]
trait IGame<TContractState> {
    // actions ---------------------------------------------------
    fn start(ref self: TContractState, interface_id: ContractAddress, starting_weapon: u8, adventurer_meta: AdventurerMetadata);
    fn explore(ref self: TContractState, adventurer_id: u256);
    fn attack(ref self: TContractState, adventurer_id: u256);
    fn flee(ref self: TContractState, adventurer_id: u256);
    fn equip(ref self: TContractState, adventurer_id: u256, item_id: u8);
    fn buy_item(ref self: TContractState, adventurer_id: u256, item_id: u8, equip: bool);
    fn buy_potion(ref self: TContractState, adventurer_id: u256);
    fn upgrade_stat(ref self: TContractState, adventurer_id: u256, stat: u8);
    fn slay_idle_adventurer(ref self: TContractState, adventurer_id: u256);

    // view ------------------------------------------------------
    fn get_adventurer(self: @TContractState, adventurer_id: u256) -> Adventurer;
    fn get_adventurer_meta(self: @TContractState, adventurer_id: u256) -> AdventurerMetadata;
    fn get_bag(self: @TContractState, adventurer_id: u256) -> Bag;
    fn get_items_on_market(self: @TContractState, adventurer_id: u256) -> Array<LootWithPrice>;
    fn get_potion_price(self: @TContractState, adventurer_id: u256) -> u16;
    fn get_attacking_beast(self: @TContractState, adventurer_id: u256) -> Beast;

    // adventurer details
    fn get_health(self: @TContractState, adventurer_id: u256) -> u16;
    fn get_xp(self: @TContractState, adventurer_id: u256) -> u16;
    fn get_level(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_gold(self: @TContractState, adventurer_id: u256) -> u16;
    fn get_beast_health(self: @TContractState, adventurer_id: u256) -> u16;
    fn get_stat_points_available(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_last_action(self: @TContractState, adventurer_id: u256) -> u16;

    // item stats
    fn get_weapon_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_chest_armor_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_head_armor_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_waist_armor_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_foot_armor_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_hand_armor_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_necklace_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_ring_greatness(self: @TContractState, adventurer_id: u256) -> u8;

    // item details
    fn get_equipped_weapon_names(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_equipped_chest_names(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_equipped_head_names(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_equipped_waist_names(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_equipped_foot_names(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_equipped_hand_names(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_equipped_necklace_names(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_equipped_ring_names(self: @TContractState, adventurer_id: u256) -> ItemSpecials;

    // adventurer stats
    fn get_base_stats(self: @TContractState, adventurer_id: u256) -> Stats;
    fn get_boosted_stats(self: @TContractState, adventurer_id: u256) -> Stats;
    fn get_base_strength(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_boosted_strength(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_base_dexterity(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_boosted_dexterity(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_base_vitality(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_boosted_vitality(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_base_intelligence(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_boosted_intelligence(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_base_wisdom(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_boosted_wisdom(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_base_charisma(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_boosted_charisma(self: @TContractState, adventurer_id: u256) -> u8;

    // beast details
    fn get_beast_type(self: @TContractState, beast_id: u8) -> u8;
    fn get_beast_tier(self: @TContractState, beast_id: u8) -> u8;

    // contract details
    fn get_dao_address(self: @TContractState) -> ContractAddress;
    fn get_lords_address(self: @TContractState) -> ContractAddress;
    fn get_entropy(self: @TContractState) -> u64;

    // setters ---------------------------------------------------
    fn set_entropy(ref self: TContractState);

    // checks ----------------------------------------------------
    fn owner_of(self: @TContractState, adventurer_id: u256) -> ContractAddress;
}


#[starknet::interface]
trait IERC20<TContractState>  {
    fn transferFrom(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn burn_away(ref self: TContractState, to: ContractAddress, amount: u256);
}