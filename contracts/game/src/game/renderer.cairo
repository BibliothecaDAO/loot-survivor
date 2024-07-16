use alexandria_encoding::base64::{Base64Encoder, Base64Decoder, Base64UrlEncoder, Base64UrlDecoder};
use adventurer::{
    adventurer::{Adventurer, ImplAdventurer, IAdventurer}, stats::{Stats, ImplStats},
    adventurer_meta::{AdventurerMetadata, ImplAdventurerMetadata},
    equipment::{Equipment, EquipmentPacking}, adventurer_utils::{AdventurerUtils},
    bag::{Bag, IBag, ImplBag},
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
    text: ByteArray, x: ByteArray, y: ByteArray, fontsize: ByteArray, baseline: ByteArray
) -> ByteArray {
    "<text x='"
        + x
        + "' y='"
        + y
        + "' font-family='Courier, monospace' font-size='"
        + fontsize
        + "' fill='#3DEC00' text-anchor='start' dominant-baseline='"
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

fn len(f: felt252) -> usize {
    let mut f: u128 = f.try_into().unwrap();
    let mut l = 0;
    while f != 0 {
        f = f / 256;
        l += 1;
    };
    l
}

fn create_full_svg(
    adventurer_id: felt252, adventurer: Adventurer, adventurerMetadata: AdventurerMetadata, bag: Bag
) -> ByteArray {
    let rect = create_rect();

    let logo_element = "<g transform='translate(25,25) scale(4)'>" + logo() + "</g>";

    let mut _name = Default::default();
    _name.append_word(adventurerMetadata.name, len(adventurerMetadata.name));

    // Update text elements
    let name = create_text(_name, "117", "117.136", "32", "middle");
    let id = create_text("#" + format!("{}", adventurer_id), "123", "61.2273", "24", "middle");
    let level = create_text(
        "LVL" + format!("{}", adventurer.get_level()), "208.008", "61.2273", "24", "middle"
    );
    let health = create_text(
        format!("{}", adventurer.health)
            + "/"
            + format!("{}", adventurer.stats.vitality.into() * HEALTH_INCREASE_PER_VITALITY + 100)
            + "HP",
        "453.527",
        "58.2727",
        "20",
        "right"
    );
    let gold = create_text(
        format!("{}", adventurer.gold) + "GLD", "475.09", "93.2727", "20", "right"
    );

    // Stats
    let str = create_text(
        format!("{} STR", adventurer.stats.strength), "511.672", "128.273", "20", "right"
    );
    let dex = create_text(
        format!("{} DEX", adventurer.stats.dexterity), "510.891", "163.273", "20", "right"
    );
    let int = create_text(
        format!("{} INT", adventurer.stats.intelligence), "517.766", "198.273", "20", "right"
    );
    let vit = create_text(
        format!("{} VIT", adventurer.stats.vitality), "518.566", "233.273", "20", "right"
    );
    let wis = create_text(
        format!("{} WIS", adventurer.stats.wisdom), "512.863", "268.273", "20", "right"
    );
    let cha = create_text(
        format!("{} CHA", adventurer.stats.charisma), "497.707", "303.273", "20", "right"
    );
    let luck = create_text(
        format!("{} LUCK", adventurer.equipment.calculate_luck(bag)),
        "496.594",
        "338.273",
        "20",
        "right"
    );

    // Equipment sections
    let equipped_header = create_text("Equipped", "30", "183.136", "32", "middle");
    let bag_header = create_text("Bag", "30", "600.136", "32", "middle");

    // Combine all elements
    let mut elements = array![rect, logo_element, name, id, level,// health,
    // gold,
    // str,
    // dex,
    // int,
    // vit,
    // wis,
    // cha,
    // luck,
    // equipped_header,
    // bag_header,
    // create_text("Katana lvl 10", "30", "233.227", "24", "middle"),
    // create_text("Helm lvl 20", "30", "272.227", "24", "middle"),
    // create_text("Gloves lvl 20", "30", "311.227", "24", "middle"),
    // create_text("Ring lvl 20", "30", "350.227", "24", "middle"),
    // create_text("Greaves lvl 20", "30", "389.227", "24", "middle"),
    // create_text("Sash lvl 10", "30", "428.227", "24", "middle"),
    // create_text("Boots lvl 10", "30", "467.227", "24", "middle"),
    // create_text("Necklace lvl 10", "30", "506.227", "24", "middle"),
    // create_text("Katana lvl 10", "30", "644.273", "20", "middle"),
    // create_text("Helm lvl 20", "30", "678.273", "20", "middle"),
    // create_text("Ring lvl 20", "30", "712.273", "20", "middle"),
    // create_text("Greaves lvl 20", "30", "746.273", "20", "middle"),
    // create_text("Sash lvl 10", "30", "780.273", "20", "middle"),
    // create_text("Boots lvl 10", "30", "814.273", "20", "middle"),
    // create_text("Necklace lvl 10", "30", "848.273", "20", "middle"),
    // create_text("Katana lvl 10", "311", "644.273", "20", "middle"),
    // create_text("Helm lvl 20", "311", "678.273", "20", "middle"),
    // create_text("Ring lvl 20", "311", "712.273", "20", "middle"),
    // create_text("Greaves lvl 20", "311", "746.273", "20", "middle"),
    // create_text("Sash lvl 10", "311", "780.273", "20", "middle"),
    // create_text("Boots lvl 10", "311", "814.273", "20", "middle"),
    // create_text("Necklace lvl 10", "311", "848.273", "20", "middle"),
    ].span();

    let internals = combine_elements(ref elements);

    let svg = create_svg(internals);

    println!("{}", svg);

    svg
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
        let adventurer = ImplAdventurer::new(24);

        let adventurer_metadata = ImplAdventurerMetadata::new('survivor');

        let bag = ImplBag::new();

        let rect = create_full_svg(1, adventurer, adventurer_metadata, bag);
    }
}
