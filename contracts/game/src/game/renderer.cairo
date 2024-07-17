use adventurer::item::IItemPrimitive;
use alexandria_encoding::base64::{Base64Encoder, Base64Decoder, Base64UrlEncoder, Base64UrlDecoder};
use adventurer::{
    adventurer::{Adventurer, ImplAdventurer, IAdventurer}, stats::{Stats, ImplStats},
    adventurer_meta::{AdventurerMetadata, ImplAdventurerMetadata},
    equipment::{Equipment, EquipmentPacking, ImplEquipment}, adventurer_utils::{AdventurerUtils},
    bag::{Bag, IBag, ImplBag}, item::{Item, ImplItem, ItemPacking},
    constants::{
        adventurer_constants::{
            STARTING_GOLD, StatisticIndex, POTION_PRICE, STARTING_HEALTH, CHARISMA_POTION_DISCOUNT,
            MINIMUM_ITEM_PRICE, MINIMUM_POTION_PRICE, HEALTH_INCREASE_PER_VITALITY, MAX_GOLD,
            MAX_STAT_UPGRADES_AVAILABLE, MAX_ADVENTURER_XP, MAX_ADVENTURER_BLOCKS,
            ITEM_MAX_GREATNESS, ITEM_MAX_XP, MAX_ADVENTURER_HEALTH, CHARISMA_ITEM_DISCOUNT,
            MAX_BLOCK_COUNT, STAT_UPGRADE_POINTS_PER_LEVEL, NECKLACE_G20_BONUS_STATS,
            SILVER_RING_G20_LUCK_BONUS, BEAST_SPECIAL_NAME_LEVEL_UNLOCK, U128_MAX, U64_MAX,
            JEWELRY_BONUS_BEAST_GOLD_PERCENT, JEWELRY_BONUS_CRITICAL_HIT_PERCENT_PER_GREATNESS,
            JEWELRY_BONUS_NAME_MATCH_PERCENT_PER_GREATNESS, NECKLACE_ARMOR_BONUS,
            MINIMUM_DAMAGE_FROM_BEASTS, SILVER_RING_LUCK_BONUS_PER_GREATNESS,
            MINIMUM_DAMAGE_FROM_OBSTACLES, MINIMUM_DAMAGE_TO_BEASTS, MAX_PACKABLE_BEAST_HEALTH,
            CRITICAL_HIT_LEVEL_MULTIPLIER
        },
    },
};
use loot::{loot::ImplLoot, constants::ImplItemNaming};
use core::{
    array::{SpanTrait, ArrayTrait}, integer::u256_try_as_non_zero, traits::{TryInto, Into},
    clone::Clone, poseidon::poseidon_hash_span, option::OptionTrait, box::BoxTrait,
    starknet::{
        get_caller_address, ContractAddress, ContractAddressIntoFelt252, contract_address_const,
        get_block_timestamp, info::BlockInfo
    },
};
use core::bytes_31::{
    BYTES_IN_BYTES31, Bytes31Trait, one_shift_left_bytes_felt252, one_shift_left_bytes_u128,
    POW_2_128, POW_2_8, U128IntoBytes31, U8IntoBytes31
};

fn logo() -> ByteArray {
    "<svg xmlns=\"http://www.w3.org/2000/svg\" fill='#3DEC00' viewBox=\"0 0 10 16\"><g><g><path d=\"M1 2V0h8v2h1v10H7v4H3v-4H0V2zm1 4v4h2v2h2v-2h2V6H6v4H4V6z\"/></g></g></svg>"
}

fn create_rect() -> ByteArray {
    "<rect x='0.5' y='0.5' width='599' height='899' rx='27.5' fill='black' stroke='#3DEC00'/>"
}

