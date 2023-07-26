use starknet::ContractAddress;
use survivor::{
    bag::Bag, adventurer::{Adventurer, Stats}, adventurer_meta::AdventurerMetadata,
    item_meta::{ItemSpecials, ItemSpecialsStorage}
};
use lootitems::loot::{Loot};
use market::market::{LootWithPrice, ItemPurchase};
use beasts::beast::Beast;

#[starknet::interface]
trait IGame<TContractState> {
    // actions ---------------------------------------------------
    fn start(
        ref self: TContractState,
        interface_id: ContractAddress,
        starting_weapon: u8,
        adventurer_meta: AdventurerMetadata
    );
    fn explore(ref self: TContractState, adventurer_id: u256);
    fn attack(ref self: TContractState, adventurer_id: u256);
    fn flee(ref self: TContractState, adventurer_id: u256);
    fn equip(ref self: TContractState, adventurer_id: u256, items: Span<u8>);
    fn drop(ref self: TContractState, adventurer_id: u256, items: Span<u8>);
    fn buy_items(ref self: TContractState, adventurer_id: u256, items: Span<ItemPurchase>);
    fn buy_item(ref self: TContractState, adventurer_id: u256, item_id: u8, equip: bool);
    fn buy_potion(ref self: TContractState, adventurer_id: u256);
    fn buy_potions(ref self: TContractState, adventurer_id: u256, amount: u8);
    fn upgrade_stat(ref self: TContractState, adventurer_id: u256, stat: u8, amount: u8);
    fn upgrade_stats(ref self: TContractState, adventurer_id: u256, stats: Span<u8>);
    fn slay_idle_adventurer(ref self: TContractState, adventurer_id: u256);

    // --------- view functions ---------

    // adventurer details
    fn get_adventurer(self: @TContractState, adventurer_id: u256) -> Adventurer;
    fn get_adventurer_no_boosts(self: @TContractState, adventurer_id: u256) -> Adventurer;
    fn get_adventurer_meta(self: @TContractState, adventurer_id: u256) -> AdventurerMetadata;
    fn get_health(self: @TContractState, adventurer_id: u256) -> u16;
    fn get_xp(self: @TContractState, adventurer_id: u256) -> u16;
    fn get_level(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_gold(self: @TContractState, adventurer_id: u256) -> u16;
    fn get_stat_upgrades_available(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_last_action(self: @TContractState, adventurer_id: u256) -> u16;

    // adventurer stats (includes boost)
    fn get_stats(self: @TContractState, adventurer_id: u256) -> Stats;
    fn get_strength(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_dexterity(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_vitality(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_intelligence(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_wisdom(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_charisma(self: @TContractState, adventurer_id: u256) -> u8;

    // item stats
    // TODO: get_equipped_items(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_weapon_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_chest_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_head_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_waist_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_foot_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_hand_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_necklace_greatness(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_ring_greatness(self: @TContractState, adventurer_id: u256) -> u8;

    // bag and specials
    fn get_bag(self: @TContractState, adventurer_id: u256) -> Bag;
    fn get_special_storage(
        self: @TContractState, adventurer_id: u256, storage_index: u256
    ) -> ItemSpecialsStorage;

    // item details
    fn get_weapon_specials(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_chest_specials(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_head_specials(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_waist_specials(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_foot_specials(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_hand_specials(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_necklace_specials(self: @TContractState, adventurer_id: u256) -> ItemSpecials;
    fn get_ring_specials(self: @TContractState, adventurer_id: u256) -> ItemSpecials;

    // market details
    fn get_items_on_market(self: @TContractState, adventurer_id: u256) -> Array<LootWithPrice>;
    fn get_weapons_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_chest_armor_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_head_armor_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_waist_armor_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_foot_armor_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_hand_armor_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_necklaces_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_rings_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_t1_items_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_t2_items_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_t3_items_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_t4_items_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_t5_items_on_market(self: @TContractState, adventurer_id: u256) -> Array<u8>;
    fn get_potion_price(self: @TContractState, adventurer_id: u256) -> u16;
    fn get_attacking_beast(self: @TContractState, adventurer_id: u256) -> Beast;

    // adventurer stats (no boosts)
    fn get_base_stats(self: @TContractState, adventurer_id: u256) -> Stats;
    fn get_base_strength(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_base_dexterity(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_base_vitality(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_base_intelligence(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_base_wisdom(self: @TContractState, adventurer_id: u256) -> u8;
    fn get_base_charisma(self: @TContractState, adventurer_id: u256) -> u8;

    // beast details
    fn get_beast_health(self: @TContractState, adventurer_id: u256) -> u16;
    fn get_beast_type(self: @TContractState, beast_id: u8) -> u8;
    fn get_beast_tier(self: @TContractState, beast_id: u8) -> u8;

    // TODO: Game settings

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
trait IERC20<TContractState> {
    fn transferFrom(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn burn_away(ref self: TContractState, to: ContractAddress, amount: u256);
}
