use starknet::ContractAddress;

use survivor::adventurer::Adventurer;
use survivor::adventurer_meta::AdventurerMetadata;
use survivor::bag::Bag;
use lootitems::loot::Loot;

#[starknet::interface]
trait IGame<TContractState> {
    // actions ---------------------------------------------------
    fn start(ref self: TContractState, starting_weapon: u8, adventurer_meta: AdventurerMetadata);
    fn explore(ref self: TContractState, adventurer_id: u256);
    fn attack(ref self: TContractState, adventurer_id: u256);
    fn flee(ref self: TContractState, adventurer_id: u256);
    fn equip(ref self: TContractState, adventurer_id: u256, item_id: u8);
    fn buy_item(ref self: TContractState, adventurer_id: u256, item_id: u8, equip: bool);
    fn buy_health(ref self: TContractState, adventurer_id: u256);
    fn upgrade_stat(ref self: TContractState, adventurer_id: u256, stat: u8);
    fn slay_idle_adventurer(ref self: TContractState, adventurer_id: u256);

    // view ------------------------------------------------------
    fn get_adventurer(self: @TContractState, adventurer_id: u256) -> Adventurer;
    fn get_adventurer_meta(self: @TContractState, adventurer_id: u256) -> AdventurerMetadata;
    fn get_bag(self: @TContractState, adventurer_id: u256) -> Bag;
    fn get_items_on_market(self: @TContractState, adventurer_id: u256) -> Array<Loot>;
    fn get_dao_address(self: @TContractState) -> ContractAddress;
    fn get_lords_address(self: @TContractState) -> ContractAddress;
    fn get_entropy(self: @TContractState) -> u256;

    // setters ---------------------------------------------------
    fn set_entropy(ref self: TContractState);

    // checks
    fn owner_of(self: @TContractState, adventurer_id: u256) -> ContractAddress;
}