fn create_text(
    text: ByteArray,
    x: ByteArray,
    y: ByteArray,
    fontsize: ByteArray,
    baseline: ByteArray,
    text_anchor: ByteArray
) -> ByteArray {
    "<text x='"
        + x
        + "' y='"
        + y
        + "' font-family='Courier, monospace' font-size='"
        + fontsize
        + "' fill='#3DEC00' text-anchor='"
        + text_anchor
        + "' dominant-baseline='"
        + baseline
        + "'>"
        + text
        + "</text>"
}

fn combine_elements(ref elements: Span<ByteArray>) -> ByteArray {
    let mut count: u8 = 1;

    let mut combined: ByteArray = "";
    loop {
        match elements.pop_front() {
            Option::Some(element) => {
                combined += element.clone();

                count += 1;
            },
            Option::None(()) => { break; }
        }
    };

    combined
}

fn create_svg(internals: ByteArray) -> ByteArray {
    "<svg xmlns='http://www.w3.org/2000/svg' width='600' height='900'>" + internals + "</svg>"
}

fn generate_item(item: Item, entropy: u64) -> ByteArray {
    let greatness = item.get_greatness();

    let specials = ImplLoot::get_specials(item.id, greatness, entropy);

    let item_name = ImplItemNaming::item_id_to_string(item.id);

    let mut _item_name = Default::default();
    _item_name.append_word(item_name, U256BytesUsedTraitImpl::bytes_used(item_name.into()).into());

    let mut _item_prefix_1 = Default::default();
    _item_prefix_1
        .append_word(
            ImplItemNaming::prefix1_to_string(specials.special1),
            U256BytesUsedTraitImpl::bytes_used(
                ImplItemNaming::prefix1_to_string(specials.special1).into()
            )
                .into()
        );

    let mut _item_prefix_2 = Default::default();
    _item_prefix_2
        .append_word(
            ImplItemNaming::prefix2_to_string(specials.special2),
            U256BytesUsedTraitImpl::bytes_used(
                ImplItemNaming::prefix1_to_string(specials.special2).into()
            )
                .into()
        );

    let mut _item_suffix = Default::default();
    _item_suffix
        .append_word(
            ImplItemNaming::suffix_to_string(specials.special3),
            U256BytesUsedTraitImpl::bytes_used(
                ImplItemNaming::prefix1_to_string(specials.special3).into()
            )
                .into()
        );

    if (specials.special1 != 0) {
        _item_prefix_1 = _item_prefix_1 + " ";
    } else {
        _item_prefix_1 = "";
    }

    if (specials.special2 != 0) {
        _item_prefix_2 = _item_prefix_2 + " ";
    } else {
        _item_prefix_2 = "";
    }

    if (specials.special3 != 0) {
        _item_suffix = " " + _item_suffix;
    } else {
        _item_suffix = "";
    }

    _item_prefix_1 + _item_prefix_2 + _item_name + _item_suffix
}

