use starknet::{ContractAddress};

use survivor::adventurer::{Adventurer, ImplAdventurer, IAdventurer};
use survivor::adventurer_meta::{AdventurerMetadata, ImplAdventurerMetadata};
use survivor::bag::{Bag, BagActions, ImplBagActions, LootStatistics};
use lootitems::loot::{Loot, ImplLoot};

#[starknet::interface]
trait IGame<T> {
    fn start(ref self: T, starting_weapon: u8, adventurer_meta: AdventurerMetadata);
    fn explore(ref self: T, adventurer_id: u256);
    fn attack(ref self: T, adventurer_id: u256);
    fn flee(ref self: T, adventurer_id: u256);
    fn equip(ref self: T, adventurer_id: u256, item_id: u8);
    fn buy_item(ref self: T, adventurer_id: u256, item_id: u8, equip: bool);
    fn upgrade_stat(ref self: T, adventurer_id: u256, stat: u8);
    fn purchase_health(ref self: T, adventurer_id: u256);

    // view ------------------------------------------------------
    fn get_adventurer(self: @T, adventurer_id: u256) -> Adventurer;
    fn get_adventurer_meta(self: @T, adventurer_id: u256) -> AdventurerMetadata;


    fn get_bag(self: @T, adventurer_id: u256) -> Bag;
    fn get_items_on_market(self: @T, adventurer_id: u256) -> Array<Loot>;

    fn owner_of(self: @T, adventurer_id: u256) -> ContractAddress;
}
