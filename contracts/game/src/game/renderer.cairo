use alexandria_encoding::base64::Base64Encoder;
use adventurer::{
    adventurer::{Adventurer, ImplAdventurer},
    adventurer_meta::{AdventurerMetadata, ImplAdventurerMetadata}, equipment::ImplEquipment,
    bag::Bag, item::{Item, ImplItem}, adventurer_utils::{AdventurerUtils},
};
use loot::{loot::ImplLoot, constants::{ImplItemNaming, ItemSuffix}};
use core::{array::{SpanTrait, ArrayTrait}, traits::Into, clone::Clone,};
use game::game::encoding::{bytes_base64_encode, U256BytesUsedTraitImpl};
use graffiti::json::JsonImpl;

fn logo() -> ByteArray {
    "<path fill='#3DEC00' d=\"M1 2V0h8v2h1v10H7v4H3v-4H0V2zm1 4v4h2v2h2v-2h2V6H6v4H4V6z\"/>"
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

fn get_suffix_boost(suffix: u8) -> ByteArray {
    if (suffix == ItemSuffix::of_Power) {
        "(+3 STR)"
    } else if (suffix == ItemSuffix::of_Giant) {
        "(+3 VIT)"
    } else if (suffix == ItemSuffix::of_Titans) {
        "(+2 STR, +1 CHA)"
    } else if (suffix == ItemSuffix::of_Skill) {
        "(+3 DEX)"
    } else if (suffix == ItemSuffix::of_Perfection) {
        "(+1 STR, +1 DEX, +1 VIT)"
    } else if (suffix == ItemSuffix::of_Brilliance) {
        "(+3 INT)"
    } else if (suffix == ItemSuffix::of_Enlightenment) {
        "(+3 WIS)"
    } else if (suffix == ItemSuffix::of_Protection) {
        "(+2 VIT, +1 DEX)"
    } else if (suffix == ItemSuffix::of_Anger) {
        "(+2 STR, +1 DEX)"
    } else if (suffix == ItemSuffix::of_Rage) {
        "(+1 STR, +1 CHA, +1 WIS)"
    } else if (suffix == ItemSuffix::of_Fury) {
        "(+1 VIT, +1 CHA, +1 INT)"
    } else if (suffix == ItemSuffix::of_Vitriol) {
        "(+2 INT, +1 WIS)"
    } else if (suffix == ItemSuffix::of_the_Fox) {
        "(+2 DEX, +1 CHA)"
    } else if (suffix == ItemSuffix::of_Detection) {
        "(+2 WIS, +1 DEX)"
    } else if (suffix == ItemSuffix::of_Reflection) {
        "(+2 WIS, +1 INT)"
    } else if (suffix == ItemSuffix::of_the_Twins) {
        "(+3 CHA)"
    } else {
        ""
    }
}

fn generate_item(item: Item, entropy: u64) -> ByteArray {
    if item.id == 0 {
        return "";
    }

    let greatness = item.get_greatness();
    let item_name = ImplItemNaming::item_id_to_string(item.id);

    let mut _item_name = Default::default();
    _item_name.append_word(item_name, U256BytesUsedTraitImpl::bytes_used(item_name.into()).into());

    if (greatness >= 15) {
        format!("G{} {} ", greatness, _item_name)
            + get_suffix_boost(ImplLoot::get_suffix(item.id, entropy))
    } else {
        format!("G{} {} ", greatness, _item_name)
    }
}

fn create_metadata(
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

    let _adventurer_id = format!("{}", adventurer_id);
    let _level = format!("{}", adventurer.get_level());

    let _health = format!("{}", adventurer.health);

    let _max_health = format!("{}", AdventurerUtils::get_max_health(adventurer.stats.vitality));

    let _gold = format!("{}", adventurer.gold);
    let _str = format!("{}", adventurer.stats.strength);
    let _dex = format!("{}", adventurer.stats.dexterity);
    let _int = format!("{}", adventurer.stats.intelligence);
    let _vit = format!("{}", adventurer.stats.vitality);
    let _wis = format!("{}", adventurer.stats.wisdom);
    let _cha = format!("{}", adventurer.stats.charisma);
    let _luck = format!("{}", adventurer.stats.luck);

    // Equipped items
    let _equiped_weapon = generate_item(
        adventurer.equipment.weapon, adventurerMetadata.start_entropy
    );
    let _equiped_chest = generate_item(
        adventurer.equipment.chest, adventurerMetadata.start_entropy
    );
    let _equiped_head = generate_item(adventurer.equipment.head, adventurerMetadata.start_entropy);
    let _equiped_waist = generate_item(
        adventurer.equipment.waist, adventurerMetadata.start_entropy
    );
    let _equiped_foot = generate_item(adventurer.equipment.foot, adventurerMetadata.start_entropy);
    let _equiped_hand = generate_item(adventurer.equipment.hand, adventurerMetadata.start_entropy);
    let _equiped_neck = generate_item(adventurer.equipment.neck, adventurerMetadata.start_entropy);
    let _equiped_ring = generate_item(adventurer.equipment.ring, adventurerMetadata.start_entropy);

    // Bag items
    let _bag_item_1 = generate_item(bag.item_1, adventurerMetadata.start_entropy);
    let _bag_item_2 = generate_item(bag.item_2, adventurerMetadata.start_entropy);
    let _bag_item_3 = generate_item(bag.item_3, adventurerMetadata.start_entropy);
    let _bag_item_4 = generate_item(bag.item_4, adventurerMetadata.start_entropy);
    let _bag_item_5 = generate_item(bag.item_5, adventurerMetadata.start_entropy);
    let _bag_item_6 = generate_item(bag.item_6, adventurerMetadata.start_entropy);
    let _bag_item_7 = generate_item(bag.item_7, adventurerMetadata.start_entropy);
    let _bag_item_8 = generate_item(bag.item_8, adventurerMetadata.start_entropy);
    let _bag_item_9 = generate_item(bag.item_9, adventurerMetadata.start_entropy);
    let _bag_item_10 = generate_item(bag.item_10, adventurerMetadata.start_entropy);
    let _bag_item_11 = generate_item(bag.item_11, adventurerMetadata.start_entropy);
    let _bag_item_12 = generate_item(bag.item_12, adventurerMetadata.start_entropy);
    let _bag_item_13 = generate_item(bag.item_13, adventurerMetadata.start_entropy);
    let _bag_item_14 = generate_item(bag.item_14, adventurerMetadata.start_entropy);
    let _bag_item_15 = generate_item(bag.item_15, adventurerMetadata.start_entropy);

    // Combine all elements
    let mut elements = array![
        rect,
        logo_element,
        create_text(_name.clone(), "117", "117.136", "32", "middle", "left"),
        create_text("#" + _adventurer_id.clone(), "123", "61.2273", "24", "middle", "left"),
        create_text("LVL " + _level.clone(), "235", "61.2273", "24", "middle", "end"),
        create_text(
            _health.clone() + " / " + _max_health.clone() + " HP",
            "570",
            "58.2727",
            "20",
            "right",
            "end"
        ),
        create_text(_gold.clone() + " GLD", "570", "93.2727", "20", "right", "end"),
        create_text(_str.clone() + " STR", "570", "128.273", "20", "right", "end"),
        create_text(_dex.clone() + " DEX", "570", "163.273", "20", "right", "end"),
        create_text(_int.clone() + " INT", "570", "198.273", "20", "right", "end"),
        create_text(_vit.clone() + " VIT", "570", "233.273", "20", "right", "end"),
        create_text(_wis.clone() + " WIS", "570", "268.273", "20", "right", "end"),
        create_text(_cha.clone() + " CHA", "570", "303.273", "20", "right", "end"),
        create_text(_luck.clone() + " LUCK", "570", "338.273", "20", "right", "end"),
        create_text("Equipped", "30", "183.136", "32", "middle", "right"),
        create_text("Bag", "30", "600.136", "32", "middle", "right"),
        create_text(_equiped_weapon.clone(), "30", "233.227", "21", "middle", "start"),
        create_text(_equiped_chest.clone(), "30", "272.227", "21", "middle", "left"),
        create_text(_equiped_head.clone(), "30", "311.227", "21", "middle", "left"),
        create_text(_equiped_waist.clone(), "30", "350.227", "21", "middle", "left"),
        create_text(_equiped_foot.clone(), "30", "389.227", "21", "middle", "left"),
        create_text(_equiped_hand.clone(), "30", "428.227", "21", "middle", "left"),
        create_text(_equiped_neck.clone(), "30", "467.227", "21", "middle", "left"),
        create_text(_equiped_ring.clone(), "30", "506.227", "21", "middle", "left"),
        create_text(_bag_item_1.clone(), "30", "644.273", "16", "middle", "left"),
        create_text(_bag_item_2.clone(), "30", "678.273", "16", "middle", "left"),
        create_text(_bag_item_3.clone(), "30", "712.273", "16", "middle", "left"),
        create_text(_bag_item_4.clone(), "30", "746.273", "16", "middle", "left"),
        create_text(_bag_item_5.clone(), "30", "780.273", "16", "middle", "left"),
        create_text(_bag_item_6.clone(), "30", "814.273", "16", "middle", "left"),
        create_text(_bag_item_7.clone(), "30", "848.273", "16", "middle", "left"),
        create_text(_bag_item_8.clone(), "311", "644.273", "16", "middle", "left"),
        create_text(_bag_item_9.clone(), "311", "678.273", "16", "middle", "left"),
        create_text(_bag_item_10.clone(), "311", "712.273", "16", "middle", "left"),
        create_text(_bag_item_11.clone(), "311", "746.273", "16", "middle", "left"),
        create_text(_bag_item_12.clone(), "311", "780.273", "16", "middle", "left"),
        create_text(_bag_item_13.clone(), "311", "814.273", "16", "middle", "left"),
        create_text(_bag_item_14.clone(), "311", "848.273", "16", "middle", "left"),
        create_text(_bag_item_15.clone(), "311", "878.273", "16", "middle", "left"),
    ]
        .span();

    let image = create_svg(combine_elements(ref elements));

    let base64_image = format!("data:image/svg+xml;base64,{}", bytes_base64_encode(image));

    let mut metadata = JsonImpl::new()
        .add("name", "Survivor" + " #" + _adventurer_id)
        .add(
            "description",
            "An NFT representing a game of Loot Survivor. These can be used to transfer game ownership, gift a game of Loot Survivor, and also change the address that player rewards are dispursed to. This NFT also serves as a simple, fully onchain viewer for your survivor stats."
        )
        .add("image", base64_image);

    let name: ByteArray = JsonImpl::new().add("trait", "Name").add("value", _name).build();
    let level: ByteArray = JsonImpl::new().add("trait", "Level").add("value", _level).build();
    let health: ByteArray = JsonImpl::new().add("trait", "Health").add("value", _health).build();
    let gold: ByteArray = JsonImpl::new().add("trait", "Gold").add("value", _gold).build();
    let str: ByteArray = JsonImpl::new().add("trait", "Strength").add("value", _str).build();
    let dex: ByteArray = JsonImpl::new().add("trait", "Dexterity").add("value", _dex).build();
    let int: ByteArray = JsonImpl::new().add("trait", "Intelligence").add("value", _int).build();
    let vit: ByteArray = JsonImpl::new().add("trait", "Vitality").add("value", _vit).build();
    let wis: ByteArray = JsonImpl::new().add("trait", "Wisdom").add("value", _wis).build();
    let cha: ByteArray = JsonImpl::new().add("trait", "Charisma").add("value", _cha).build();
    let luck: ByteArray = JsonImpl::new().add("trait", "Luck").add("value", _luck).build();

    let equipped_weapon: ByteArray = JsonImpl::new()
        .add("trait", "Weapon")
        .add("value", _equiped_weapon)
        .build();
    let equipped_chest: ByteArray = JsonImpl::new()
        .add("trait", "Chest Armor")
        .add("value", _equiped_chest)
        .build();
    let equipped_head: ByteArray = JsonImpl::new()
        .add("trait", "Head Armor")
        .add("value", _equiped_head)
        .build();
    let equipped_waist: ByteArray = JsonImpl::new()
        .add("trait", "Waist Armor")
        .add("value", _equiped_waist)
        .build();
    let equipped_foot: ByteArray = JsonImpl::new()
        .add("trait", "Foot Armor")
        .add("value", _equiped_foot)
        .build();
    let equipped_hand: ByteArray = JsonImpl::new()
        .add("trait", "Hand Armor")
        .add("value", _equiped_hand)
        .build();
    let equipped_neck: ByteArray = JsonImpl::new()
        .add("trait", "Necklace")
        .add("value", _equiped_neck)
        .build();
    let equipped_ring: ByteArray = JsonImpl::new()
        .add("trait", "Ring")
        .add("value", _equiped_ring)
        .build();

    let bag_item_1: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 1")
        .add("value", _bag_item_1)
        .build();
    let bag_item_2: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 2")
        .add("value", _bag_item_2)
        .build();
    let bag_item_3: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 3")
        .add("value", _bag_item_3)
        .build();
    let bag_item_4: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 4")
        .add("value", _bag_item_4)
        .build();
    let bag_item_5: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 5")
        .add("value", _bag_item_5)
        .build();
    let bag_item_6: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 6")
        .add("value", _bag_item_6)
        .build();
    let bag_item_7: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 7")
        .add("value", _bag_item_7)
        .build();
    let bag_item_8: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 8")
        .add("value", _bag_item_8)
        .build();
    let bag_item_9: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 9")
        .add("value", _bag_item_9)
        .build();
    let bag_item_10: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 10")
        .add("value", _bag_item_10)
        .build();
    let bag_item_11: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 11")
        .add("value", _bag_item_11)
        .build();
    let bag_item_12: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 12")
        .add("value", _bag_item_12)
        .build();
    let bag_item_13: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 13")
        .add("value", _bag_item_13)
        .build();
    let bag_item_14: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 14")
        .add("value", _bag_item_14)
        .build();
    let bag_item_15: ByteArray = JsonImpl::new()
        .add("trait", "Bag Item 15")
        .add("value", _bag_item_15)
        .build();

    let attributes = array![
        name,
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
        equipped_weapon,
        equipped_chest,
        equipped_head,
        equipped_waist,
        equipped_foot,
        equipped_hand,
        equipped_neck,
        equipped_ring,
        bag_item_1,
        bag_item_2,
        bag_item_3,
        bag_item_4,
        bag_item_5,
        bag_item_6,
        bag_item_7,
        bag_item_8,
        bag_item_9,
        bag_item_10,
        bag_item_11,
        bag_item_12,
        bag_item_13,
        bag_item_14,
        bag_item_15,
    ]
        .span();

    let metadata = metadata.add_array("attributes", attributes).build();

    format!("data:application/json;base64,{}", bytes_base64_encode(metadata))
}


#[cfg(test)]
mod tests {
    use core::array::ArrayTrait;
    use super::{create_metadata};
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

        let rect = create_metadata(1, adventurer, adventurer_metadata, bag);

        println!("{}", rect);
    }
}