fn create_full_svg(
    adventurer_id: felt252, adventurer: Adventurer, adventurerMetadata: AdventurerMetadata, bag: Bag
) -> ByteArray {
    let rect = create_rect();

    let logo_element = "<g transform='translate(25,25) scale(4)'>" + logo() + "</g>";

    let mut _name = Default::default();
    _name
        .append_word(
            adventurerMetadata.name,
            U256BytesUsedTraitImpl::bytes_used(adventurerMetadata.name.into()).into()
        );

    // Update text elements
    let name = create_text(_name, "117", "117.136", "32", "middle", "left");
    let id = create_text(format!("# {}", adventurer_id), "123", "61.2273", "24", "middle", "left");
    let level = create_text(
        format!("LVL {}", adventurer.get_level()), "228.008", "61.2273", "24", "middle", "end"
    );
    let stat_boosts = adventurer.equipment.get_stat_boosts(adventurerMetadata.start_entropy);

    let health = create_text(
        format!(
            " {} / {} HP",
            adventurer.health,
            stat_boosts.vitality.into() * HEALTH_INCREASE_PER_VITALITY.into() + STARTING_HEALTH
        ),
        "570",
        "58.2727",
        "20",
        "right",
        "end"
    );

    let gold = create_text(
        format!("{} GLD", adventurer.gold), "570", "93.2727", "20", "right", "end"
    );

    // Stats
    let str = create_text(
        format!("{} STR", stat_boosts.strength), "570", "128.273", "20", "right", "end"
    );
    let dex = create_text(
        format!("{} DEX", stat_boosts.dexterity), "570", "163.273", "20", "right", "end"
    );
    let int = create_text(
        format!("{} INT", stat_boosts.intelligence), "570", "198.273", "20", "right", "end"
    );
    let vit = create_text(
        format!("{} VIT", stat_boosts.vitality), "570", "233.273", "20", "right", "end"
    );
    let wis = create_text(
        format!("{} WIS", stat_boosts.wisdom), "570", "268.273", "20", "right", "end"
    );
    let cha = create_text(
        format!("{} CHA", stat_boosts.charisma), "570", "303.273", "20", "right", "end"
    );
    let luck = create_text(
        format!("{} LUCK", adventurer.equipment.calculate_luck(bag)),
        "570",
        "338.273",
        "20",
        "right",
        "end"
    );

    // Equipment sections
    let equipped_header = create_text("Equipped", "30", "183.136", "32", "middle", "right");
    let bag_header = create_text("Bag", "30", "600.136", "32", "middle", "right");

    // Combine all elements
    let mut elements = array![
        rect,
        logo_element,
        name,
        id,
        level,
        health,
        gold,
        str,
        dex,
        int,
        vit,
        wis,
        cha,
        luck,
        equipped_header,
        bag_header,
        create_text(
            generate_item(adventurer.equipment.weapon, adventurerMetadata.start_entropy),
            "30",
            "233.227",
            "24",
            "middle",
            "start"
        ),
        create_text(
            generate_item(adventurer.equipment.chest, adventurerMetadata.start_entropy),
            "30",
            "272.227",
            "24",
            "middle",
            "left"
        ),
        create_text(
            generate_item(adventurer.equipment.head, adventurerMetadata.start_entropy),
            "30",
            "311.227",
            "24",
            "middle",
            "left"
        ),
        create_text(
            generate_item(adventurer.equipment.waist, adventurerMetadata.start_entropy),
            "30",
            "350.227",
            "24",
            "middle",
            "left"
        ),
        create_text(
            generate_item(adventurer.equipment.foot, adventurerMetadata.start_entropy),
            "30",
            "389.227",
            "24",
            "middle",
            "left"
        ),
        create_text(
            generate_item(adventurer.equipment.hand, adventurerMetadata.start_entropy),
            "30",
            "428.227",
            "24",
            "middle",
            "left"
        ),
        create_text(
            generate_item(adventurer.equipment.neck, adventurerMetadata.start_entropy),
            "30",
            "467.227",
            "24",
            "middle",
            "left"
        ),
        create_text(
            generate_item(adventurer.equipment.ring, adventurerMetadata.start_entropy),
            "30",
            "506.227",
            "24",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_1, adventurerMetadata.start_entropy),
            "30",
            "644.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_2, adventurerMetadata.start_entropy),
            "30",
            "678.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_3, adventurerMetadata.start_entropy),
            "30",
            "712.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_4, adventurerMetadata.start_entropy),
            "30",
            "746.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_5, adventurerMetadata.start_entropy),
            "30",
            "780.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_6, adventurerMetadata.start_entropy),
            "30",
            "814.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_7, adventurerMetadata.start_entropy),
            "30",
            "848.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_8, adventurerMetadata.start_entropy),
            "311",
            "644.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_9, adventurerMetadata.start_entropy),
            "311",
            "678.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_10, adventurerMetadata.start_entropy),
            "311",
            "712.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_11, adventurerMetadata.start_entropy),
            "311",
            "746.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_12, adventurerMetadata.start_entropy),
            "311",
            "780.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_13, adventurerMetadata.start_entropy),
            "311",
            "814.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_14, adventurerMetadata.start_entropy),
            "311",
            "848.273",
            "20",
            "middle",
            "left"
        ),
        create_text(
            generate_item(bag.item_15, adventurerMetadata.start_entropy),
            "311",
            "878.273",
            "20",
            "middle",
            "left"
        ),
    ]
        .span();

    create_svg(combine_elements(ref elements))
}


#[cfg(test)]
mod tests {
    use core::array::ArrayTrait;
    use super::{create_full_svg};
    use adventurer::{
        adventurer::{Adventurer, ImplAdventurer, IAdventurer}, stats::{Stats, ImplStats},
        adventurer_meta::{AdventurerMetadata, ImplAdventurerMetadata},
        equipment::{Equipment, EquipmentPacking}, adventurer_utils::{AdventurerUtils},
        bag::{Bag, IBag, ImplBag}, item::{ImplItem, Item},
    };


    #[test]
    fn print() {
        let adventurer = ImplAdventurer::new(42);

        let adventurer_metadata = ImplAdventurerMetadata::new('survivor');

        let bag = ImplBag::new();

        let rect = create_full_svg(1, adventurer, adventurer_metadata, bag);

        println!("{}", rect);
    }
}

use keccak::{cairo_keccak, u128_split};
use integer::{BoundedInt, u32_as_non_zero, U32TryIntoNonZero};
trait BytesUsedTrait<T> {
    /// Returns the number of bytes used to represent a `T` value.
    /// # Arguments
    /// * `self` - The value to check.
    /// # Returns
    /// The number of bytes used to represent the value.
    fn bytes_used(self: T) -> u8;
}

impl U8BytesUsedTraitImpl of BytesUsedTrait<u8> {
    fn bytes_used(self: u8) -> u8 {
        if self == 0 {
            return 0;
        }

        return 1;
    }
}

impl USizeBytesUsedTraitImpl of BytesUsedTrait<usize> {
    fn bytes_used(self: usize) -> u8 {
        if self < 0x10000 { // 256^2
            if self < 0x100 { // 256^1
                if self == 0 {
                    return 0;
                } else {
                    return 1;
                };
            }
            return 2;
        } else {
            if self < 0x1000000 { // 256^3
                return 3;
            }
            return 4;
        }
    }
}

impl U64BytesUsedTraitImpl of BytesUsedTrait<u64> {
    fn bytes_used(self: u64) -> u8 {
        if self <= BoundedInt::<u32>::max().into() { // 256^4
            return BytesUsedTrait::<u32>::bytes_used(self.try_into().unwrap());
        } else {
            if self < 0x1000000000000 { // 256^6
                if self < 0x10000000000 {
                    if self < 0x100000000 {
                        return 4;
                    }
                    return 5;
                }
                return 6;
            } else {
                if self < 0x100000000000000 { // 256^7
                    return 7;
                } else {
                    return 8;
                }
            }
        }
    }
}


impl U128BytesTraitUsedImpl of BytesUsedTrait<u128> {
    fn bytes_used(self: u128) -> u8 {
        let (u64high, u64low) = u128_split(self);
        if u64high == 0 {
            return BytesUsedTrait::<u64>::bytes_used(u64low.try_into().unwrap());
        } else {
            return BytesUsedTrait::<u64>::bytes_used(u64high.try_into().unwrap()) + 8;
        }
    }
}

impl U256BytesUsedTraitImpl of BytesUsedTrait<u256> {
    fn bytes_used(self: u256) -> u8 {
        if self.high == 0 {
            return BytesUsedTrait::<u128>::bytes_used(self.low.try_into().unwrap());
        } else {
            return BytesUsedTrait::<u128>::bytes_used(self.high.try_into().unwrap()) + 16;
        }
    }
}
