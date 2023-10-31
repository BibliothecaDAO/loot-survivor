use core::{
    serde::Serde, clone::Clone, option::OptionTrait, starknet::StorePacking, traits::{TryInto, Into}
};

use combat::{combat::ImplCombat, constants::CombatEnums::{Type, Tier, Slot}};
use super::{
    constants::{
        NamePrefixLength, ItemNameSuffix, ItemId, ItemNamePrefix, NameSuffixLength,
        ItemSuffixLength, ItemSuffix, NUM_ITEMS, ItemIndex, ItemSlotLength
    },
    utils::{
        NameUtils::{
            is_special3_set1, is_special3_set2, is_special3_set3, is_special1_set1,
            is_special1_set2, is_special2_set1, is_special2_set2, is_special2_set3
        },
        ItemUtils
    }
};

#[derive(Copy, Drop, Serde)]
struct Loot {
    id: u8,
    tier: Tier,
    item_type: Type,
    slot: Slot,
}

impl LootPacking of StorePacking<Loot, felt252> {
    fn pack(value: Loot) -> felt252 {
        let item_tier = ImplCombat::tier_to_u8(value.tier);
        let item_type = ImplCombat::type_to_u8(value.item_type);
        let item_slot = ImplCombat::slot_to_u8(value.slot);

        (value.id.into()
            + item_tier.into() * TWO_POW_8
            + item_type.into() * TWO_POW_16
            + item_slot.into() * TWO_POW_24)
            .try_into()
            .unwrap()
    }
    fn unpack(value: felt252) -> Loot {
        let packed = value.into();
        let (packed, item_id) = integer::U256DivRem::div_rem(packed, TWO_POW_8.try_into().unwrap());
        let (packed, item_tier) = integer::U256DivRem::div_rem(
            packed, TWO_POW_8.try_into().unwrap()
        );
        let (packed, item_type) = integer::U256DivRem::div_rem(
            packed, TWO_POW_8.try_into().unwrap()
        );
        let (_, item_slot) = integer::U256DivRem::div_rem(packed, TWO_POW_8.try_into().unwrap());

        Loot {
            id: item_id.try_into().unwrap(),
            tier: ImplCombat::u8_to_tier(item_tier.try_into().unwrap()),
            item_type: ImplCombat::u8_to_type(item_type.try_into().unwrap()),
            slot: ImplCombat::u8_to_slot(item_slot.try_into().unwrap())
        }
    }
}

#[generate_trait]
impl ImplLoot of ILoot {
    // generate_naming_seed generates a seed for naming an item.
    // @param self The item.
    // @param entropy The entropy.
    // @return The naming seed.
    #[inline(always)]
    fn generate_naming_seed(item_id: u8, entropy: u128) -> u128 {
        let rnd = entropy % NUM_ITEMS.into();
        rnd * ImplLoot::get_slot_length(ImplLoot::get_slot(item_id)).into()
            + ImplLoot::get_item_index(item_id).into()
    }

    // generate_prefix1 returns the name prefix of an item (Agony, Apocalypse, Armageddon, etc)
    // @param self The item.
    // @param entropy The entropy.
    // @return The name prefix id.
    #[inline(always)]
    fn generate_prefix1(item_id: u8, entropy: u128) -> u8 {
        (ImplLoot::generate_naming_seed(item_id, entropy) % NamePrefixLength.into() + 1)
            .try_into()
            .unwrap()
    }

    // generate_prefix2 returns the name suffix of an item (Bane, Root, Bite, etc)
    // @param self The item.
    // @param entropy The entropy.
    // @return The name suffix id.
    #[inline(always)]
    fn generate_prefix2(item_id: u8, entropy: u128) -> u8 {
        (ImplLoot::generate_naming_seed(item_id, entropy) % NameSuffixLength.into() + 1)
            .try_into()
            .unwrap()
    }

    // @notice gets the item suffix of an item (of_Power, of_Giant, of_Titans, etc)
    // @param item_id the id of the item to get special1 for
    // @param entropy The entropy for randomness
    // @return u8 special1 for the item
    #[inline(always)]
    fn get_special1(item_id: u8, entropy: u128) -> u8 {
        (ImplLoot::generate_naming_seed(item_id, entropy) % ItemSuffixLength.into() + 1)
            .try_into()
            .unwrap()
    }

    // @notice gets Loot item from item id
    // @param id the id of the item to get
    // @return the Loot item
    fn get_item(id: u8) -> Loot {
        if id == ItemId::Pendant {
            return ItemUtils::get_pendant();
        } else if id == ItemId::Necklace {
            return ItemUtils::get_necklace();
        } else if id == ItemId::Amulet {
            return ItemUtils::get_amulet();
        } else if (id == ItemId::SilverRing) {
            return ItemUtils::get_silver_ring();
        } else if (id == ItemId::BronzeRing) {
            return ItemUtils::get_bronze_ring();
        } else if (id == ItemId::PlatinumRing) {
            return ItemUtils::get_platinum_ring();
        } else if (id == ItemId::TitaniumRing) {
            return ItemUtils::get_titanium_ring();
        } else if (id == ItemId::GoldRing) {
            return ItemUtils::get_gold_ring();
        } else if (id == ItemId::GhostWand) {
            return ItemUtils::get_ghost_wand();
        } else if (id == ItemId::GraveWand) {
            return ItemUtils::get_grave_wand();
        } else if (id == ItemId::BoneWand) {
            return ItemUtils::get_bone_wand();
        } else if (id == ItemId::Wand) {
            return ItemUtils::get_wand();
        } else if (id == ItemId::Grimoire) {
            return ItemUtils::get_grimoire();
        } else if (id == ItemId::Chronicle) {
            return ItemUtils::get_chronicle();
        } else if (id == ItemId::Tome) {
            return ItemUtils::get_tome();
        } else if (id == ItemId::Book) {
            return ItemUtils::get_book();
        } else if (id == ItemId::DivineRobe) {
            return ItemUtils::get_divine_robe();
        } else if (id == ItemId::SilkRobe) {
            return ItemUtils::get_silk_robe();
        } else if (id == ItemId::LinenRobe) {
            return ItemUtils::get_linen_robe();
        } else if (id == ItemId::Robe) {
            return ItemUtils::get_robe();
        } else if (id == ItemId::Shirt) {
            return ItemUtils::get_shirt();
        } else if (id == ItemId::Crown) {
            return ItemUtils::get_crown();
        } else if (id == ItemId::DivineHood) {
            return ItemUtils::get_divine_hood();
        } else if (id == ItemId::SilkHood) {
            return ItemUtils::get_silk_hood();
        } else if (id == ItemId::LinenHood) {
            return ItemUtils::get_linen_hood();
        } else if (id == ItemId::Hood) {
            return ItemUtils::get_hood();
        } else if (id == ItemId::BrightsilkSash) {
            return ItemUtils::get_brightsilk_sash();
        } else if (id == ItemId::SilkSash) {
            return ItemUtils::get_silk_sash();
        } else if (id == ItemId::WoolSash) {
            return ItemUtils::get_wool_sash();
        } else if (id == ItemId::LinenSash) {
            return ItemUtils::get_linen_sash();
        } else if (id == ItemId::Sash) {
            return ItemUtils::get_sash();
        } else if (id == ItemId::DivineSlippers) {
            return ItemUtils::get_divine_slippers();
        } else if (id == ItemId::SilkSlippers) {
            return ItemUtils::get_silk_slippers();
        } else if (id == ItemId::WoolShoes) {
            return ItemUtils::get_wool_shoes();
        } else if (id == ItemId::LinenShoes) {
            return ItemUtils::get_linen_shoes();
        } else if (id == ItemId::Shoes) {
            return ItemUtils::get_shoes();
        } else if (id == ItemId::DivineGloves) {
            return ItemUtils::get_divine_gloves();
        } else if (id == ItemId::SilkGloves) {
            return ItemUtils::get_silk_gloves();
        } else if (id == ItemId::WoolGloves) {
            return ItemUtils::get_wool_gloves();
        } else if (id == ItemId::LinenGloves) {
            return ItemUtils::get_linen_gloves();
        } else if (id == ItemId::Gloves) {
            return ItemUtils::get_gloves();
        } else if (id == ItemId::Katana) {
            return ItemUtils::get_katana();
        } else if (id == ItemId::Falchion) {
            return ItemUtils::get_falchion();
        } else if (id == ItemId::Scimitar) {
            return ItemUtils::get_scimitar();
        } else if (id == ItemId::LongSword) {
            return ItemUtils::get_long_sword();
        } else if (id == ItemId::ShortSword) {
            return ItemUtils::get_short_sword();
        } else if (id == ItemId::DemonHusk) {
            return ItemUtils::get_demon_husk();
        } else if (id == ItemId::DragonskinArmor) {
            return ItemUtils::get_dragonskin_armor();
        } else if (id == ItemId::StuddedLeatherArmor) {
            return ItemUtils::get_studded_leather_armor();
        } else if (id == ItemId::HardLeatherArmor) {
            return ItemUtils::get_hard_leather_armor();
        } else if (id == ItemId::LeatherArmor) {
            return ItemUtils::get_leather_armor();
        } else if (id == ItemId::DemonCrown) {
            return ItemUtils::get_demon_crown();
        } else if (id == ItemId::DragonsCrown) {
            return ItemUtils::get_dragons_crown();
        } else if (id == ItemId::WarCap) {
            return ItemUtils::get_war_cap();
        } else if (id == ItemId::LeatherCap) {
            return ItemUtils::get_leather_cap();
        } else if (id == ItemId::Cap) {
            return ItemUtils::get_cap();
        } else if (id == ItemId::DemonhideBelt) {
            return ItemUtils::get_demonhide_belt();
        } else if (id == ItemId::DragonskinBelt) {
            return ItemUtils::get_dragonskin_belt();
        } else if (id == ItemId::StuddedLeatherBelt) {
            return ItemUtils::get_studded_leather_belt();
        } else if (id == ItemId::HardLeatherBelt) {
            return ItemUtils::get_hard_leather_belt();
        } else if (id == ItemId::LeatherBelt) {
            return ItemUtils::get_leather_belt();
        } else if (id == ItemId::DemonhideBoots) {
            return ItemUtils::get_demonhide_boots();
        } else if (id == ItemId::DragonskinBoots) {
            return ItemUtils::get_dragonskin_boots();
        } else if (id == ItemId::StuddedLeatherBoots) {
            return ItemUtils::get_studded_leather_boots();
        } else if (id == ItemId::HardLeatherBoots) {
            return ItemUtils::get_hard_leather_boots();
        } else if (id == ItemId::LeatherBoots) {
            return ItemUtils::get_leather_boots();
        } else if (id == ItemId::DemonsHands) {
            return ItemUtils::get_demons_hands();
        } else if (id == ItemId::DragonskinGloves) {
            return ItemUtils::get_dragonskin_gloves();
        } else if (id == ItemId::StuddedLeatherGloves) {
            return ItemUtils::get_studded_leather_gloves();
        } else if (id == ItemId::HardLeatherGloves) {
            return ItemUtils::get_hard_leather_gloves();
        } else if (id == ItemId::LeatherGloves) {
            return ItemUtils::get_leather_gloves();
        } else if (id == ItemId::Warhammer) {
            return ItemUtils::get_warhammer();
        } else if (id == ItemId::Quarterstaff) {
            return ItemUtils::get_quarterstaff();
        } else if (id == ItemId::Maul) {
            return ItemUtils::get_maul();
        } else if (id == ItemId::Mace) {
            return ItemUtils::get_mace();
        } else if (id == ItemId::Club) {
            return ItemUtils::get_club();
        } else if (id == ItemId::HolyChestplate) {
            return ItemUtils::get_holy_chestplate();
        } else if (id == ItemId::OrnateChestplate) {
            return ItemUtils::get_ornate_chestplate();
        } else if (id == ItemId::PlateMail) {
            return ItemUtils::get_plate_mail();
        } else if (id == ItemId::ChainMail) {
            return ItemUtils::get_chain_mail();
        } else if (id == ItemId::RingMail) {
            return ItemUtils::get_ring_mail();
        } else if (id == ItemId::AncientHelm) {
            return ItemUtils::get_ancient_helm();
        } else if (id == ItemId::OrnateHelm) {
            return ItemUtils::get_ornate_helm();
        } else if (id == ItemId::GreatHelm) {
            return ItemUtils::get_great_helm();
        } else if (id == ItemId::FullHelm) {
            return ItemUtils::get_full_helm();
        } else if (id == ItemId::Helm) {
            return ItemUtils::get_helm();
        } else if (id == ItemId::OrnateBelt) {
            return ItemUtils::get_ornate_belt();
        } else if (id == ItemId::WarBelt) {
            return ItemUtils::get_war_belt();
        } else if (id == ItemId::PlatedBelt) {
            return ItemUtils::get_plated_belt();
        } else if (id == ItemId::MeshBelt) {
            return ItemUtils::get_mesh_belt();
        } else if (id == ItemId::HeavyBelt) {
            return ItemUtils::get_heavy_belt();
        } else if (id == ItemId::HolyGreaves) {
            return ItemUtils::get_holy_greaves();
        } else if (id == ItemId::OrnateGreaves) {
            return ItemUtils::get_ornate_greaves();
        } else if (id == ItemId::Greaves) {
            return ItemUtils::get_greaves();
        } else if (id == ItemId::ChainBoots) {
            return ItemUtils::get_chain_boots();
        } else if (id == ItemId::HeavyBoots) {
            return ItemUtils::get_heavy_boots();
        } else if (id == ItemId::HolyGauntlets) {
            return ItemUtils::get_holy_gauntlets();
        } else if (id == ItemId::OrnateGauntlets) {
            return ItemUtils::get_ornate_gauntlets();
        } else if (id == ItemId::Gauntlets) {
            return ItemUtils::get_gauntlets();
        } else if (id == ItemId::ChainGloves) {
            return ItemUtils::get_chain_gloves();
        } else if (id == ItemId::HeavyGloves) {
            return ItemUtils::get_heavy_gloves();
        } else {
            return ItemUtils::get_blank_item();
        }
    }

    // @notice gets the type of a Loot item
    // @param id the id of the Loot item to get type for
    // @return Type the type of the Loot item
    fn get_type(id: u8) -> Type {
        if ItemUtils::is_necklace(id) {
            return Type::Necklace(());
        } else if ItemUtils::is_ring(id) {
            return Type::Ring(());
        } else if ItemUtils::is_magic_or_cloth(id) {
            return Type::Magic_or_Cloth(());
        } else if ItemUtils::is_blade_or_hide(id) {
            return Type::Blade_or_Hide(());
        } else if ItemUtils::is_bludgeon_or_metal(id) {
            return Type::Bludgeon_or_Metal(());
        } else {
            return Type::None(());
        }
    }

    // @notice gets the tier of an item.
    // @param id The item id.
    // @return The tier of the item.
    fn get_tier(id: u8) -> Tier {
        if id == ItemId::Pendant {
            return ItemUtils::get_pendant().tier;
        } else if id == ItemId::Necklace {
            return ItemUtils::get_necklace().tier;
        } else if id == ItemId::Amulet {
            return ItemUtils::get_amulet().tier;
        } else if id == ItemId::GoldRing {
            return ItemUtils::get_gold_ring().tier;
        } else if id == ItemId::SilverRing {
            return ItemUtils::get_silver_ring().tier;
        } else if id == ItemId::BronzeRing {
            return ItemUtils::get_bronze_ring().tier;
        } else if id == ItemId::PlatinumRing {
            return ItemUtils::get_platinum_ring().tier;
        } else if id == ItemId::TitaniumRing {
            return ItemUtils::get_titanium_ring().tier;
        } else if id == ItemId::GhostWand {
            return ItemUtils::get_ghost_wand().tier;
        } else if id == ItemId::GraveWand {
            return ItemUtils::get_grave_wand().tier;
        } else if id == ItemId::BoneWand {
            return ItemUtils::get_bone_wand().tier;
        } else if id == ItemId::Wand {
            return ItemUtils::get_wand().tier;
        } else if id == ItemId::Grimoire {
            return ItemUtils::get_grimoire().tier;
        } else if id == ItemId::Chronicle {
            return ItemUtils::get_chronicle().tier;
        } else if id == ItemId::Tome {
            return ItemUtils::get_tome().tier;
        } else if id == ItemId::Book {
            return ItemUtils::get_book().tier;
        } else if id == ItemId::DivineRobe {
            return ItemUtils::get_divine_robe().tier;
        } else if id == ItemId::SilkRobe {
            return ItemUtils::get_silk_robe().tier;
        } else if id == ItemId::LinenRobe {
            return ItemUtils::get_linen_robe().tier;
        } else if id == ItemId::Robe {
            return ItemUtils::get_robe().tier;
        } else if id == ItemId::Shirt {
            return ItemUtils::get_shirt().tier;
        } else if id == ItemId::Crown {
            return ItemUtils::get_crown().tier;
        } else if id == ItemId::DivineHood {
            return ItemUtils::get_divine_hood().tier;
        } else if id == ItemId::SilkHood {
            return ItemUtils::get_silk_hood().tier;
        } else if id == ItemId::LinenHood {
            return ItemUtils::get_linen_hood().tier;
        } else if id == ItemId::Hood {
            return ItemUtils::get_hood().tier;
        } else if id == ItemId::BrightsilkSash {
            return ItemUtils::get_brightsilk_sash().tier;
        } else if id == ItemId::SilkSash {
            return ItemUtils::get_silk_sash().tier;
        } else if id == ItemId::WoolSash {
            return ItemUtils::get_wool_sash().tier;
        } else if id == ItemId::LinenSash {
            return ItemUtils::get_linen_sash().tier;
        } else if id == ItemId::Sash {
            return ItemUtils::get_sash().tier;
        } else if id == ItemId::DivineSlippers {
            return ItemUtils::get_divine_slippers().tier;
        } else if id == ItemId::SilkSlippers {
            return ItemUtils::get_silk_slippers().tier;
        } else if id == ItemId::WoolShoes {
            return ItemUtils::get_wool_shoes().tier;
        } else if id == ItemId::LinenShoes {
            return ItemUtils::get_linen_shoes().tier;
        } else if id == ItemId::Shoes {
            return ItemUtils::get_shoes().tier;
        } else if id == ItemId::DivineGloves {
            return ItemUtils::get_divine_gloves().tier;
        } else if id == ItemId::SilkGloves {
            return ItemUtils::get_silk_gloves().tier;
        } else if id == ItemId::WoolGloves {
            return ItemUtils::get_wool_gloves().tier;
        } else if id == ItemId::LinenGloves {
            return ItemUtils::get_linen_gloves().tier;
        } else if id == ItemId::Gloves {
            return ItemUtils::get_gloves().tier;
        } else if id == ItemId::Katana {
            return ItemUtils::get_katana().tier;
        } else if id == ItemId::Falchion {
            return ItemUtils::get_falchion().tier;
        } else if id == ItemId::Scimitar {
            return ItemUtils::get_scimitar().tier;
        } else if id == ItemId::LongSword {
            return ItemUtils::get_long_sword().tier;
        } else if id == ItemId::ShortSword {
            return ItemUtils::get_short_sword().tier;
        } else if id == ItemId::DemonHusk {
            return ItemUtils::get_demon_husk().tier;
        } else if id == ItemId::DragonskinArmor {
            return ItemUtils::get_dragonskin_armor().tier;
        } else if id == ItemId::StuddedLeatherArmor {
            return ItemUtils::get_studded_leather_armor().tier;
        } else if id == ItemId::HardLeatherArmor {
            return ItemUtils::get_hard_leather_armor().tier;
        } else if id == ItemId::LeatherArmor {
            return ItemUtils::get_leather_armor().tier;
        } else if id == ItemId::DemonCrown {
            return ItemUtils::get_demon_crown().tier;
        } else if id == ItemId::DragonsCrown {
            return ItemUtils::get_dragons_crown().tier;
        } else if id == ItemId::WarCap {
            return ItemUtils::get_war_cap().tier;
        } else if id == ItemId::LeatherCap {
            return ItemUtils::get_leather_cap().tier;
        } else if id == ItemId::Cap {
            return ItemUtils::get_cap().tier;
        } else if id == ItemId::DemonhideBelt {
            return ItemUtils::get_demonhide_belt().tier;
        } else if id == ItemId::DragonskinBelt {
            return ItemUtils::get_dragonskin_belt().tier;
        } else if id == ItemId::StuddedLeatherBelt {
            return ItemUtils::get_studded_leather_belt().tier;
        } else if id == ItemId::HardLeatherBelt {
            return ItemUtils::get_hard_leather_belt().tier;
        } else if id == ItemId::LeatherBelt {
            return ItemUtils::get_leather_belt().tier;
        } else if id == ItemId::DemonhideBoots {
            return ItemUtils::get_demonhide_boots().tier;
        } else if id == ItemId::DragonskinBoots {
            return ItemUtils::get_dragonskin_boots().tier;
        } else if id == ItemId::StuddedLeatherBoots {
            return ItemUtils::get_studded_leather_boots().tier;
        } else if id == ItemId::HardLeatherBoots {
            return ItemUtils::get_hard_leather_boots().tier;
        } else if id == ItemId::LeatherBoots {
            return ItemUtils::get_leather_boots().tier;
        } else if id == ItemId::DemonsHands {
            return ItemUtils::get_demons_hands().tier;
        } else if id == ItemId::DragonskinGloves {
            return ItemUtils::get_dragonskin_gloves().tier;
        } else if id == ItemId::StuddedLeatherGloves {
            return ItemUtils::get_studded_leather_gloves().tier;
        } else if id == ItemId::HardLeatherGloves {
            return ItemUtils::get_hard_leather_gloves().tier;
        } else if id == ItemId::LeatherGloves {
            return ItemUtils::get_leather_gloves().tier;
        } else if id == ItemId::Warhammer {
            return ItemUtils::get_warhammer().tier;
        } else if id == ItemId::Quarterstaff {
            return ItemUtils::get_quarterstaff().tier;
        } else if id == ItemId::Maul {
            return ItemUtils::get_maul().tier;
        } else if id == ItemId::Mace {
            return ItemUtils::get_mace().tier;
        } else if id == ItemId::Club {
            return ItemUtils::get_club().tier;
        } else if id == ItemId::HolyChestplate {
            return ItemUtils::get_holy_chestplate().tier;
        } else if id == ItemId::OrnateChestplate {
            return ItemUtils::get_ornate_chestplate().tier;
        } else if id == ItemId::PlateMail {
            return ItemUtils::get_plate_mail().tier;
        } else if id == ItemId::ChainMail {
            return ItemUtils::get_chain_mail().tier;
        } else if id == ItemId::RingMail {
            return ItemUtils::get_ring_mail().tier;
        } else if id == ItemId::AncientHelm {
            return ItemUtils::get_ancient_helm().tier;
        } else if id == ItemId::OrnateHelm {
            return ItemUtils::get_ornate_helm().tier;
        } else if id == ItemId::GreatHelm {
            return ItemUtils::get_great_helm().tier;
        } else if id == ItemId::FullHelm {
            return ItemUtils::get_full_helm().tier;
        } else if id == ItemId::Helm {
            return ItemUtils::get_helm().tier;
        } else if id == ItemId::OrnateBelt {
            return ItemUtils::get_ornate_belt().tier;
        } else if id == ItemId::WarBelt {
            return ItemUtils::get_war_belt().tier;
        } else if id == ItemId::PlatedBelt {
            return ItemUtils::get_plated_belt().tier;
        } else if id == ItemId::MeshBelt {
            return ItemUtils::get_mesh_belt().tier;
        } else if id == ItemId::HeavyBelt {
            return ItemUtils::get_heavy_belt().tier;
        } else if id == ItemId::HolyGreaves {
            return ItemUtils::get_holy_greaves().tier;
        } else if id == ItemId::OrnateGreaves {
            return ItemUtils::get_ornate_greaves().tier;
        } else if id == ItemId::Greaves {
            return ItemUtils::get_greaves().tier;
        } else if id == ItemId::ChainBoots {
            return ItemUtils::get_chain_boots().tier;
        } else if id == ItemId::HeavyBoots {
            return ItemUtils::get_heavy_boots().tier;
        } else if id == ItemId::HolyGauntlets {
            return ItemUtils::get_holy_gauntlets().tier;
        } else if id == ItemId::OrnateGauntlets {
            return ItemUtils::get_ornate_gauntlets().tier;
        } else if id == ItemId::Gauntlets {
            return ItemUtils::get_gauntlets().tier;
        } else if id == ItemId::ChainGloves {
            return ItemUtils::get_chain_gloves().tier;
        } else if id == ItemId::HeavyGloves {
            return ItemUtils::get_heavy_gloves().tier;
        } else {
            return Tier::None(());
        }
    }

    // @notice gets the slot for a Loot item
    // @param id the id of the Loot item to get slot for
    // @return Slot the slot of the Loot item
    fn get_slot(id: u8) -> Slot {
        if id == ItemId::Pendant {
            return ItemUtils::get_pendant().slot;
        } else if id == ItemId::Necklace {
            return ItemUtils::get_necklace().slot;
        } else if id == ItemId::Amulet {
            return ItemUtils::get_amulet().slot;
        } else if id == ItemId::GoldRing {
            return ItemUtils::get_gold_ring().slot;
        } else if id == ItemId::SilverRing {
            return ItemUtils::get_silver_ring().slot;
        } else if id == ItemId::BronzeRing {
            return ItemUtils::get_bronze_ring().slot;
        } else if id == ItemId::PlatinumRing {
            return ItemUtils::get_platinum_ring().slot;
        } else if id == ItemId::TitaniumRing {
            return ItemUtils::get_titanium_ring().slot;
        } else if id == ItemId::GhostWand {
            return ItemUtils::get_ghost_wand().slot;
        } else if id == ItemId::GraveWand {
            return ItemUtils::get_grave_wand().slot;
        } else if id == ItemId::BoneWand {
            return ItemUtils::get_bone_wand().slot;
        } else if id == ItemId::Wand {
            return ItemUtils::get_wand().slot;
        } else if id == ItemId::Grimoire {
            return ItemUtils::get_grimoire().slot;
        } else if id == ItemId::Chronicle {
            return ItemUtils::get_chronicle().slot;
        } else if id == ItemId::Tome {
            return ItemUtils::get_tome().slot;
        } else if id == ItemId::Book {
            return ItemUtils::get_book().slot;
        } else if id == ItemId::DivineRobe {
            return ItemUtils::get_divine_robe().slot;
        } else if id == ItemId::SilkRobe {
            return ItemUtils::get_silk_robe().slot;
        } else if id == ItemId::LinenRobe {
            return ItemUtils::get_linen_robe().slot;
        } else if id == ItemId::Robe {
            return ItemUtils::get_robe().slot;
        } else if id == ItemId::Shirt {
            return ItemUtils::get_shirt().slot;
        } else if id == ItemId::Crown {
            return ItemUtils::get_crown().slot;
        } else if id == ItemId::DivineHood {
            return ItemUtils::get_divine_hood().slot;
        } else if id == ItemId::SilkHood {
            return ItemUtils::get_silk_hood().slot;
        } else if id == ItemId::LinenHood {
            return ItemUtils::get_linen_hood().slot;
        } else if id == ItemId::Hood {
            return ItemUtils::get_hood().slot;
        } else if id == ItemId::BrightsilkSash {
            return ItemUtils::get_brightsilk_sash().slot;
        } else if id == ItemId::SilkSash {
            return ItemUtils::get_silk_sash().slot;
        } else if id == ItemId::WoolSash {
            return ItemUtils::get_wool_sash().slot;
        } else if id == ItemId::LinenSash {
            return ItemUtils::get_linen_sash().slot;
        } else if id == ItemId::Sash {
            return ItemUtils::get_sash().slot;
        } else if id == ItemId::DivineSlippers {
            return ItemUtils::get_divine_slippers().slot;
        } else if id == ItemId::SilkSlippers {
            return ItemUtils::get_silk_slippers().slot;
        } else if id == ItemId::WoolShoes {
            return ItemUtils::get_wool_shoes().slot;
        } else if id == ItemId::LinenShoes {
            return ItemUtils::get_linen_shoes().slot;
        } else if id == ItemId::Shoes {
            return ItemUtils::get_shoes().slot;
        } else if id == ItemId::DivineGloves {
            return ItemUtils::get_divine_gloves().slot;
        } else if id == ItemId::SilkGloves {
            return ItemUtils::get_silk_gloves().slot;
        } else if id == ItemId::WoolGloves {
            return ItemUtils::get_wool_gloves().slot;
        } else if id == ItemId::LinenGloves {
            return ItemUtils::get_linen_gloves().slot;
        } else if id == ItemId::Gloves {
            return ItemUtils::get_gloves().slot;
        } else if id == ItemId::Katana {
            return ItemUtils::get_katana().slot;
        } else if id == ItemId::Falchion {
            return ItemUtils::get_falchion().slot;
        } else if id == ItemId::Scimitar {
            return ItemUtils::get_scimitar().slot;
        } else if id == ItemId::LongSword {
            return ItemUtils::get_long_sword().slot;
        } else if id == ItemId::ShortSword {
            return ItemUtils::get_short_sword().slot;
        } else if id == ItemId::DemonHusk {
            return ItemUtils::get_demon_husk().slot;
        } else if id == ItemId::DragonskinArmor {
            return ItemUtils::get_dragonskin_armor().slot;
        } else if id == ItemId::StuddedLeatherArmor {
            return ItemUtils::get_studded_leather_armor().slot;
        } else if id == ItemId::HardLeatherArmor {
            return ItemUtils::get_hard_leather_armor().slot;
        } else if id == ItemId::LeatherArmor {
            return ItemUtils::get_leather_armor().slot;
        } else if id == ItemId::DemonCrown {
            return ItemUtils::get_demon_crown().slot;
        } else if id == ItemId::DragonsCrown {
            return ItemUtils::get_dragons_crown().slot;
        } else if id == ItemId::WarCap {
            return ItemUtils::get_war_cap().slot;
        } else if id == ItemId::LeatherCap {
            return ItemUtils::get_leather_cap().slot;
        } else if id == ItemId::Cap {
            return ItemUtils::get_cap().slot;
        } else if id == ItemId::DemonhideBelt {
            return ItemUtils::get_demonhide_belt().slot;
        } else if id == ItemId::DragonskinBelt {
            return ItemUtils::get_dragonskin_belt().slot;
        } else if id == ItemId::StuddedLeatherBelt {
            return ItemUtils::get_studded_leather_belt().slot;
        } else if id == ItemId::HardLeatherBelt {
            return ItemUtils::get_hard_leather_belt().slot;
        } else if id == ItemId::LeatherBelt {
            return ItemUtils::get_leather_belt().slot;
        } else if id == ItemId::DemonhideBoots {
            return ItemUtils::get_demonhide_boots().slot;
        } else if id == ItemId::DragonskinBoots {
            return ItemUtils::get_dragonskin_boots().slot;
        } else if id == ItemId::StuddedLeatherBoots {
            return ItemUtils::get_studded_leather_boots().slot;
        } else if id == ItemId::HardLeatherBoots {
            return ItemUtils::get_hard_leather_boots().slot;
        } else if id == ItemId::LeatherBoots {
            return ItemUtils::get_leather_boots().slot;
        } else if id == ItemId::DemonsHands {
            return ItemUtils::get_demons_hands().slot;
        } else if id == ItemId::DragonskinGloves {
            return ItemUtils::get_dragonskin_gloves().slot;
        } else if id == ItemId::StuddedLeatherGloves {
            return ItemUtils::get_studded_leather_gloves().slot;
        } else if id == ItemId::HardLeatherGloves {
            return ItemUtils::get_hard_leather_gloves().slot;
        } else if id == ItemId::LeatherGloves {
            return ItemUtils::get_leather_gloves().slot;
        } else if id == ItemId::Warhammer {
            return ItemUtils::get_warhammer().slot;
        } else if id == ItemId::Quarterstaff {
            return ItemUtils::get_quarterstaff().slot;
        } else if id == ItemId::Maul {
            return ItemUtils::get_maul().slot;
        } else if id == ItemId::Mace {
            return ItemUtils::get_mace().slot;
        } else if id == ItemId::Club {
            return ItemUtils::get_club().slot;
        } else if id == ItemId::HolyChestplate {
            return ItemUtils::get_holy_chestplate().slot;
        } else if id == ItemId::OrnateChestplate {
            return ItemUtils::get_ornate_chestplate().slot;
        } else if id == ItemId::PlateMail {
            return ItemUtils::get_plate_mail().slot;
        } else if id == ItemId::ChainMail {
            return ItemUtils::get_chain_mail().slot;
        } else if id == ItemId::RingMail {
            return ItemUtils::get_ring_mail().slot;
        } else if id == ItemId::AncientHelm {
            return ItemUtils::get_ancient_helm().slot;
        } else if id == ItemId::OrnateHelm {
            return ItemUtils::get_ornate_helm().slot;
        } else if id == ItemId::GreatHelm {
            return ItemUtils::get_great_helm().slot;
        } else if id == ItemId::FullHelm {
            return ItemUtils::get_full_helm().slot;
        } else if id == ItemId::Helm {
            return ItemUtils::get_helm().slot;
        } else if id == ItemId::OrnateBelt {
            return ItemUtils::get_ornate_belt().slot;
        } else if id == ItemId::WarBelt {
            return ItemUtils::get_war_belt().slot;
        } else if id == ItemId::PlatedBelt {
            return ItemUtils::get_plated_belt().slot;
        } else if id == ItemId::MeshBelt {
            return ItemUtils::get_mesh_belt().slot;
        } else if id == ItemId::HeavyBelt {
            return ItemUtils::get_heavy_belt().slot;
        } else if id == ItemId::HolyGreaves {
            return ItemUtils::get_holy_greaves().slot;
        } else if id == ItemId::OrnateGreaves {
            return ItemUtils::get_ornate_greaves().slot;
        } else if id == ItemId::Greaves {
            return ItemUtils::get_greaves().slot;
        } else if id == ItemId::ChainBoots {
            return ItemUtils::get_chain_boots().slot;
        } else if id == ItemId::HeavyBoots {
            return ItemUtils::get_heavy_boots().slot;
        } else if id == ItemId::HolyGauntlets {
            return ItemUtils::get_holy_gauntlets().slot;
        } else if id == ItemId::OrnateGauntlets {
            return ItemUtils::get_ornate_gauntlets().slot;
        } else if id == ItemId::Gauntlets {
            return ItemUtils::get_gauntlets().slot;
        } else if id == ItemId::ChainGloves {
            return ItemUtils::get_chain_gloves().slot;
        } else if id == ItemId::HeavyGloves {
            return ItemUtils::get_heavy_gloves().slot;
        } else {
            return Slot::None(());
        }
    }

    // @notice gets the number of Loot items for a given slot
    // @param slot the slot to get number of items for
    // @return u8 the number of items for the given slot 
    fn get_slot_length(slot: Slot) -> u8 {
        match slot {
            Slot::None(()) => 0,
            Slot::Weapon(()) => ItemSlotLength::SlotItemsLengthWeapon,
            Slot::Chest(()) => ItemSlotLength::SlotItemsLengthChest,
            Slot::Head(()) => ItemSlotLength::SlotItemsLengthHead,
            Slot::Waist(()) => ItemSlotLength::SlotItemsLengthWaist,
            Slot::Foot(()) => ItemSlotLength::SlotItemsLengthFoot,
            Slot::Hand(()) => ItemSlotLength::SlotItemsLengthHand,
            Slot::Neck(()) => ItemSlotLength::SlotItemsLengthHand,
            Slot::Ring(()) => ItemSlotLength::SlotItemsLengthRing,
        }
    }

    // @notice gets the index of a Loot item 
    // @dev the index is the items position in its repsective grouping {weapon, chest_armor, etc}
    // @param id of the item to get the index for
    // @return u8 the index of the item
    fn get_item_index(id: u8) -> u8 {
        if id == ItemId::Pendant {
            return ItemIndex::Pendant;
        } else if id == ItemId::Necklace {
            return ItemIndex::Necklace;
        } else if id == ItemId::Amulet {
            return ItemIndex::Amulet;
        } else if id == ItemId::SilverRing {
            return ItemIndex::SilverRing;
        } else if id == ItemId::BronzeRing {
            return ItemIndex::BronzeRing;
        } else if id == ItemId::PlatinumRing {
            return ItemIndex::PlatinumRing;
        } else if id == ItemId::TitaniumRing {
            return ItemIndex::TitaniumRing;
        } else if id == ItemId::GoldRing {
            return ItemIndex::GoldRing;
        } else if id == ItemId::GhostWand {
            return ItemIndex::GhostWand;
        } else if id == ItemId::GraveWand {
            return ItemIndex::GraveWand;
        } else if id == ItemId::BoneWand {
            return ItemIndex::BoneWand;
        } else if id == ItemId::Wand {
            return ItemIndex::Wand;
        } else if id == ItemId::Grimoire {
            return ItemIndex::Grimoire;
        } else if id == ItemId::Chronicle {
            return ItemIndex::Chronicle;
        } else if id == ItemId::Tome {
            return ItemIndex::Tome;
        } else if id == ItemId::Book {
            return ItemIndex::Book;
        } else if id == ItemId::DivineRobe {
            return ItemIndex::DivineRobe;
        } else if id == ItemId::SilkRobe {
            return ItemIndex::SilkRobe;
        } else if id == ItemId::LinenRobe {
            return ItemIndex::LinenRobe;
        } else if id == ItemId::Robe {
            return ItemIndex::Robe;
        } else if id == ItemId::Shirt {
            return ItemIndex::Shirt;
        } else if id == ItemId::Crown {
            return ItemIndex::Crown;
        } else if id == ItemId::DivineHood {
            return ItemIndex::DivineHood;
        } else if id == ItemId::SilkHood {
            return ItemIndex::SilkHood;
        } else if id == ItemId::LinenHood {
            return ItemIndex::LinenHood;
        } else if id == ItemId::Hood {
            return ItemIndex::Hood;
        } else if id == ItemId::BrightsilkSash {
            return ItemIndex::BrightsilkSash;
        } else if id == ItemId::SilkSash {
            return ItemIndex::SilkSash;
        } else if id == ItemId::WoolSash {
            return ItemIndex::WoolSash;
        } else if id == ItemId::LinenSash {
            return ItemIndex::LinenSash;
        } else if id == ItemId::Sash {
            return ItemIndex::Sash;
        } else if id == ItemId::DivineSlippers {
            return ItemIndex::DivineSlippers;
        } else if id == ItemId::SilkSlippers {
            return ItemIndex::SilkSlippers;
        } else if id == ItemId::WoolShoes {
            return ItemIndex::WoolShoes;
        } else if id == ItemId::LinenShoes {
            return ItemIndex::LinenShoes;
        } else if id == ItemId::Shoes {
            return ItemIndex::Shoes;
        } else if id == ItemId::DivineGloves {
            return ItemIndex::DivineGloves;
        } else if id == ItemId::SilkGloves {
            return ItemIndex::SilkGloves;
        } else if id == ItemId::WoolGloves {
            return ItemIndex::WoolGloves;
        } else if id == ItemId::LinenGloves {
            return ItemIndex::LinenGloves;
        } else if id == ItemId::Gloves {
            return ItemIndex::Gloves;
        } else if id == ItemId::Katana {
            return ItemIndex::Katana;
        } else if id == ItemId::Falchion {
            return ItemIndex::Falchion;
        } else if id == ItemId::Scimitar {
            return ItemIndex::Scimitar;
        } else if id == ItemId::LongSword {
            return ItemIndex::LongSword;
        } else if id == ItemId::ShortSword {
            return ItemIndex::ShortSword;
        } else if id == ItemId::DemonHusk {
            return ItemIndex::DemonHusk;
        } else if id == ItemId::DragonskinArmor {
            return ItemIndex::DragonskinArmor;
        } else if id == ItemId::StuddedLeatherArmor {
            return ItemIndex::StuddedLeatherArmor;
        } else if id == ItemId::HardLeatherArmor {
            return ItemIndex::HardLeatherArmor;
        } else if id == ItemId::LeatherArmor {
            return ItemIndex::LeatherArmor;
        } else if id == ItemId::DemonCrown {
            return ItemIndex::DemonCrown;
        } else if id == ItemId::DragonsCrown {
            return ItemIndex::DragonsCrown;
        } else if id == ItemId::WarCap {
            return ItemIndex::WarCap;
        } else if id == ItemId::LeatherCap {
            return ItemIndex::LeatherCap;
        } else if id == ItemId::Cap {
            return ItemIndex::Cap;
        } else if id == ItemId::DemonhideBelt {
            return ItemIndex::DemonhideBelt;
        } else if id == ItemId::DragonskinBelt {
            return ItemIndex::DragonskinBelt;
        } else if id == ItemId::StuddedLeatherBelt {
            return ItemIndex::StuddedLeatherBelt;
        } else if id == ItemId::HardLeatherBelt {
            return ItemIndex::HardLeatherBelt;
        } else if id == ItemId::LeatherBelt {
            return ItemIndex::LeatherBelt;
        } else if id == ItemId::DemonhideBoots {
            return ItemIndex::DemonhideBoots;
        } else if id == ItemId::DragonskinBoots {
            return ItemIndex::DragonskinBoots;
        } else if id == ItemId::StuddedLeatherBoots {
            return ItemIndex::StuddedLeatherBoots;
        } else if id == ItemId::HardLeatherBoots {
            return ItemIndex::HardLeatherBoots;
        } else if id == ItemId::LeatherBoots {
            return ItemIndex::LeatherBoots;
        } else if id == ItemId::DemonsHands {
            return ItemIndex::DemonsHands;
        } else if id == ItemId::DragonskinGloves {
            return ItemIndex::DragonskinGloves;
        } else if id == ItemId::StuddedLeatherGloves {
            return ItemIndex::StuddedLeatherGloves;
        } else if id == ItemId::HardLeatherGloves {
            return ItemIndex::HardLeatherGloves;
        } else if id == ItemId::LeatherGloves {
            return ItemIndex::LeatherGloves;
        } else if id == ItemId::Warhammer {
            return ItemIndex::Warhammer;
        } else if id == ItemId::Quarterstaff {
            return ItemIndex::Quarterstaff;
        } else if id == ItemId::Maul {
            return ItemIndex::Maul;
        } else if id == ItemId::Mace {
            return ItemIndex::Mace;
        } else if id == ItemId::Club {
            return ItemIndex::Club;
        } else if id == ItemId::HolyChestplate {
            return ItemIndex::HolyChestplate;
        } else if id == ItemId::OrnateChestplate {
            return ItemIndex::OrnateChestplate;
        } else if id == ItemId::PlateMail {
            return ItemIndex::PlateMail;
        } else if id == ItemId::ChainMail {
            return ItemIndex::ChainMail;
        } else if id == ItemId::RingMail {
            return ItemIndex::RingMail;
        } else if id == ItemId::AncientHelm {
            return ItemIndex::AncientHelm;
        } else if id == ItemId::OrnateHelm {
            return ItemIndex::OrnateHelm;
        } else if id == ItemId::GreatHelm {
            return ItemIndex::GreatHelm;
        } else if id == ItemId::FullHelm {
            return ItemIndex::FullHelm;
        } else if id == ItemId::Helm {
            return ItemIndex::Helm;
        } else if id == ItemId::OrnateBelt {
            return ItemIndex::OrnateBelt;
        } else if id == ItemId::WarBelt {
            return ItemIndex::WarBelt;
        } else if id == ItemId::PlatedBelt {
            return ItemIndex::PlatedBelt;
        } else if id == ItemId::MeshBelt {
            return ItemIndex::MeshBelt;
        } else if id == ItemId::HeavyBelt {
            return ItemIndex::HeavyBelt;
        } else if id == ItemId::HolyGreaves {
            return ItemIndex::HolyGreaves;
        } else if id == ItemId::OrnateGreaves {
            return ItemIndex::OrnateGreaves;
        } else if id == ItemId::Greaves {
            return ItemIndex::Greaves;
        } else if id == ItemId::ChainBoots {
            return ItemIndex::ChainBoots;
        } else if id == ItemId::HeavyBoots {
            return ItemIndex::HeavyBoots;
        } else if id == ItemId::HolyGauntlets {
            return ItemIndex::HolyGauntlets;
        } else if id == ItemId::OrnateGauntlets {
            return ItemIndex::OrnateGauntlets;
        } else if id == ItemId::Gauntlets {
            return ItemIndex::Gauntlets;
        } else if id == ItemId::ChainGloves {
            return ItemIndex::ChainGloves;
        } else if id == ItemId::HeavyGloves {
            return ItemIndex::HeavyGloves;
        } else {
            panic_with_felt252('invalid item')
        }
    }

    // is_starting_weapon returns true if the item is a starting weapon.
    // Starting weapons are: {Wand, Book, Club, ShortSword}
    // @param id The item id.
    // @return True if the item is a starting weapon.
    fn is_starting_weapon(id: u8) -> bool {
        if (id == ItemId::Wand
            || id == ItemId::Book
            || id == ItemId::Club
            || id == ItemId::ShortSword) {
            true
        } else {
            false
        }
    }
}
const TWO_POW_8: u256 = 0x100;
const TWO_POW_16: u256 = 0x10000;
const TWO_POW_24: u256 = 0x1000000;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use traits::{TryInto, Into};
    use option::OptionTrait;
    use core::{serde::Serde, clone::Clone};

    use combat::{combat::ImplCombat, constants::CombatEnums::{Type, Tier, Slot}};
    use lootitems::{
        loot::{ImplLoot, ILoot, LootPacking, Loot},
        constants::{
            NamePrefixLength, ItemNameSuffix, ItemId, ItemNamePrefix, NameSuffixLength,
            ItemSuffixLength, ItemSuffix, NUM_ITEMS,
        },
        utils::{
            NameUtils::{
                is_special3_set1, is_special3_set2, is_special3_set3, is_special1_set1,
                is_special1_set2, is_special2_set1, is_special2_set2, is_special2_set3
            },
            ItemUtils
        }
    };

    #[test]
    #[available_gas(3975111110)]
    fn test_suffix_assignments() {
        let mut i: u128 = 0;
        loop {
            if i > ItemSuffixLength.into() {
                break ();
            }

            // verify Warhammers are part of set1
            let warhammer_suffix = ImplLoot::get_special1(ItemId::Warhammer, i);
            assert(is_special1_set1(warhammer_suffix), 'invalid warhammer suffix');

            // verify quarterstaffs are part of set2
            let quarterstaff_suffix = ImplLoot::get_special1(ItemId::Quarterstaff, i);
            assert(is_special1_set2(quarterstaff_suffix), 'invalid quarterstaff suffix');

            // verify mauls are part of set1
            let maul_suffix = ImplLoot::get_special1(ItemId::Maul, i);
            assert(is_special1_set1(maul_suffix), 'invalid maul suffix');

            // verify maces are part of set2
            let mace_suffix = ImplLoot::get_special1(ItemId::Mace, i);
            assert(is_special1_set2(mace_suffix), 'invalid mace suffix');

            // verify clubs are part of set2
            let club_suffix = ImplLoot::get_special1(ItemId::Club, i);
            assert(is_special1_set1(club_suffix), 'invalid club suffix');

            // verify katanas are part of set1
            let katana_suffix = ImplLoot::get_special1(ItemId::Katana, i);
            assert(is_special1_set2(katana_suffix), 'invalid katana suffix');

            // verify falchions are part of set2
            let falchion_suffix = ImplLoot::get_special1(ItemId::Falchion, i);
            assert(is_special1_set1(falchion_suffix), 'invalid falchion suffix');

            // verify scimitars are part of set1
            let scimitar_suffix = ImplLoot::get_special1(ItemId::Scimitar, i);
            assert(is_special1_set2(scimitar_suffix), 'invalid scimitar suffix');

            // verify long swords are part of set2
            let long_sword_suffix = ImplLoot::get_special1(ItemId::LongSword, i);
            assert(is_special1_set1(long_sword_suffix), 'invalid long sword suffix');

            // verify short swords are part of set1
            let short_sword_suffix = ImplLoot::get_special1(ItemId::ShortSword, i);
            assert(is_special1_set2(short_sword_suffix), 'invalid short sword suffix');

            // verify ghost wands are part of set2
            let ghost_wand_suffix = ImplLoot::get_special1(ItemId::GhostWand, i);
            assert(is_special1_set1(ghost_wand_suffix), 'invalid ghost wand suffix');

            // verify grave wands are part of set1
            let grave_wand_suffix = ImplLoot::get_special1(ItemId::GraveWand, i);
            assert(is_special1_set2(grave_wand_suffix), 'invalid grave wand suffix');

            // verify bone wands are part of set2
            let bone_wand_suffix = ImplLoot::get_special1(ItemId::BoneWand, i);
            assert(is_special1_set1(bone_wand_suffix), 'invalid bone wand suffix');

            // verify wands are part of set1
            let wand_suffix = ImplLoot::get_special1(ItemId::Wand, i);
            assert(is_special1_set2(wand_suffix), 'invalid wand suffix');

            // verify grimoires are part of set2
            let grimoire_suffix = ImplLoot::get_special1(ItemId::Grimoire, i);
            assert(is_special1_set1(grimoire_suffix), 'invalid grimoire suffix');

            // verify chronicles are part of set1
            let chronicle_suffix = ImplLoot::get_special1(ItemId::Chronicle, i);
            assert(is_special1_set2(chronicle_suffix), 'invalid chronicle suffix');

            // verify tomes are part of set2
            let tome_suffix = ImplLoot::get_special1(ItemId::Tome, i);
            assert(is_special1_set1(tome_suffix), 'invalid tome suffix');

            // verify books are part of set1
            let book_suffix = ImplLoot::get_special1(ItemId::Book, i);
            assert(is_special1_set2(book_suffix), 'invalid book suffix');

            // increment counter
            i += 1;
        };
    }

    #[test]
    #[available_gas(2298200670)]
    fn test_prefix2_assignments() {
        let mut i: u128 = 0;

        loop {
            // test over entire entropy set which is size of name suffix list
            if i > NameSuffixLength.into() {
                break ();
            }

            //
            // Weapons
            //

            // Warhammers are always 'X Bane'
            assert(
                ImplLoot::generate_prefix2(ItemId::Warhammer, i) == ItemNameSuffix::Bane,
                'warhammer should be bane'
            );

            // Quarterstaffs are always 'X Root'
            assert(
                ImplLoot::generate_prefix2(ItemId::Quarterstaff, i) == ItemNameSuffix::Root,
                'quarterstaff should be root'
            );

            // Mauls are always 'X Bite'
            assert(
                ImplLoot::generate_prefix2(ItemId::Maul, i) == ItemNameSuffix::Bite,
                'maul should be bite'
            );

            // Maces are always 'X Song'
            assert(
                ImplLoot::generate_prefix2(ItemId::Mace, i) == ItemNameSuffix::Song,
                'mace should be song'
            );

            // Clubs are always 'X Roar'
            assert(
                ImplLoot::generate_prefix2(ItemId::Club, i) == ItemNameSuffix::Roar,
                'club should be roar'
            );

            // Katanas are always 'X Grasp'
            assert(
                ImplLoot::generate_prefix2(ItemId::Katana, i) == ItemNameSuffix::Grasp,
                'katana should be grasp'
            );

            // Falchions are always 'X Instrument'
            assert(
                ImplLoot::generate_prefix2(ItemId::Falchion, i) == ItemNameSuffix::Instrument,
                'falchion should be instrument'
            );

            // Scimitars are always 'X Glow'
            assert(
                ImplLoot::generate_prefix2(ItemId::Scimitar, i) == ItemNameSuffix::Glow,
                'scimitar should be glow'
            );

            // Long Swords are always 'X Bender'
            assert(
                ImplLoot::generate_prefix2(ItemId::LongSword, i) == ItemNameSuffix::Bender,
                'long sword should be bender'
            );

            // Short Swords are always 'X Shadow'
            assert(
                ImplLoot::generate_prefix2(ItemId::ShortSword, i) == ItemNameSuffix::Shadow,
                'short sword should be shadow'
            );

            // Ghost Wands are always 'X Whisper'
            assert(
                ImplLoot::generate_prefix2(ItemId::GhostWand, i) == ItemNameSuffix::Whisper,
                'ghost wand should be whisper'
            );

            // Grave Wands are always 'X Shout'
            assert(
                ImplLoot::generate_prefix2(ItemId::GraveWand, i) == ItemNameSuffix::Shout,
                'grave wand should be shout'
            );

            // Bone Wands are always 'X Growl'
            assert(
                ImplLoot::generate_prefix2(ItemId::BoneWand, i) == ItemNameSuffix::Growl,
                'bone wand should be growl'
            );

            // Wands are always 'X Tear'
            assert(
                ImplLoot::generate_prefix2(ItemId::Wand, i) == ItemNameSuffix::Tear,
                'wand should be tear'
            );

            // Grimoires are always 'X Peak'
            assert(
                ImplLoot::generate_prefix2(ItemId::Grimoire, i) == ItemNameSuffix::Peak,
                'grimoire should be peak'
            );

            // Chronicles are always 'X Form'
            assert(
                ImplLoot::generate_prefix2(ItemId::Chronicle, i) == ItemNameSuffix::Form,
                'chronicle should be form'
            );

            // Tomes are always 'X Sun'
            assert(
                ImplLoot::generate_prefix2(ItemId::Tome, i) == ItemNameSuffix::Sun,
                'tome should be sun'
            );

            // Books are always 'X Moon'
            assert(
                ImplLoot::generate_prefix2(ItemId::Book, i) == ItemNameSuffix::Moon,
                'book should be moon'
            );

            // Chest Armor
            //
            // Divine Robes are always {X Bane, X Song, X Instrument, X Shadow, X Growl, X Form} (set 1)
            assert(
                is_special3_set1(ImplLoot::generate_prefix2(ItemId::DivineRobe, i)),
                'invalid divine robe name suffix'
            );

            // Chain Mail is always {X Root, X Roar, X Glow, X Whisper, X Tear, X Sun} (set 2)
            assert(
                is_special3_set2(ImplLoot::generate_prefix2(ItemId::ChainMail, i)),
                'invalid chain mail name suffix'
            );

            // Demon Husks are always {X Bite, X Grasp, X Bender, X Shout, X Peak, X Moon} (set 3)
            assert(
                is_special3_set3(ImplLoot::generate_prefix2(ItemId::DemonHusk, i)),
                'invalid demon husk name suffix'
            );
            //

            // Head Armor
            //
            // Ancient Helms use name suffix set 1
            assert(
                is_special3_set1(ImplLoot::generate_prefix2(ItemId::AncientHelm, i)),
                'invalid war cap name suffix'
            );

            // Crown uses name suffix set 2
            assert(
                is_special3_set2(ImplLoot::generate_prefix2(ItemId::Crown, i)),
                'invalid crown name suffix'
            );

            // Divine Hood uses name suffix set 3
            assert(
                is_special3_set3(ImplLoot::generate_prefix2(ItemId::DivineHood, i)),
                'invalid divine hood name suffix'
            );

            //
            // Waist Armor
            //
            // Ornate Belt uses name suffix set 1
            assert(
                is_special3_set1(ImplLoot::generate_prefix2(ItemId::OrnateBelt, i)),
                'invalid ornate belt suffix'
            );

            // Brightsilk Sash uses name suffix set 2
            assert(
                is_special3_set2(ImplLoot::generate_prefix2(ItemId::BrightsilkSash, i)),
                'invalid brightsilk sash suffix'
            );

            // Hard Leather Belt uses name set 3
            assert(
                is_special3_set3(ImplLoot::generate_prefix2(ItemId::HardLeatherBelt, i)),
                'wrong hard leather belt suffix'
            );

            //
            // Foot Armor
            //
            // Holy Graves uses name suffix set 1
            assert(
                is_special3_set1(ImplLoot::generate_prefix2(ItemId::HolyGreaves, i)),
                'invalid holy greaves suffix'
            );

            // Heavy Boots use name suffix set 2
            assert(
                is_special3_set2(ImplLoot::generate_prefix2(ItemId::HeavyBoots, i)),
                'invalid heavy boots suffix'
            );

            // Silk Slippers use name suffix set 3
            assert(
                is_special3_set3(ImplLoot::generate_prefix2(ItemId::SilkSlippers, i)),
                'invalid silk slippers suffix'
            );

            //
            // Hand Armor
            //
            // Holy Gauntlets use name suffix set 1
            assert(
                is_special3_set1(ImplLoot::generate_prefix2(ItemId::HolyGauntlets, i)),
                'invalid holy gauntlets suffix'
            );

            // Linen Gloves use name suffix set 2
            assert(
                is_special3_set2(ImplLoot::generate_prefix2(ItemId::LinenGloves, i)),
                'invalid linen gloves suffix'
            );

            // Hard Leather Gloves use name suffix set 3
            assert(
                is_special3_set3(ImplLoot::generate_prefix2(ItemId::HardLeatherGloves, i)),
                'invalid hard lthr gloves suffix'
            );

            //
            // Necklaces
            //
            // Neckalce uses name suffix set 1
            assert(
                is_special3_set1(ImplLoot::generate_prefix2(ItemId::Necklace, i)),
                'invalid Necklace name suffix'
            );

            // Amulets use name suffix set 2
            assert(
                is_special3_set2(ImplLoot::generate_prefix2(ItemId::Amulet, i)),
                'invalid amulet name suffix'
            );

            // Pendants use name suffix set 3
            assert(
                is_special3_set3(ImplLoot::generate_prefix2(ItemId::Pendant, i)),
                'invalid pendant name suffix'
            );

            //
            // Rings
            //
            // Can have any name so no need to test. Note while the contract doesn't generate any Rings with
            // name prefix set 1  such as "X Bane" Gold Ring of Power, this is because those ring variants
            // haven't yet reached G19 to receive their name. This is simlar to us
            // knowing that all Warhammers will eventually be "X Bane" even though none have reached G19
            // in the present day. The contract is deterministic with the item naming and the name
            // assignment does not depend on the items greatness.

            i += 1;
        };
    }


    #[test]
    #[available_gas(1655011840)]
    fn test_prefix1_assignment() {
        let mut i: u128 = 0;
        loop {
            if i > NamePrefixLength.into() {
                break ();
            }

            // verify warhammer uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::Warhammer, i)),
                'invalid warhammer prefix'
            );

            // verify quarterstaff uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::Quarterstaff, i)),
                'invalid quarterstaff prefix'
            );

            // verify maul uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::Maul, i)),
                'invalid maul prefix'
            );

            // verify mace uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::Mace, i)),
                'invalid mace prefix'
            );

            // verify club uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::Club, i)),
                'invalid club prefix'
            );

            // verify katana uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::Katana, i)),
                'invalid katana prefix'
            );

            // verify falchion uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::Falchion, i)),
                'invalid falchion prefix'
            );

            // verify scimitar uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::Scimitar, i)),
                'invalid scimitar prefix'
            );

            // verify long sword uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::LongSword, i)),
                'invalid long sword prefix'
            );

            // verify short sword uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::ShortSword, i)),
                'invalid short sword prefix'
            );

            // verify ghost wand uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::GhostWand, i)),
                'invalid ghost wand prefix'
            );

            // verify grave wand uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::GraveWand, i)),
                'invalid grave wand prefix'
            );

            // verify bone wand uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::BoneWand, i)),
                'invalid bone wand prefix'
            );

            // verify wand uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::Wand, i)),
                'invalid wand prefix'
            );

            // verify grimoire uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::Grimoire, i)),
                'invalid grimoire prefix'
            );

            // verify chronicle uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::Chronicle, i)),
                'invalid chronicle prefix'
            );

            // verify tome uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::Tome, i)),
                'invalid tome prefix'
            );

            // verify book uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::Book, i)),
                'invalid book prefix'
            );

            // verify divine robe uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::DivineRobe, i)),
                'invalid divine robe prefix'
            );

            // verify silk robe uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::SilkRobe, i)),
                'invalid silk robe prefix'
            );

            // verify linen robe uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::LinenRobe, i)),
                'invalid linen robe prefix'
            );

            // verify robe uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::Robe, i)),
                'invalid robe prefix'
            );

            // verify shirt uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::Shirt, i)),
                'invalid shirt prefix'
            );

            // verify demon husk uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::DemonHusk, i)),
                'invalid demon husk prefix'
            );

            // verify dragonskin armor uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::DragonskinArmor, i)),
                'invalid dragonskin armor prefix'
            );

            // verify studded leather armor uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::StuddedLeatherArmor, i)),
                'invalid studded leather prefix'
            );

            // verify hard leather armor uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::HardLeatherArmor, i)),
                'invalid hard leather prefix'
            );

            // verify leather armor uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::LeatherArmor, i)),
                'invalid leather armor prefix'
            );

            // verify holy chestplate uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::HolyChestplate, i)),
                'invalid holy chestplate prefix'
            );

            // verify ornate chestplate uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::OrnateChestplate, i)),
                'invalid ornte chestplate prefix'
            );

            // verify plate mail uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::PlateMail, i)),
                'invalid plate mail prefix'
            );

            // verify chain mail uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::ChainMail, i)),
                'invalid chain mail prefix'
            );

            // verify ring mail uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::RingMail, i)),
                'invalid ring mail prefix'
            );

            // assert ancient helm uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::AncientHelm, i)),
                'invalid ancient helm prefix'
            );

            // assert ornate helm uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::OrnateHelm, i)),
                'invalid ornate helm prefix'
            );

            // assert great helm uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::GreatHelm, i)),
                'invalid great helm prefix'
            );

            // assert full helm uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::FullHelm, i)),
                'invalid full helm prefix'
            );

            // assert helm uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::Helm, i)),
                'invalid helm prefix'
            );

            // assert demon crown uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::DemonCrown, i)),
                'invalid demon crown prefix'
            );

            // assert dragons crown uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::DragonsCrown, i)),
                'invalid dragons crown prefix'
            );

            // assert war cap uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::WarCap, i)),
                'invalid war cap prefix'
            );

            // assert leather cap uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::LeatherCap, i)),
                'invalid leather cap prefix'
            );

            // assert cap uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::Cap, i)),
                'invalid cap prefix'
            );

            // assert crown uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::Crown, i)),
                'invalid crown prefix'
            );

            // assert divine hood uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::DivineHood, i)),
                'invalid divine hood prefix'
            );

            // assert silk hood uses set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::SilkHood, i)),
                'invalid silk hood prefix'
            );

            // assert linen hood uses set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::LinenHood, i)),
                'invalid linen hood prefix'
            );

            // assert hood uses set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::Hood, i)),
                'invalid hood prefix'
            );

            // assert ornate belt is set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::OrnateBelt, i)),
                'invalid ornate belt prefix'
            );

            // assert war belt is set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::WarBelt, i)),
                'invalid war belt prefix'
            );

            // assert plated belt is set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::PlatedBelt, i)),
                'invalid plated belt prefix'
            );

            // assert mesh belt is set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::MeshBelt, i)),
                'invalid mesh belt prefix'
            );

            // assert heavy belt is set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::HeavyBelt, i)),
                'invalid heavy belt prefix'
            );

            // assert demonhide belt is set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::DemonhideBelt, i)),
                'invalid demonhide belt prefix'
            );

            // assert dragonskin belt is set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::DragonskinBelt, i)),
                'invalid dragonskin belt prefix'
            );

            // assert studded leather belt is set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::StuddedLeatherBelt, i)),
                'invalid studded lthr blt prefix'
            );

            // assert hard leather belt is set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::HardLeatherBelt, i)),
                'invalid hard leather blt prefix'
            );

            // assert leather belt is set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::LeatherBelt, i)),
                'invalid leather belt prefix'
            );

            // assert brightsilk sash is set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::BrightsilkSash, i)),
                'invalid brightsilk sash prefix'
            );

            // assert silk sash is set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::SilkSash, i)),
                'invalid silk sash prefix'
            );

            // assert wool sash is set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::WoolSash, i)),
                'invalid wool sash prefix'
            );

            // assert linen sash is set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::LinenSash, i)),
                'invalid linen sash prefix'
            );

            // assert sash is set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::Sash, i)),
                'invalid sash prefix'
            );

            // assert holy greaves is set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::HolyGreaves, i)),
                'invalid holy greaves prefix'
            );

            // assert ornate greaves is set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::OrnateGreaves, i)),
                'invalid ornate greaves prefix'
            );

            // assert greaves is set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::Greaves, i)),
                'invalid greaves prefix'
            );

            // assert chain boots is set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::ChainBoots, i)),
                'invalid chain boots prefix'
            );

            // assert heavy boots is set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::HeavyBoots, i)),
                'invalid heavy boots prefix'
            );

            // assert demonhide boots is set3
            assert(
                is_special2_set3(ImplLoot::generate_prefix1(ItemId::DemonhideBoots, i)),
                'invalid demonhide boots prefix'
            );

            // assert dragonskin boots is set1
            assert(
                is_special2_set1(ImplLoot::generate_prefix1(ItemId::DragonskinBoots, i)),
                'invalid dragonskin boots prefix'
            );

            // assert studded leather boots is set2
            assert(
                is_special2_set2(ImplLoot::generate_prefix1(ItemId::StuddedLeatherBoots, i)),
                'invalid stdded lthr boots prfix'
            );

            // Can't do any more tests on current version of scarb or we get a
            // #27302->#27303: Got 'Offset overflow' error while moving [5]

            i += 1;
        };
    }

    #[test]
    #[available_gas(229280)]
    fn test_pack_and_unpack() {
        let loot = Loot {
            id: 1, tier: Tier::T1(()), item_type: Type::Bludgeon_or_Metal(()), slot: Slot::Waist(())
        };

        let unpacked: Loot = LootPacking::unpack(LootPacking::pack(loot));
        assert(loot.id == unpacked.id, 'id');
        assert(loot.tier == unpacked.tier, 'tier');
        assert(loot.item_type == unpacked.item_type, 'item_type');
        assert(loot.slot == unpacked.slot, 'slot');
    }

    #[test]
    #[available_gas(21000)]
    fn test_get_item_gas() {
        ImplLoot::get_item(101);
    }

    #[test]
    #[available_gas(605400)]
    fn test_get_item_part1() {
        let katana_id = ItemId::Katana;
        let katana_item = ImplLoot::get_item(katana_id);
        assert(katana_item.tier == Tier::T1(()), 'katana is T1');
        assert(katana_item.item_type == Type::Blade_or_Hide(()), 'katana is blade');
        assert(katana_item.slot == Slot::Weapon(()), 'katana is weapon');

        let pendant_id = ItemId::Pendant;
        let pendant_item = ImplLoot::get_item(pendant_id);
        assert(pendant_item.tier == Tier::T1(()), 'pendant is T1');
        assert(pendant_item.item_type == Type::Necklace(()), 'pendant is necklace');
        assert(pendant_item.slot == Slot::Neck(()), 'pendant is neck slot');

        let necklace_id = ItemId::Necklace;
        let necklace_item = ImplLoot::get_item(necklace_id);
        assert(necklace_item.tier == Tier::T1(()), 'necklace is T1');
        assert(necklace_item.item_type == Type::Necklace(()), 'necklace is necklace');
        assert(necklace_item.slot == Slot::Neck(()), 'necklace is neck slot');

        let amulet_id = ItemId::Amulet;
        let amulet_item = ImplLoot::get_item(amulet_id);
        assert(amulet_item.tier == Tier::T1(()), 'amulet is T1');
        assert(amulet_item.item_type == Type::Necklace(()), 'amulet is necklace');
        assert(amulet_item.slot == Slot::Neck(()), 'amulet is neck slot');

        let silver_ring_id = ItemId::SilverRing;
        let silver_ring_item = ImplLoot::get_item(silver_ring_id);
        assert(silver_ring_item.tier == Tier::T2(()), 'silver ring is T2');
        assert(silver_ring_item.item_type == Type::Ring(()), 'silver ring is a ring');
        assert(silver_ring_item.slot == Slot::Ring(()), 'silver ring is ring slot');

        let bronze_ring_id = ItemId::BronzeRing;
        let bronze_ring_item = ImplLoot::get_item(bronze_ring_id);
        assert(bronze_ring_item.tier == Tier::T3(()), 'bronze ring is T3');
        assert(bronze_ring_item.item_type == Type::Ring(()), 'bronze ring is ring');
        assert(bronze_ring_item.slot == Slot::Ring(()), 'bronze ring is ring slot');

        let platinum_ring_id = ItemId::PlatinumRing;
        let platinum_ring_item = ImplLoot::get_item(platinum_ring_id);
        assert(platinum_ring_item.tier == Tier::T1(()), 'platinum ring is T1');
        assert(platinum_ring_item.item_type == Type::Ring(()), 'platinum ring is ring');
        assert(platinum_ring_item.slot == Slot::Ring(()), 'platinum ring is ring slot');

        let titanium_ring_id = ItemId::TitaniumRing;
        let titanium_ring_item = ImplLoot::get_item(titanium_ring_id);
        assert(titanium_ring_item.tier == Tier::T1(()), 'titanium ring is T1');
        assert(titanium_ring_item.item_type == Type::Ring(()), 'titanium ring is ring');
        assert(titanium_ring_item.slot == Slot::Ring(()), 'titanium ring is ring slot');

        let gold_ring_id = ItemId::GoldRing;
        let gold_ring_item = ImplLoot::get_item(gold_ring_id);
        assert(gold_ring_item.tier == Tier::T1(()), 'gold ring is T1');
        assert(gold_ring_item.item_type == Type::Ring(()), 'gold ring is ring');
        assert(gold_ring_item.slot == Slot::Ring(()), 'gold ring is ring slow');

        let ghost_wand_id = ItemId::GhostWand;
        let ghost_wand_item = ImplLoot::get_item(ghost_wand_id);
        assert(ghost_wand_item.tier == Tier::T1(()), 'ghost wand is T1');
        assert(ghost_wand_item.item_type == Type::Magic_or_Cloth(()), 'ghost wand is magical');
        assert(ghost_wand_item.slot == Slot::Weapon(()), 'ghost wand is weapon');

        let grave_wand_id = ItemId::GraveWand;
        let grave_wand_item = ImplLoot::get_item(grave_wand_id);
        assert(grave_wand_item.tier == Tier::T2(()), 'grave wand is T2');
        assert(grave_wand_item.item_type == Type::Magic_or_Cloth(()), 'grave wand is magical');
        assert(grave_wand_item.slot == Slot::Weapon(()), 'grave wand is weapon');

        let bone_wand_id = ItemId::BoneWand;
        let bone_wand_item = ImplLoot::get_item(bone_wand_id);
        assert(bone_wand_item.tier == Tier::T3(()), 'bone wand is T3');
        assert(bone_wand_item.item_type == Type::Magic_or_Cloth(()), 'bone wand is magical');
        assert(bone_wand_item.slot == Slot::Weapon(()), 'bone wand is weapon');

        let wand_id = ItemId::Wand;
        let wand_item = ImplLoot::get_item(wand_id);
        assert(wand_item.tier == Tier::T5(()), 'wand is T5');
        assert(wand_item.item_type == Type::Magic_or_Cloth(()), 'wand is magical');
        assert(wand_item.slot == Slot::Weapon(()), 'wand is weapon');

        let grimoire_id = ItemId::Grimoire;
        let grimoire_item = ImplLoot::get_item(grimoire_id);
        assert(grimoire_item.tier == Tier::T1(()), 'grimoire is T1');
        assert(grimoire_item.item_type == Type::Magic_or_Cloth(()), 'grimoire is magical');
        assert(grimoire_item.slot == Slot::Weapon(()), 'grimoire is weapon');

        let chronicle_id = ItemId::Chronicle;
        let chronicle_item = ImplLoot::get_item(chronicle_id);
        assert(chronicle_item.tier == Tier::T2(()), 'chronicle is T2');
        assert(chronicle_item.item_type == Type::Magic_or_Cloth(()), 'chronicle is magical');
        assert(chronicle_item.slot == Slot::Weapon(()), 'chronicle is weapon');

        let tome_id = ItemId::Tome;
        let tome_item = ImplLoot::get_item(tome_id);
        assert(tome_item.tier == Tier::T3(()), 'tome is T3');
        assert(tome_item.item_type == Type::Magic_or_Cloth(()), 'tome is magical');
        assert(tome_item.slot == Slot::Weapon(()), 'tome is weapon');

        let book_id = ItemId::Book;
        let book_item = ImplLoot::get_item(book_id);
        assert(book_item.tier == Tier::T5(()), 'book is T5');
        assert(book_item.item_type == Type::Magic_or_Cloth(()), 'book is magical');
        assert(book_item.slot == Slot::Weapon(()), 'book is weapon');

        let divine_robe_id = ItemId::DivineRobe;
        let divine_robe_item = ImplLoot::get_item(divine_robe_id);
        assert(divine_robe_item.tier == Tier::T1(()), 'divine robe is T1');
        assert(divine_robe_item.item_type == Type::Magic_or_Cloth(()), 'divine robe is cloth');
        assert(divine_robe_item.slot == Slot::Chest(()), 'divine robe is chest armor');

        let silk_robe_id = ItemId::SilkRobe;
        let silk_robe_item = ImplLoot::get_item(silk_robe_id);
        assert(silk_robe_item.tier == Tier::T2(()), 'silk robe is T2');
        assert(silk_robe_item.item_type == Type::Magic_or_Cloth(()), 'silk robe is cloth');
        assert(silk_robe_item.slot == Slot::Chest(()), 'silk robe is chest armor');

        let linen_robe_id = ItemId::LinenRobe;
        let linen_robe_item = ImplLoot::get_item(linen_robe_id);
        assert(linen_robe_item.tier == Tier::T3(()), 'linen robe is T3');
        assert(linen_robe_item.item_type == Type::Magic_or_Cloth(()), 'linen robe is cloth');
        assert(linen_robe_item.slot == Slot::Chest(()), 'linen robe is chest armor');

        let robe_id = ItemId::Robe;
        let robe_item = ImplLoot::get_item(robe_id);
        assert(robe_item.tier == Tier::T4(()), 'robe is T4');
        assert(robe_item.item_type == Type::Magic_or_Cloth(()), 'robe is cloth');
        assert(robe_item.slot == Slot::Chest(()), 'robe is chest armor');

        let shirt_id = ItemId::Shirt;
        let shirt_item = ImplLoot::get_item(shirt_id);
        assert(shirt_item.tier == Tier::T5(()), 'shirt is T5');
        assert(shirt_item.item_type == Type::Magic_or_Cloth(()), 'shirt is cloth');
        assert(shirt_item.slot == Slot::Chest(()), 'shirt is chest armor');

        let crown_id = ItemId::Crown;
        let crown_item = ImplLoot::get_item(crown_id);
        assert(crown_item.tier == Tier::T1(()), 'crown is T1');
        assert(crown_item.item_type == Type::Magic_or_Cloth(()), 'crown is cloth');
        assert(crown_item.slot == Slot::Head(()), 'crown is head armor');

        let divine_hood_id = ItemId::DivineHood;
        let divine_hood_item = ImplLoot::get_item(divine_hood_id);
        assert(divine_hood_item.tier == Tier::T2(()), 'divine hood is T2');
        assert(divine_hood_item.item_type == Type::Magic_or_Cloth(()), 'divine hood is cloth');
        assert(divine_hood_item.slot == Slot::Head(()), 'divine hood is head armor');
    }

    #[test]
    #[available_gas(630600)]
    fn test_get_item_part2() {
        let silk_hood_id = ItemId::SilkHood;
        let silk_hood_item = ImplLoot::get_item(silk_hood_id);
        assert(silk_hood_item.tier == Tier::T3(()), 'silk hood is T3');
        assert(silk_hood_item.item_type == Type::Magic_or_Cloth(()), 'silk hood is cloth');
        assert(silk_hood_item.slot == Slot::Head(()), 'silk hood is head armor');

        let linen_hood_id = ItemId::LinenHood;
        let linen_hood_item = ImplLoot::get_item(linen_hood_id);
        assert(linen_hood_item.tier == Tier::T4(()), 'linen hood is T4');
        assert(linen_hood_item.item_type == Type::Magic_or_Cloth(()), 'linen hood is cloth');
        assert(linen_hood_item.slot == Slot::Head(()), 'linen hood is head armor');

        let hood_id = ItemId::Hood;
        let hood_item = ImplLoot::get_item(hood_id);
        assert(hood_item.tier == Tier::T5(()), 'hood is T5');
        assert(hood_item.item_type == Type::Magic_or_Cloth(()), 'hood is cloth');
        assert(hood_item.slot == Slot::Head(()), 'hood is head armor');

        let brightsilk_sash_id = ItemId::BrightsilkSash;
        let brightsilk_sash_item = ImplLoot::get_item(brightsilk_sash_id);
        assert(brightsilk_sash_item.tier == Tier::T1(()), 'brightsilk sash is T1');
        assert(
            brightsilk_sash_item.item_type == Type::Magic_or_Cloth(()), 'brightsilk sash is cloth'
        );
        assert(brightsilk_sash_item.slot == Slot::Waist(()), 'brightsilk sash is waist armor');

        let silk_sash_id = ItemId::SilkSash;
        let silk_sash_item = ImplLoot::get_item(silk_sash_id);
        assert(silk_sash_item.tier == Tier::T2(()), 'silk sash is T2');
        assert(silk_sash_item.item_type == Type::Magic_or_Cloth(()), 'silk sash is cloth');
        assert(silk_sash_item.slot == Slot::Waist(()), 'silk sash is waist armor');

        let wool_sash_id = ItemId::WoolSash;
        let wool_sash_item = ImplLoot::get_item(wool_sash_id);
        assert(wool_sash_item.tier == Tier::T3(()), 'wool sash is T3');
        assert(wool_sash_item.item_type == Type::Magic_or_Cloth(()), 'wool sash is cloth');
        assert(wool_sash_item.slot == Slot::Waist(()), 'wool sash is waist armor');

        let linen_sash_id = ItemId::LinenSash;
        let linen_sash_item = ImplLoot::get_item(linen_sash_id);
        assert(linen_sash_item.tier == Tier::T4(()), 'linen sash is T4');
        assert(linen_sash_item.item_type == Type::Magic_or_Cloth(()), 'linen sash is cloth');
        assert(linen_sash_item.slot == Slot::Waist(()), 'linen sash is waist armor');

        let sash_id = ItemId::Sash;
        let sash_item = ImplLoot::get_item(sash_id);
        assert(sash_item.tier == Tier::T5(()), 'sash is T5');
        assert(sash_item.item_type == Type::Magic_or_Cloth(()), 'sash is cloth');
        assert(sash_item.slot == Slot::Waist(()), 'sash is waist armor');

        let divine_slippers_id = ItemId::DivineSlippers;
        let divine_slippers_item = ImplLoot::get_item(divine_slippers_id);
        assert(divine_slippers_item.tier == Tier::T1(()), 'divine slippers are T1');
        assert(
            divine_slippers_item.item_type == Type::Magic_or_Cloth(()), 'divine slippers are cloth'
        );
        assert(divine_slippers_item.slot == Slot::Foot(()), 'divine slippers are foot armor');

        let silk_slippers_id = ItemId::SilkSlippers;
        let silk_slippers_item = ImplLoot::get_item(silk_slippers_id);
        assert(silk_slippers_item.tier == Tier::T2(()), 'silk slippers are T2');
        assert(silk_slippers_item.item_type == Type::Magic_or_Cloth(()), 'silk slippers are cloth');
        assert(silk_slippers_item.slot == Slot::Foot(()), 'silk slippers are foot armor');

        let wool_shoes_id = ItemId::WoolShoes;
        let wool_shoes_item = ImplLoot::get_item(wool_shoes_id);
        assert(wool_shoes_item.tier == Tier::T3(()), 'wool shoes are T3');
        assert(wool_shoes_item.item_type == Type::Magic_or_Cloth(()), 'wool shoes are cloth');
        assert(wool_shoes_item.slot == Slot::Foot(()), 'wool shoes are foot armor');

        let linen_shoes_id = ItemId::LinenShoes;
        let linen_shoes_item = ImplLoot::get_item(linen_shoes_id);
        assert(linen_shoes_item.tier == Tier::T4(()), 'linen shoes are T4');
        assert(linen_shoes_item.item_type == Type::Magic_or_Cloth(()), 'linen shoes are cloth');
        assert(linen_shoes_item.slot == Slot::Foot(()), 'linen shoes are foot armor');

        let shoes_id = ItemId::Shoes;
        let shoes_item = ImplLoot::get_item(shoes_id);
        assert(shoes_item.tier == Tier::T5(()), 'shoes are T5');
        assert(shoes_item.item_type == Type::Magic_or_Cloth(()), 'shoes are cloth');
        assert(shoes_item.slot == Slot::Foot(()), 'shoes are foot armor');

        let divine_gloves_id = ItemId::DivineGloves;
        let divine_gloves_item = ImplLoot::get_item(divine_gloves_id);
        assert(divine_gloves_item.tier == Tier::T1(()), 'divine gloves are T1');
        assert(divine_gloves_item.item_type == Type::Magic_or_Cloth(()), 'divine gloves are cloth');
        assert(divine_gloves_item.slot == Slot::Hand(()), 'divine gloves are hand armor');

        let silk_gloves_id = ItemId::SilkGloves;
        let silk_gloves_item = ImplLoot::get_item(silk_gloves_id);
        assert(silk_gloves_item.tier == Tier::T2(()), 'silk gloves are T2');
        assert(silk_gloves_item.item_type == Type::Magic_or_Cloth(()), 'silk gloves are cloth');
        assert(silk_gloves_item.slot == Slot::Hand(()), 'silk gloves are hand armor');

        let wool_gloves_id = ItemId::WoolGloves;
        let wool_gloves_item = ImplLoot::get_item(wool_gloves_id);
        assert(wool_gloves_item.tier == Tier::T3(()), 'wool gloves are T3');
        assert(wool_gloves_item.item_type == Type::Magic_or_Cloth(()), 'wool gloves are cloth');
        assert(wool_gloves_item.slot == Slot::Hand(()), 'wool gloves are hand armor');

        let linen_gloves_id = ItemId::LinenGloves;
        let linen_gloves_item = ImplLoot::get_item(linen_gloves_id);
        assert(linen_gloves_item.tier == Tier::T4(()), 'linen gloves are T4');
        assert(
            linen_gloves_item.item_type == Type::Magic_or_Cloth(()), 'linen gloves are hand armor'
        );
        assert(linen_gloves_item.slot == Slot::Hand(()), 'linen gloves are cloth');

        let gloves_id = ItemId::Gloves;
        let gloves_item = ImplLoot::get_item(gloves_id);
        assert(gloves_item.tier == Tier::T5(()), 'gloves are T5');
        assert(gloves_item.item_type == Type::Magic_or_Cloth(()), 'gloves are cloth');
        assert(gloves_item.slot == Slot::Hand(()), 'gloves are hand armor');

        let katana_id = ItemId::Katana;
        let katana_item = ImplLoot::get_item(katana_id);
        assert(katana_item.tier == Tier::T1(()), 'katana is T1');
        assert(katana_item.item_type == Type::Blade_or_Hide(()), 'katana is blade');
        assert(katana_item.slot == Slot::Weapon(()), 'katana is weapon');

        let falchion_id = ItemId::Falchion;
        let falchion_item = ImplLoot::get_item(falchion_id);
        assert(falchion_item.tier == Tier::T2(()), 'falchion is T2');
        assert(falchion_item.item_type == Type::Blade_or_Hide(()), 'falchion is blade');
        assert(falchion_item.slot == Slot::Weapon(()), 'falchion is weapon');

        let scimitar_id = ItemId::Scimitar;
        let scimitar_item = ImplLoot::get_item(scimitar_id);
        assert(scimitar_item.tier == Tier::T3(()), 'scimitar is T3');
        assert(scimitar_item.item_type == Type::Blade_or_Hide(()), 'scimitar is blade');
        assert(scimitar_item.slot == Slot::Weapon(()), 'scimitar is weapon');

        let long_sword_id = ItemId::LongSword;
        let long_sword_item = ImplLoot::get_item(long_sword_id);
        assert(long_sword_item.tier == Tier::T4(()), 'long sword is T4');
        assert(long_sword_item.item_type == Type::Blade_or_Hide(()), 'long sword is blade');
        assert(long_sword_item.slot == Slot::Weapon(()), 'long sword is weapon');

        let short_sword_id = ItemId::ShortSword;
        let short_sword_item = ImplLoot::get_item(short_sword_id);
        assert(short_sword_item.tier == Tier::T5(()), 'short sword is T5');
        assert(short_sword_item.item_type == Type::Blade_or_Hide(()), 'short sword is blade');
        assert(short_sword_item.slot == Slot::Weapon(()), 'short sword is weapon');

        let demon_husk_id = ItemId::DemonHusk;
        let demon_husk_item = ImplLoot::get_item(demon_husk_id);
        assert(demon_husk_item.tier == Tier::T1(()), 'demon husk is T1');
        assert(demon_husk_item.item_type == Type::Blade_or_Hide(()), 'demon husk is hide');
        assert(demon_husk_item.slot == Slot::Chest(()), 'demon husk is chest armor');

        let dragonskin_armor_id = ItemId::DragonskinArmor;
        let dragonskin_armor_item = ImplLoot::get_item(dragonskin_armor_id);
        assert(dragonskin_armor_item.tier == Tier::T2(()), 'dragonskin armor is T2');
        assert(
            dragonskin_armor_item.item_type == Type::Blade_or_Hide(()), 'dragonskin armor is hide'
        );
        assert(dragonskin_armor_item.slot == Slot::Chest(()), 'dragonskin armor is chest armor');
    }

    #[test]
    #[available_gas(378600)]
    fn test_get_item_part3() {
        let studded_leather_armor_id = ItemId::StuddedLeatherArmor;
        let studded_leather_armor_item = ImplLoot::get_item(studded_leather_armor_id);
        assert(studded_leather_armor_item.tier == Tier::T3(()), 'studded leather armor is T3');
        assert(
            studded_leather_armor_item.item_type == Type::Blade_or_Hide(()),
            'studded leather armor is hide'
        );
        assert(
            studded_leather_armor_item.slot == Slot::Chest(()), 'studded leather armor is chest'
        );

        let hard_leather_armor_id = ItemId::HardLeatherArmor;
        let hard_leather_armor_item = ImplLoot::get_item(hard_leather_armor_id);
        assert(hard_leather_armor_item.tier == Tier::T4(()), 'hard leather armor is T4');
        assert(
            hard_leather_armor_item.item_type == Type::Blade_or_Hide(()),
            'hard leather armor is hide'
        );
        assert(hard_leather_armor_item.slot == Slot::Chest(()), 'hard leather armor is chest');

        let leather_armor_id = ItemId::LeatherArmor;
        let leather_armor_item = ImplLoot::get_item(leather_armor_id);
        assert(leather_armor_item.tier == Tier::T5(()), 'leather armor is T5');
        assert(leather_armor_item.item_type == Type::Blade_or_Hide(()), 'leather armor is hide');
        assert(leather_armor_item.slot == Slot::Chest(()), 'leather armor is chest armor');

        let demon_crown_id = ItemId::DemonCrown;
        let demon_crown_item = ImplLoot::get_item(demon_crown_id);
        assert(demon_crown_item.tier == Tier::T1(()), 'demon crown is T1');
        assert(demon_crown_item.item_type == Type::Blade_or_Hide(()), 'demon crown is hide');
        assert(demon_crown_item.slot == Slot::Head(()), 'demon crown is head armor');

        let dragons_crown_id = ItemId::DragonsCrown;
        let dragons_crown_item = ImplLoot::get_item(dragons_crown_id);
        assert(dragons_crown_item.tier == Tier::T2(()), 'dragons crown is T2');
        assert(dragons_crown_item.item_type == Type::Blade_or_Hide(()), 'dragons crown is hide');
        assert(dragons_crown_item.slot == Slot::Head(()), 'dragons crown is head armor');

        let war_cap_id = ItemId::WarCap;
        let war_cap_item = ImplLoot::get_item(war_cap_id);
        assert(war_cap_item.tier == Tier::T3(()), 'war cap is T3');
        assert(war_cap_item.item_type == Type::Blade_or_Hide(()), 'war cap is hide');
        assert(war_cap_item.slot == Slot::Head(()), 'war cap is head armor');

        let leather_cap_id = ItemId::LeatherCap;
        let leather_cap_item = ImplLoot::get_item(leather_cap_id);
        assert(leather_cap_item.tier == Tier::T4(()), 'leather cap is T4');
        assert(leather_cap_item.item_type == Type::Blade_or_Hide(()), 'leather cap is hide');
        assert(leather_cap_item.slot == Slot::Head(()), 'leather cap is head armor');

        let cap_id = ItemId::Cap;
        let cap_item = ImplLoot::get_item(cap_id);
        assert(cap_item.tier == Tier::T5(()), 'cap is T5');
        assert(cap_item.item_type == Type::Blade_or_Hide(()), 'cap is hide');
        assert(cap_item.slot == Slot::Head(()), 'cap is head armor');

        let demonhide_belt_id = ItemId::DemonhideBelt;
        let demonhide_belt_item = ImplLoot::get_item(demonhide_belt_id);
        assert(demonhide_belt_item.tier == Tier::T1(()), 'demonhide belt is T1');
        assert(demonhide_belt_item.item_type == Type::Blade_or_Hide(()), 'demonhide belt is hide');
        assert(demonhide_belt_item.slot == Slot::Waist(()), 'demonhide belt is waist armor');

        let dragonskin_belt_id = ItemId::DragonskinBelt;
        let dragonskin_belt_item = ImplLoot::get_item(dragonskin_belt_id);
        assert(dragonskin_belt_item.tier == Tier::T2(()), 'dragonskin belt is T2');
        assert(
            dragonskin_belt_item.item_type == Type::Blade_or_Hide(()), 'dragonskin belt is hide'
        );
        assert(dragonskin_belt_item.slot == Slot::Waist(()), 'dragonskin belt is waist armor');

        let studded_leather_belt_id = ItemId::StuddedLeatherBelt;
        let studded_leather_belt_item = ImplLoot::get_item(studded_leather_belt_id);
        assert(studded_leather_belt_item.tier == Tier::T3(()), 'studded leather belt is T3');
        assert(
            studded_leather_belt_item.item_type == Type::Blade_or_Hide(()),
            'studded leather belt is hide'
        );
        assert(studded_leather_belt_item.slot == Slot::Waist(()), 'studded leather belt is waist');

        let hard_leather_belt_id = ItemId::HardLeatherBelt;
        let hard_leather_belt_item = ImplLoot::get_item(hard_leather_belt_id);
        assert(hard_leather_belt_item.tier == Tier::T4(()), 'hard leather belt is T4');
        assert(
            hard_leather_belt_item.item_type == Type::Blade_or_Hide(()), 'hard leather belt is hide'
        );
        assert(hard_leather_belt_item.slot == Slot::Waist(()), 'hard leather belt is waist');

        let leather_belt_id = ItemId::LeatherBelt;
        let leather_belt_item = ImplLoot::get_item(leather_belt_id);
        assert(leather_belt_item.tier == Tier::T5(()), 'leather belt is T5');
        assert(leather_belt_item.item_type == Type::Blade_or_Hide(()), 'leather belt is hide');
        assert(leather_belt_item.slot == Slot::Waist(()), 'leather belt is waist armor');

        let demonhide_boots_id = ItemId::DemonhideBoots;
        let demonhide_boots_item = ImplLoot::get_item(demonhide_boots_id);
        assert(demonhide_boots_item.tier == Tier::T1(()), 'demonhide boots is T1');
        assert(
            demonhide_boots_item.item_type == Type::Blade_or_Hide(()), 'demonhide boots is hide'
        );
        assert(demonhide_boots_item.slot == Slot::Foot(()), 'demonhide boots is foot armor');

        let dragonskin_boots_id = ItemId::DragonskinBoots;
        let dragonskin_boots_item = ImplLoot::get_item(dragonskin_boots_id);
        assert(dragonskin_boots_item.tier == Tier::T2(()), 'dragonskin boots is T2');
        assert(
            dragonskin_boots_item.item_type == Type::Blade_or_Hide(()), 'dragonskin boots is hide'
        );
        assert(dragonskin_boots_item.slot == Slot::Foot(()), 'dragonskin boots is foot armor');
    }

    #[test]
    #[available_gas(328200)]
    fn test_get_item_part4() {
        let studded_leather_boots_id = ItemId::StuddedLeatherBoots;
        let studded_leather_boots_item = ImplLoot::get_item(studded_leather_boots_id);
        assert(studded_leather_boots_item.tier == Tier::T3(()), 'studded leather boots is T3');
        assert(
            studded_leather_boots_item.item_type == Type::Blade_or_Hide(()),
            'studded leather boots is hide'
        );
        assert(studded_leather_boots_item.slot == Slot::Foot(()), 'studded leather boots is foot');

        let hard_leather_boots_id = ItemId::HardLeatherBoots;
        let hard_leather_boots_item = ImplLoot::get_item(hard_leather_boots_id);
        assert(hard_leather_boots_item.tier == Tier::T4(()), 'hard leather boots is T4');
        assert(
            hard_leather_boots_item.item_type == Type::Blade_or_Hide(()),
            'hard leather boots is hide'
        );
        assert(hard_leather_boots_item.slot == Slot::Foot(()), 'hard leather boots is foot');

        let leather_boots_id = ItemId::LeatherBoots;
        let leather_boots_item = ImplLoot::get_item(leather_boots_id);
        assert(leather_boots_item.tier == Tier::T5(()), 'leather boots is T5');
        assert(leather_boots_item.item_type == Type::Blade_or_Hide(()), 'leather boots is hide');
        assert(leather_boots_item.slot == Slot::Foot(()), 'leather boots is foot armor');

        let demons_hands_id = ItemId::DemonsHands;
        let demons_hands_item = ImplLoot::get_item(demons_hands_id);
        assert(demons_hands_item.tier == Tier::T1(()), 'demons hands is T1');
        assert(demons_hands_item.item_type == Type::Blade_or_Hide(()), 'demons hands is hide');
        assert(demons_hands_item.slot == Slot::Hand(()), 'demons hands is hand armor');

        let dragonskin_gloves_id = ItemId::DragonskinGloves;
        let dragonskin_gloves_item = ImplLoot::get_item(dragonskin_gloves_id);
        assert(dragonskin_gloves_item.tier == Tier::T2(()), 'dragonskin gloves is T2');
        assert(
            dragonskin_gloves_item.item_type == Type::Blade_or_Hide(()), 'dragonskin gloves is hide'
        );
        assert(dragonskin_gloves_item.slot == Slot::Hand(()), 'dragonskin gloves is hand armor');

        let studded_leather_gloves_id = ItemId::StuddedLeatherGloves;
        let studded_leather_gloves_item = ImplLoot::get_item(studded_leather_gloves_id);
        assert(studded_leather_gloves_item.tier == Tier::T3(()), 'studded leather gloves is T3');
        assert(
            studded_leather_gloves_item.item_type == Type::Blade_or_Hide(()),
            'studded leather gloves is hide'
        );
        assert(
            studded_leather_gloves_item.slot == Slot::Hand(()), 'studded leather gloves is hand'
        );

        let hard_leather_gloves_id = ItemId::HardLeatherGloves;
        let hard_leather_gloves_item = ImplLoot::get_item(hard_leather_gloves_id);
        assert(hard_leather_gloves_item.tier == Tier::T4(()), 'hard leather gloves is T4');
        assert(
            hard_leather_gloves_item.item_type == Type::Blade_or_Hide(()),
            'hard leather gloves is hide'
        );
        assert(hard_leather_gloves_item.slot == Slot::Hand(()), 'hard leather gloves is hand');

        let leather_gloves_id = ItemId::LeatherGloves;
        let leather_gloves_item = ImplLoot::get_item(leather_gloves_id);
        assert(leather_gloves_item.tier == Tier::T5(()), 'leather gloves is T5');
        assert(leather_gloves_item.item_type == Type::Blade_or_Hide(()), 'leather gloves is hide');
        assert(leather_gloves_item.slot == Slot::Hand(()), 'leather gloves is hand armor');

        let warhammer_id = ItemId::Warhammer;
        let warhammer_item = ImplLoot::get_item(warhammer_id);
        assert(warhammer_item.tier == Tier::T1(()), 'warhammer is T1');
        assert(warhammer_item.item_type == Type::Bludgeon_or_Metal(()), 'warhammer is bludgeon');
        assert(warhammer_item.slot == Slot::Weapon(()), 'warhammer is weapon');

        let quarterstaff_id = ItemId::Quarterstaff;
        let quarterstaff_item = ImplLoot::get_item(quarterstaff_id);
        assert(quarterstaff_item.tier == Tier::T2(()), 'quarterstaff is T2');
        assert(
            quarterstaff_item.item_type == Type::Bludgeon_or_Metal(()), 'quarterstaff is bludgeon'
        );
        assert(quarterstaff_item.slot == Slot::Weapon(()), 'quarterstaff is weapon');

        let maul_id = ItemId::Maul;
        let maul_item = ImplLoot::get_item(maul_id);
        assert(maul_item.tier == Tier::T3(()), 'maul is T3');
        assert(maul_item.item_type == Type::Bludgeon_or_Metal(()), 'maul is bludgeon');
        assert(maul_item.slot == Slot::Weapon(()), 'maul is weapon');

        let mace_id = ItemId::Mace;
        let mace_item = ImplLoot::get_item(mace_id);
        assert(mace_item.tier == Tier::T4(()), 'mace is T4');
        assert(mace_item.item_type == Type::Bludgeon_or_Metal(()), 'mace is bludgeon');
        assert(mace_item.slot == Slot::Weapon(()), 'mace is weapon');

        let club_id = ItemId::Club;
        let club_item = ImplLoot::get_item(club_id);
        assert(club_item.tier == Tier::T5(()), 'club is T5');
        assert(club_item.item_type == Type::Bludgeon_or_Metal(()), 'club is bludgeon');
        assert(club_item.slot == Slot::Weapon(()), 'club is weapon');
    }

    #[test]
    #[available_gas(20700)]
    fn test_get_slot_gas() {
        ImplLoot::get_slot(1);
    }

    #[test]
    #[available_gas(2222600)]
    fn test_get_slot() {
        // Weapons
        let katana = ItemId::Katana;
        let katana_slot = ImplLoot::get_slot(katana);
        assert(katana_slot == Slot::Weapon(()), 'katana is weapon slot');

        let warhammer = ItemId::Warhammer;
        let warhammer_slot = ImplLoot::get_slot(warhammer);
        assert(warhammer_slot == Slot::Weapon(()), 'warhammer is weapon slot');

        let quarterstaff = ItemId::Quarterstaff;
        let quarterstaff_slot = ImplLoot::get_slot(quarterstaff);
        assert(quarterstaff_slot == Slot::Weapon(()), 'quarterstaff is weapon slot');

        let maul = ItemId::Maul;
        let maul_slot = ImplLoot::get_slot(maul);
        assert(maul_slot == Slot::Weapon(()), 'maul is weapon slot');

        let mace = ItemId::Mace;
        let mace_slot = ImplLoot::get_slot(mace);
        assert(mace_slot == Slot::Weapon(()), 'mace is weapon slot');

        let club = ItemId::Club;
        let club_slot = ImplLoot::get_slot(club);
        assert(club_slot == Slot::Weapon(()), 'club is weapon slot');

        let falchion = ItemId::Falchion;
        let falchion_slot = ImplLoot::get_slot(falchion);
        assert(falchion_slot == Slot::Weapon(()), 'falchion is weapon slot');

        let scimitar = ItemId::Scimitar;
        let scimitar_slot = ImplLoot::get_slot(scimitar);
        assert(scimitar_slot == Slot::Weapon(()), 'scimitar is weapon slot');

        let long_sword = ItemId::LongSword;
        let long_sword_slot = ImplLoot::get_slot(long_sword);
        assert(long_sword_slot == Slot::Weapon(()), 'long sword is weapon slot');

        let short_sword = ItemId::ShortSword;
        let short_sword_slot = ImplLoot::get_slot(short_sword);
        assert(short_sword_slot == Slot::Weapon(()), 'short sword is weapon slot');

        let ghost_wand = ItemId::GhostWand;
        let ghost_wand_slot = ImplLoot::get_slot(ghost_wand);
        assert(ghost_wand_slot == Slot::Weapon(()), 'ghost wand is weapon slot');

        let grave_wand = ItemId::GraveWand;
        let grave_wand_slot = ImplLoot::get_slot(grave_wand);
        assert(grave_wand_slot == Slot::Weapon(()), 'grave wand is weapon slot');

        let bone_wand = ItemId::BoneWand;
        let bone_wand_slot = ImplLoot::get_slot(bone_wand);
        assert(bone_wand_slot == Slot::Weapon(()), 'bone wand is weapon slot');

        let wand = ItemId::Wand;
        let wand_slot = ImplLoot::get_slot(wand);
        assert(wand_slot == Slot::Weapon(()), 'wand is weapon slot');

        let grimoire = ItemId::Grimoire;
        let grimoire_slot = ImplLoot::get_slot(grimoire);
        assert(grimoire_slot == Slot::Weapon(()), 'grimoire is weapon slot');

        let chronicle = ItemId::Chronicle;
        let chronicle_slot = ImplLoot::get_slot(chronicle);
        assert(chronicle_slot == Slot::Weapon(()), 'chronicle is weapon slot');

        let tome = ItemId::Tome;
        let tome_slot = ImplLoot::get_slot(tome);
        assert(tome_slot == Slot::Weapon(()), 'tome is weapon slot');

        let book = ItemId::Book;
        let book_slot = ImplLoot::get_slot(book);
        assert(book_slot == Slot::Weapon(()), 'book is weapon slot');

        // Chest
        let divine_robe = ItemId::DivineRobe;
        let divine_robe_slot = ImplLoot::get_slot(divine_robe);
        assert(divine_robe_slot == Slot::Chest(()), 'divine robe is chest slot');

        let silk_robe = ItemId::SilkRobe;
        let silk_robe_slot = ImplLoot::get_slot(silk_robe);
        assert(silk_robe_slot == Slot::Chest(()), 'silk robe is chest slot');

        let linen_robe = ItemId::LinenRobe;
        let linen_robe_slot = ImplLoot::get_slot(linen_robe);
        assert(linen_robe_slot == Slot::Chest(()), 'linen robe is chest slot');

        let robe = ItemId::Robe;
        let robe_slot = ImplLoot::get_slot(robe);
        assert(robe_slot == Slot::Chest(()), 'robe is chest slot');

        let shirt = ItemId::Shirt;
        let shirt_slot = ImplLoot::get_slot(shirt);
        assert(shirt_slot == Slot::Chest(()), 'shirt is chest slot');

        let demon_husk = ItemId::DemonHusk;
        let demon_husk_slot = ImplLoot::get_slot(demon_husk);
        assert(demon_husk_slot == Slot::Chest(()), 'demon husk is chest slot');

        let dragonskin_armor = ItemId::DragonskinArmor;
        let dragonskin_armor_slot = ImplLoot::get_slot(dragonskin_armor);
        assert(dragonskin_armor_slot == Slot::Chest(()), 'dragonskin armor is chest slot');

        let studded_leather_armor = ItemId::StuddedLeatherArmor;
        let studded_leather_armor_slot = ImplLoot::get_slot(studded_leather_armor);
        assert(studded_leather_armor_slot == Slot::Chest(()), 'studded leather armor slot err');

        let hard_leather_armor = ItemId::HardLeatherArmor;
        let hard_leather_armor_slot = ImplLoot::get_slot(hard_leather_armor);
        assert(hard_leather_armor_slot == Slot::Chest(()), 'hard leather armor slot err');

        let leather_armor = ItemId::LeatherArmor;
        let leather_armor_slot = ImplLoot::get_slot(leather_armor);
        assert(leather_armor_slot == Slot::Chest(()), 'leather armor is chest slot');

        let holy_chestplate = ItemId::HolyChestplate;
        let holy_chestplate_slot = ImplLoot::get_slot(holy_chestplate);
        assert(holy_chestplate_slot == Slot::Chest(()), 'holy chestplate is chest slot');

        let ornate_chestplate = ItemId::OrnateChestplate;
        let ornate_chestplate_slot = ImplLoot::get_slot(ornate_chestplate);
        assert(ornate_chestplate_slot == Slot::Chest(()), 'ornate chestplate is chest slot');

        let plate_mail = ItemId::PlateMail;
        let plate_mail_slot = ImplLoot::get_slot(plate_mail);
        assert(plate_mail_slot == Slot::Chest(()), 'plate mail is chest slot');

        let chain_mail = ItemId::ChainMail;
        let chain_mail_slot = ImplLoot::get_slot(chain_mail);
        assert(chain_mail_slot == Slot::Chest(()), 'chain mail is chest slot');

        let ring_mail = ItemId::RingMail;
        let ring_mail_slot = ImplLoot::get_slot(ring_mail);
        assert(ring_mail_slot == Slot::Chest(()), 'ring mail is chest slot');

        // Head
        let ancient_helm = ItemId::AncientHelm;
        let ancient_helm_slot = ImplLoot::get_slot(ancient_helm);
        assert(ancient_helm_slot == Slot::Head(()), 'ancient helm is head slot');

        let ornate_helm = ItemId::OrnateHelm;
        let ornate_helm_slot = ImplLoot::get_slot(ornate_helm);
        assert(ornate_helm_slot == Slot::Head(()), 'ornate helm is head slot');

        let great_helm = ItemId::GreatHelm;
        let great_helm_slot = ImplLoot::get_slot(great_helm);
        assert(great_helm_slot == Slot::Head(()), 'great helm is head slot');

        let full_helm = ItemId::FullHelm;
        let full_helm_slot = ImplLoot::get_slot(full_helm);
        assert(full_helm_slot == Slot::Head(()), 'full helm is head slot');

        let helm = ItemId::Helm;
        let helm_slot = ImplLoot::get_slot(helm);
        assert(helm_slot == Slot::Head(()), 'helm is head slot');

        let demon_crown = ItemId::DemonCrown;
        let demon_crown_slot = ImplLoot::get_slot(demon_crown);
        assert(demon_crown_slot == Slot::Head(()), 'demon crown is head slot');

        let dragons_crown = ItemId::DragonsCrown;
        let dragons_crown_slot = ImplLoot::get_slot(dragons_crown);
        assert(dragons_crown_slot == Slot::Head(()), 'dragons crown is head slot');

        let war_cap = ItemId::WarCap;
        let war_cap_slot = ImplLoot::get_slot(war_cap);
        assert(war_cap_slot == Slot::Head(()), 'war cap is head slot');

        let leather_cap = ItemId::LeatherCap;
        let leather_cap_slot = ImplLoot::get_slot(leather_cap);
        assert(leather_cap_slot == Slot::Head(()), 'leather cap is head slot');

        let cap = ItemId::Cap;
        let cap_slot = ImplLoot::get_slot(cap);
        assert(cap_slot == Slot::Head(()), 'cap is head slot');

        let crown = ItemId::Crown;
        let crown_slot = ImplLoot::get_slot(crown);
        assert(crown_slot == Slot::Head(()), 'crown is head slot');

        let divine_hood = ItemId::DivineHood;
        let divine_hood_slot = ImplLoot::get_slot(divine_hood);
        assert(divine_hood_slot == Slot::Head(()), 'divine hood is head slot');

        let silk_hood = ItemId::SilkHood;
        let silk_hood_slot = ImplLoot::get_slot(silk_hood);
        assert(silk_hood_slot == Slot::Head(()), 'silk hood is head slot');

        let linen_hood = ItemId::LinenHood;
        let linen_hood_slot = ImplLoot::get_slot(linen_hood);
        assert(linen_hood_slot == Slot::Head(()), 'linen hood is head slot');

        let hood = ItemId::Hood;
        let hood_slot = ImplLoot::get_slot(hood);
        assert(hood_slot == Slot::Head(()), 'hood is head slot');

        // Waist
        let ornate_belt = ItemId::OrnateBelt;
        let ornate_belt_slot = ImplLoot::get_slot(ornate_belt);
        assert(ornate_belt_slot == Slot::Waist(()), 'ornate belt is waist slot');

        let war_belt = ItemId::WarBelt;
        let war_belt_slot = ImplLoot::get_slot(war_belt);
        assert(war_belt_slot == Slot::Waist(()), 'war belt is waist slot');

        let plated_belt = ItemId::PlatedBelt;
        let plated_belt_slot = ImplLoot::get_slot(plated_belt);
        assert(plated_belt_slot == Slot::Waist(()), 'plated belt is waist slot');

        let mesh_belt = ItemId::MeshBelt;
        let mesh_belt_slot = ImplLoot::get_slot(mesh_belt);
        assert(mesh_belt_slot == Slot::Waist(()), 'mesh belt is waist slot');

        let heavy_belt = ItemId::HeavyBelt;
        let heavy_belt_slot = ImplLoot::get_slot(heavy_belt);
        assert(heavy_belt_slot == Slot::Waist(()), 'heavy belt is waist slot');

        let demonhide_belt = ItemId::DemonhideBelt;
        let demonhide_belt_slot = ImplLoot::get_slot(demonhide_belt);
        assert(demonhide_belt_slot == Slot::Waist(()), 'demonhide belt is waist slot');

        let dragonskin_belt = ItemId::DragonskinBelt;
        let dragonskin_belt_slot = ImplLoot::get_slot(dragonskin_belt);
        assert(dragonskin_belt_slot == Slot::Waist(()), 'dragonskin belt is waist slot');

        let studded_leather_belt = ItemId::StuddedLeatherBelt;
        let studded_leather_belt_slot = ImplLoot::get_slot(studded_leather_belt);
        assert(studded_leather_belt_slot == Slot::Waist(()), 'studded leather belt wrong slot');

        let hard_leather_belt = ItemId::HardLeatherBelt;
        let hard_leather_belt_slot = ImplLoot::get_slot(hard_leather_belt);
        assert(hard_leather_belt_slot == Slot::Waist(()), 'hard leather belt is waist slot');

        let leather_belt = ItemId::LeatherBelt;
        let leather_belt_slot = ImplLoot::get_slot(leather_belt);
        assert(leather_belt_slot == Slot::Waist(()), 'leather belt is waist slot');

        let brightsilk_sash = ItemId::BrightsilkSash;
        let brightsilk_sash_slot = ImplLoot::get_slot(brightsilk_sash);
        assert(brightsilk_sash_slot == Slot::Waist(()), 'brightsilk sash is waist slot');

        let silk_sash = ItemId::SilkSash;
        let silk_sash_slot = ImplLoot::get_slot(silk_sash);
        assert(silk_sash_slot == Slot::Waist(()), 'silk sash is waist slot');

        let wool_sash = ItemId::WoolSash;
        let wool_sash_slot = ImplLoot::get_slot(wool_sash);
        assert(wool_sash_slot == Slot::Waist(()), 'wool sash is waist slot');

        let linen_sash = ItemId::LinenSash;
        let linen_sash_slot = ImplLoot::get_slot(linen_sash);
        assert(linen_sash_slot == Slot::Waist(()), 'linen sash is waist slot');

        let sash = ItemId::Sash;
        let sash_slot = ImplLoot::get_slot(sash);
        assert(sash_slot == Slot::Waist(()), 'sash is waist slot');

        // Foot
        let holy_greaves = ItemId::HolyGreaves;
        let holy_greaves_slot = ImplLoot::get_slot(holy_greaves);
        assert(holy_greaves_slot == Slot::Foot(()), 'holy greaves is foot slot');

        let ornate_greaves = ItemId::OrnateGreaves;
        let ornate_greaves_slot = ImplLoot::get_slot(ornate_greaves);
        assert(ornate_greaves_slot == Slot::Foot(()), 'ornate greaves is foot slot');

        let greaves = ItemId::Greaves;
        let greaves_slot = ImplLoot::get_slot(greaves);
        assert(greaves_slot == Slot::Foot(()), 'greaves is foot slot');

        let chain_boots = ItemId::ChainBoots;
        let chain_boots_slot = ImplLoot::get_slot(chain_boots);
        assert(chain_boots_slot == Slot::Foot(()), 'chain boots is foot slot');

        let heavy_boots = ItemId::HeavyBoots;
        let heavy_boots_slot = ImplLoot::get_slot(heavy_boots);
        assert(heavy_boots_slot == Slot::Foot(()), 'heavy boots is foot slot');

        let demonhide_boots = ItemId::DemonhideBoots;
        let demonhide_boots_slot = ImplLoot::get_slot(demonhide_boots);
        assert(demonhide_boots_slot == Slot::Foot(()), 'demonhide boots is foot slot');

        let dragonskin_boots = ItemId::DragonskinBoots;
        let dragonskin_boots_slot = ImplLoot::get_slot(dragonskin_boots);
        assert(dragonskin_boots_slot == Slot::Foot(()), 'dragonskin boots is foot slot');

        let studded_leather_boots = ItemId::StuddedLeatherBoots;
        let studded_leather_boots_slot = ImplLoot::get_slot(studded_leather_boots);
        assert(studded_leather_boots_slot == Slot::Foot(()), 'studded leather boots err');

        let hard_leather_boots = ItemId::HardLeatherBoots;
        let hard_leather_boots_slot = ImplLoot::get_slot(hard_leather_boots);
        assert(hard_leather_boots_slot == Slot::Foot(()), 'hard leather boots is foot slot');

        let leather_boots = ItemId::LeatherBoots;
        let leather_boots_slot = ImplLoot::get_slot(leather_boots);
        assert(leather_boots_slot == Slot::Foot(()), 'leather boots is foot slot');

        let divine_slippers = ItemId::DivineSlippers;
        let divine_slippers_slot = ImplLoot::get_slot(divine_slippers);
        assert(divine_slippers_slot == Slot::Foot(()), 'divine slippers is foot slot');

        let silk_slippers = ItemId::SilkSlippers;
        let silk_slippers_slot = ImplLoot::get_slot(silk_slippers);
        assert(silk_slippers_slot == Slot::Foot(()), 'silk slippers is foot slot');

        let wool_shoes = ItemId::WoolShoes;
        let wool_shoes_slot = ImplLoot::get_slot(wool_shoes);
        assert(wool_shoes_slot == Slot::Foot(()), 'wool shoes is foot slot');

        let linen_shoes = ItemId::LinenShoes;
        let linen_shoes_slot = ImplLoot::get_slot(linen_shoes);
        assert(linen_shoes_slot == Slot::Foot(()), 'linen shoes is foot slot');

        let shoes = ItemId::Shoes;
        let shoes_slot = ImplLoot::get_slot(shoes);
        assert(shoes_slot == Slot::Foot(()), 'shoes is foot slot');

        // Hand
        let holy_gauntlets = ItemId::HolyGauntlets;
        let holy_gauntlets_slot = ImplLoot::get_slot(holy_gauntlets);
        assert(holy_gauntlets_slot == Slot::Hand(()), 'holy gauntlets is hand slot');

        let ornate_gauntlets = ItemId::OrnateGauntlets;
        let ornate_gauntlets_slot = ImplLoot::get_slot(ornate_gauntlets);
        assert(ornate_gauntlets_slot == Slot::Hand(()), 'ornate gauntlets is hand slot');

        let gauntlets = ItemId::Gauntlets;
        let gauntlets_slot = ImplLoot::get_slot(gauntlets);
        assert(gauntlets_slot == Slot::Hand(()), 'gauntlets is hand slot');

        let chain_gloves = ItemId::ChainGloves;
        let chain_gloves_slot = ImplLoot::get_slot(chain_gloves);
        assert(chain_gloves_slot == Slot::Hand(()), 'chain gloves is hand slot');

        let heavy_gloves = ItemId::HeavyGloves;
        let heavy_gloves_slot = ImplLoot::get_slot(heavy_gloves);
        assert(heavy_gloves_slot == Slot::Hand(()), 'heavy gloves is hand slot');

        let demons_hands = ItemId::DemonsHands;
        let demons_hands_slot = ImplLoot::get_slot(demons_hands);
        assert(demons_hands_slot == Slot::Hand(()), 'demons hands is hand slot');

        let dragonskin_gloves = ItemId::DragonskinGloves;
        let dragonskin_gloves_slot = ImplLoot::get_slot(dragonskin_gloves);
        assert(dragonskin_gloves_slot == Slot::Hand(()), 'dragonskin gloves is hand slot');

        let studded_leather_gloves = ItemId::StuddedLeatherGloves;
        let studded_leather_gloves_slot = ImplLoot::get_slot(studded_leather_gloves);
        assert(studded_leather_gloves_slot == Slot::Hand(()), 'studded leather gloves err');

        let hard_leather_gloves = ItemId::HardLeatherGloves;
        let hard_leather_gloves_slot = ImplLoot::get_slot(hard_leather_gloves);
        assert(hard_leather_gloves_slot == Slot::Hand(()), 'hard leather gloves wrong slot');

        let leather_gloves = ItemId::LeatherGloves;
        let leather_gloves_slot = ImplLoot::get_slot(leather_gloves);
        assert(leather_gloves_slot == Slot::Hand(()), 'leather gloves is hand slot');

        let divine_gloves = ItemId::DivineGloves;
        let divine_gloves_slot = ImplLoot::get_slot(divine_gloves);
        assert(divine_gloves_slot == Slot::Hand(()), 'divine gloves is hand slot');

        let silk_gloves = ItemId::SilkGloves;
        let silk_gloves_slot = ImplLoot::get_slot(silk_gloves);
        assert(silk_gloves_slot == Slot::Hand(()), 'silk gloves is hand slot');

        let wool_gloves = ItemId::WoolGloves;
        let wool_gloves_slot = ImplLoot::get_slot(wool_gloves);
        assert(wool_gloves_slot == Slot::Hand(()), 'wool gloves is hand slot');

        let linen_gloves = ItemId::LinenGloves;
        let linen_gloves_slot = ImplLoot::get_slot(linen_gloves);
        assert(linen_gloves_slot == Slot::Hand(()), 'linen gloves is hand slot');

        let gloves = ItemId::Gloves;
        let gloves_slot = ImplLoot::get_slot(gloves);
        assert(gloves_slot == Slot::Hand(()), 'gloves is hand slot');

        // Necklaces
        let necklace = ItemId::Necklace;
        let necklace_slot = ImplLoot::get_slot(necklace);
        assert(necklace_slot == Slot::Neck(()), 'necklace is necklace slot');

        let amulet = ItemId::Amulet;
        let amulet_slot = ImplLoot::get_slot(amulet);
        assert(amulet_slot == Slot::Neck(()), 'amulet is necklace slot');

        let pendant = ItemId::Pendant;
        let pendant_slot = ImplLoot::get_slot(pendant);
        assert(pendant_slot == Slot::Neck(()), 'pendant is necklace slot');

        // Rings
        let gold_ring = ItemId::GoldRing;
        let gold_ring_slot = ImplLoot::get_slot(gold_ring);
        assert(gold_ring_slot == Slot::Ring(()), 'gold ring is ring slot');

        let silver_ring = ItemId::SilverRing;
        let silver_ring_slot = ImplLoot::get_slot(silver_ring);
        assert(silver_ring_slot == Slot::Ring(()), 'silver ring is ring slot');

        let bronze_ring = ItemId::BronzeRing;
        let bronze_ring_slot = ImplLoot::get_slot(bronze_ring);
        assert(bronze_ring_slot == Slot::Ring(()), 'bronze ring is ring slot');

        let platinum_ring = ItemId::PlatinumRing;
        let platinum_ring_slot = ImplLoot::get_slot(platinum_ring);
        assert(platinum_ring_slot == Slot::Ring(()), 'platinum ring is ring slot');

        let titanium_ring = ItemId::TitaniumRing;
        let titanium_ring_slot = ImplLoot::get_slot(titanium_ring);
        assert(titanium_ring_slot == Slot::Ring(()), 'titanium ring is ring slot');
    }

    #[test]
    #[available_gas(20700)]
    fn test_get_tier_gas() {
        ImplLoot::get_tier(101);
    }

    #[test]
    #[available_gas(484600)]
    fn test_get_tier() {
        let pendant = ItemId::Pendant;
        let pendant_tier = ImplLoot::get_tier(pendant);
        assert(pendant_tier == Tier::T1(()), 'pendant is T1');

        let necklace = ItemId::Necklace;
        let necklace_tier = ImplLoot::get_tier(necklace);
        assert(necklace_tier == Tier::T1(()), 'necklace is T1');

        let amulet = ItemId::Amulet;
        let amulet_tier = ImplLoot::get_tier(amulet);
        assert(amulet_tier == Tier::T1(()), 'amulet is T1');

        let silver_ring = ItemId::SilverRing;
        let silver_ring_tier = ImplLoot::get_tier(silver_ring);
        assert(silver_ring_tier == Tier::T2(()), 'silver ring is T2');

        let bronze_ring = ItemId::BronzeRing;
        let bronze_ring_tier = ImplLoot::get_tier(bronze_ring);
        assert(bronze_ring_tier == Tier::T3(()), 'bronze ring is T3');

        let platinum_ring = ItemId::PlatinumRing;
        let platinum_ring_tier = ImplLoot::get_tier(platinum_ring);
        assert(platinum_ring_tier == Tier::T1(()), 'platinum ring is T1');

        let titanium_ring = ItemId::TitaniumRing;
        let titanium_ring_tier = ImplLoot::get_tier(titanium_ring);
        assert(titanium_ring_tier == Tier::T1(()), 'titanium ring is T1');

        let gold_ring = ItemId::GoldRing;
        let gold_ring_tier = ImplLoot::get_tier(gold_ring);
        assert(gold_ring_tier == Tier::T1(()), 'gold ring is T1');

        let ghost_wand = ItemId::GhostWand;
        let ghost_wand_tier = ImplLoot::get_tier(ghost_wand);
        assert(ghost_wand_tier == Tier::T1(()), 'ghost wand is T1');

        let grave_wand = ItemId::GraveWand;
        let grave_wand_tier = ImplLoot::get_tier(grave_wand);
        assert(grave_wand_tier == Tier::T2(()), 'grave wand is T2');

        let bone_wand = ItemId::BoneWand;
        let bone_wand_tier = ImplLoot::get_tier(bone_wand);
        assert(bone_wand_tier == Tier::T3(()), 'bone wand is T3');

        let wand = ItemId::Wand;
        let wand_tier = ImplLoot::get_tier(wand);
        assert(wand_tier == Tier::T5(()), 'wand is T5');

        let grimoire = ItemId::Grimoire;
        let grimoire_tier = ImplLoot::get_tier(grimoire);
        assert(grimoire_tier == Tier::T1(()), 'grimoire is T1');

        let chronicle = ItemId::Chronicle;
        let chronicle_tier = ImplLoot::get_tier(chronicle);
        assert(chronicle_tier == Tier::T2(()), 'chronicle is T2');

        let tome = ItemId::Tome;
        let tome_tier = ImplLoot::get_tier(tome);
        assert(tome_tier == Tier::T3(()), 'tome is T3');

        let book = ItemId::Book;
        let book_tier = ImplLoot::get_tier(book);
        assert(book_tier == Tier::T5(()), 'book is T5');

        let divine_robe_id = ItemId::DivineRobe;
        let divine_robe_tier = ImplLoot::get_tier(divine_robe_id);
        assert(divine_robe_tier == Tier::T1(()), 'divine robe is T1');

        let silk_robe_id = ItemId::SilkRobe;
        let silk_robe_tier = ImplLoot::get_tier(silk_robe_id);
        assert(silk_robe_tier == Tier::T2(()), 'silk robe is T2');

        let linen_robe_id = ItemId::LinenRobe;
        let linen_robe_tier = ImplLoot::get_tier(linen_robe_id);
        assert(linen_robe_tier == Tier::T3(()), 'linen robe is T3');

        let robe_id = ItemId::Robe;
        let robe_tier = ImplLoot::get_tier(robe_id);
        assert(robe_tier == Tier::T4(()), 'robe is T4');

        let shirt_id = ItemId::Shirt;
        let shirt_tier = ImplLoot::get_tier(shirt_id);
        assert(shirt_tier == Tier::T5(()), 'shirt is T5');

        assert(ImplLoot::get_tier(255) == Tier::None(()), 'undefined is None');
    }

    #[test]
    #[available_gas(5560)]
    fn test_get_type_gas() {
        ImplLoot::get_type(101);
    }

    #[test]
    #[available_gas(649660)]
    fn test_get_type() {
        let warhammer = ItemId::Warhammer;
        let warhammer_type = ImplLoot::get_type(warhammer);
        assert(warhammer_type == Type::Bludgeon_or_Metal(()), 'warhammer is blunt');

        let quarterstaff = ItemId::Quarterstaff;
        let quarterstaff_type = ImplLoot::get_type(quarterstaff);
        assert(quarterstaff_type == Type::Bludgeon_or_Metal(()), 'quarterstaff is blunt');

        let maul = ItemId::Maul;
        let maul_type = ImplLoot::get_type(maul);
        assert(maul_type == Type::Bludgeon_or_Metal(()), 'maul is blunt');

        let mace = ItemId::Mace;
        let mace_type = ImplLoot::get_type(mace);
        assert(mace_type == Type::Bludgeon_or_Metal(()), 'mace is blunt');

        let club = ItemId::Club;
        let club_type = ImplLoot::get_type(club);
        assert(club_type == Type::Bludgeon_or_Metal(()), 'club is blunt');

        let katana = ItemId::Katana;
        let katana_type = ImplLoot::get_type(katana);
        assert(katana_type == Type::Blade_or_Hide(()), 'katana is blade');

        let falchion = ItemId::Falchion;
        let falchion_type = ImplLoot::get_type(falchion);
        assert(falchion_type == Type::Blade_or_Hide(()), 'falchion is blade');

        let scimitar = ItemId::Scimitar;
        let scimitar_type = ImplLoot::get_type(scimitar);
        assert(scimitar_type == Type::Blade_or_Hide(()), 'scimitar is blade');

        let long_sword = ItemId::LongSword;
        let long_sword_type = ImplLoot::get_type(long_sword);
        assert(long_sword_type == Type::Blade_or_Hide(()), 'long sword is blade');

        let short_sword = ItemId::ShortSword;
        let short_sword_type = ImplLoot::get_type(short_sword);
        assert(short_sword_type == Type::Blade_or_Hide(()), 'short sword is blade');

        let ghost_wand = ItemId::GhostWand;
        let ghost_wand_type = ImplLoot::get_type(ghost_wand);
        assert(ghost_wand_type == Type::Magic_or_Cloth(()), 'ghost wand is magic');

        let grave_wand = ItemId::GraveWand;
        let grave_wand_type = ImplLoot::get_type(grave_wand);
        assert(grave_wand_type == Type::Magic_or_Cloth(()), 'grave wand is magic');

        let bone_wand = ItemId::BoneWand;
        let bone_wand_type = ImplLoot::get_type(bone_wand);
        assert(bone_wand_type == Type::Magic_or_Cloth(()), 'bone wand is magic');

        let wand = ItemId::Wand;
        let wand_type = ImplLoot::get_type(wand);
        assert(wand_type == Type::Magic_or_Cloth(()), 'wand is magic');

        let grimoire = ItemId::Grimoire;
        let grimoire_type = ImplLoot::get_type(grimoire);
        assert(grimoire_type == Type::Magic_or_Cloth(()), 'grimoire is magic');

        let chronicle = ItemId::Chronicle;
        let chronicle_type = ImplLoot::get_type(chronicle);
        assert(chronicle_type == Type::Magic_or_Cloth(()), 'chronicle is magic');

        let tome = ItemId::Tome;
        let tome_type = ImplLoot::get_type(tome);
        assert(tome_type == Type::Magic_or_Cloth(()), 'tome is magic');

        let book = ItemId::Book;
        let book_type = ImplLoot::get_type(book);
        assert(book_type == Type::Magic_or_Cloth(()), 'book is magic');

        let divine_robe = ItemId::DivineRobe;
        let divine_robe_type = ImplLoot::get_type(divine_robe);
        assert(divine_robe_type == Type::Magic_or_Cloth(()), 'divine robe is cloth');

        let silk_robe = ItemId::SilkRobe;
        let silk_robe_type = ImplLoot::get_type(silk_robe);
        assert(silk_robe_type == Type::Magic_or_Cloth(()), 'silk robe is cloth');

        let linen_robe = ItemId::LinenRobe;
        let linen_robe_type = ImplLoot::get_type(linen_robe);
        assert(linen_robe_type == Type::Magic_or_Cloth(()), 'linen robe is cloth');

        let robe = ItemId::Robe;
        let robe_type = ImplLoot::get_type(robe);
        assert(robe_type == Type::Magic_or_Cloth(()), 'robe is cloth');

        let shirt = ItemId::Shirt;
        let shirt_type = ImplLoot::get_type(shirt);
        assert(shirt_type == Type::Magic_or_Cloth(()), 'shirt is cloth');

        let demon_husk = ItemId::DemonHusk;
        let demon_husk_type = ImplLoot::get_type(demon_husk);
        assert(demon_husk_type == Type::Blade_or_Hide(()), 'demon husk is hide');

        let dragonskin_armor = ItemId::DragonskinArmor;
        let dragonskin_armor_type = ImplLoot::get_type(dragonskin_armor);
        assert(dragonskin_armor_type == Type::Blade_or_Hide(()), 'dragonskin armor is hide');

        let studded_leather_armor = ItemId::StuddedLeatherArmor;
        let studded_leather_armor_type = ImplLoot::get_type(studded_leather_armor);
        assert(
            studded_leather_armor_type == Type::Blade_or_Hide(()), 'studded leather armor is hide'
        );

        let hard_leather_armor = ItemId::HardLeatherArmor;
        let hard_leather_armor_type = ImplLoot::get_type(hard_leather_armor);
        assert(hard_leather_armor_type == Type::Blade_or_Hide(()), 'hard leather armor is hide');

        let leather_armor = ItemId::LeatherArmor;
        let leather_armor_type = ImplLoot::get_type(leather_armor);
        assert(leather_armor_type == Type::Blade_or_Hide(()), 'leather armor is hide');

        let holy_chestplate = ItemId::HolyChestplate;
        let holy_chestplate_type = ImplLoot::get_type(holy_chestplate);
        assert(holy_chestplate_type == Type::Bludgeon_or_Metal(()), 'holy chestplate is metal');

        let ornate_chestplate = ItemId::OrnateChestplate;
        let ornate_chestplate_type = ImplLoot::get_type(ornate_chestplate);
        assert(ornate_chestplate_type == Type::Bludgeon_or_Metal(()), 'ornate chestplate is metal');

        let plate_mail = ItemId::PlateMail;
        let plate_mail_type = ImplLoot::get_type(plate_mail);
        assert(plate_mail_type == Type::Bludgeon_or_Metal(()), 'plate mail is metal');

        let chain_mail = ItemId::ChainMail;
        let chain_mail_type = ImplLoot::get_type(chain_mail);
        assert(chain_mail_type == Type::Bludgeon_or_Metal(()), 'chain mail is metal');

        let ring_mail = ItemId::RingMail;
        let ring_mail_type = ImplLoot::get_type(ring_mail);
        assert(ring_mail_type == Type::Bludgeon_or_Metal(()), 'ring mail is metal');

        let ancient_helm = ItemId::AncientHelm;
        let ancient_helm_type = ImplLoot::get_type(ancient_helm);
        assert(ancient_helm_type == Type::Bludgeon_or_Metal(()), 'ancient helm is metal');

        let ornate_helm = ItemId::OrnateHelm;
        let ornate_helm_type = ImplLoot::get_type(ornate_helm);
        assert(ornate_helm_type == Type::Bludgeon_or_Metal(()), 'ornate helm is metal');

        let great_helm = ItemId::GreatHelm;
        let great_helm_type = ImplLoot::get_type(great_helm);
        assert(great_helm_type == Type::Bludgeon_or_Metal(()), 'great helm is metal');

        let full_helm = ItemId::FullHelm;
        let full_helm_type = ImplLoot::get_type(full_helm);
        assert(full_helm_type == Type::Bludgeon_or_Metal(()), 'full helm is metal');

        let helm = ItemId::Helm;
        let helm_type = ImplLoot::get_type(helm);
        assert(helm_type == Type::Bludgeon_or_Metal(()), 'helm is metal');

        let demon_crown = ItemId::DemonCrown;
        let demon_crown_type = ImplLoot::get_type(demon_crown);
        assert(demon_crown_type == Type::Blade_or_Hide(()), 'demon crown is hide');

        let dragons_crown = ItemId::DragonsCrown;
        let dragons_crown_type = ImplLoot::get_type(dragons_crown);
        assert(dragons_crown_type == Type::Blade_or_Hide(()), 'dragons crown is hide');

        let war_cap = ItemId::WarCap;
        let war_cap_type = ImplLoot::get_type(war_cap);
        assert(war_cap_type == Type::Blade_or_Hide(()), 'war cap is hide');

        let leather_cap = ItemId::LeatherCap;
        let leather_cap_type = ImplLoot::get_type(leather_cap);
        assert(leather_cap_type == Type::Blade_or_Hide(()), 'leather cap is hide');

        let cap = ItemId::Cap;
        let cap_type = ImplLoot::get_type(cap);
        assert(cap_type == Type::Blade_or_Hide(()), 'cap is hide');

        let crown = ItemId::Crown;
        let crown_type = ImplLoot::get_type(crown);
        assert(crown_type == Type::Magic_or_Cloth(()), 'crown is cloth');

        let divine_hood = ItemId::DivineHood;
        let divine_hood_type = ImplLoot::get_type(divine_hood);
        assert(divine_hood_type == Type::Magic_or_Cloth(()), 'divine hood is cloth');

        let silk_hood = ItemId::SilkHood;
        let silk_hood_type = ImplLoot::get_type(silk_hood);
        assert(silk_hood_type == Type::Magic_or_Cloth(()), 'silk hood is cloth');

        let linen_hood = ItemId::LinenHood;
        let linen_hood_type = ImplLoot::get_type(linen_hood);
        assert(linen_hood_type == Type::Magic_or_Cloth(()), 'linen hood is cloth');

        let hood = ItemId::Hood;
        let hood_type = ImplLoot::get_type(hood);
        assert(hood_type == Type::Magic_or_Cloth(()), 'hood is cloth');

        let ornate_belt = ItemId::OrnateBelt;
        let ornate_belt_type = ImplLoot::get_type(ornate_belt);
        assert(ornate_belt_type == Type::Bludgeon_or_Metal(()), 'ornate belt is metal');

        let war_belt = ItemId::WarBelt;
        let war_belt_type = ImplLoot::get_type(war_belt);
        assert(war_belt_type == Type::Bludgeon_or_Metal(()), 'war belt is metal');

        let plated_belt = ItemId::PlatedBelt;
        let plated_belt_type = ImplLoot::get_type(plated_belt);
        assert(plated_belt_type == Type::Bludgeon_or_Metal(()), 'plated belt is metal');

        let mesh_belt = ItemId::MeshBelt;
        let mesh_belt_type = ImplLoot::get_type(mesh_belt);
        assert(mesh_belt_type == Type::Bludgeon_or_Metal(()), 'mesh belt is metal');

        let heavy_belt = ItemId::HeavyBelt;
        let heavy_belt_type = ImplLoot::get_type(heavy_belt);
        assert(heavy_belt_type == Type::Bludgeon_or_Metal(()), 'heavy belt is metal');

        let demonhide_belt = ItemId::DemonhideBelt;
        let demonhide_belt_type = ImplLoot::get_type(demonhide_belt);
        assert(demonhide_belt_type == Type::Blade_or_Hide(()), 'demonhide belt is hide');

        let dragonskin_belt = ItemId::DragonskinBelt;
        let dragonskin_belt_type = ImplLoot::get_type(dragonskin_belt);
        assert(dragonskin_belt_type == Type::Blade_or_Hide(()), 'dragonskin belt is hide');

        let studded_leather_belt = ItemId::StuddedLeatherBelt;
        let studded_leather_belt_type = ImplLoot::get_type(studded_leather_belt);
        assert(
            studded_leather_belt_type == Type::Blade_or_Hide(()), 'studded leather belt is hide'
        );

        let hard_leather_belt = ItemId::HardLeatherBelt;
        let hard_leather_belt_type = ImplLoot::get_type(hard_leather_belt);
        assert(hard_leather_belt_type == Type::Blade_or_Hide(()), 'hard leather belt is hide');

        let leather_belt = ItemId::LeatherBelt;
        let leather_belt_type = ImplLoot::get_type(leather_belt);
        assert(leather_belt_type == Type::Blade_or_Hide(()), 'leather belt is hide');

        let brightsilk_sash = ItemId::BrightsilkSash;
        let brightsilk_sash_type = ImplLoot::get_type(brightsilk_sash);
        assert(brightsilk_sash_type == Type::Magic_or_Cloth(()), 'brightsilk sash is cloth');

        let silk_sash = ItemId::SilkSash;
        let silk_sash_type = ImplLoot::get_type(silk_sash);
        assert(silk_sash_type == Type::Magic_or_Cloth(()), 'silk sash is cloth');

        let wool_sash = ItemId::WoolSash;
        let wool_sash_type = ImplLoot::get_type(wool_sash);
        assert(wool_sash_type == Type::Magic_or_Cloth(()), 'wool sash is cloth');

        let linen_sash = ItemId::LinenSash;
        let linen_sash_type = ImplLoot::get_type(linen_sash);
        assert(linen_sash_type == Type::Magic_or_Cloth(()), 'linen sash is cloth');

        let sash = ItemId::Sash;
        let sash_type = ImplLoot::get_type(sash);
        assert(sash_type == Type::Magic_or_Cloth(()), 'sash is cloth');

        let holy_greaves = ItemId::HolyGreaves;
        let holy_greaves_type = ImplLoot::get_type(holy_greaves);
        assert(holy_greaves_type == Type::Bludgeon_or_Metal(()), 'holy greaves is metal');

        let ornate_greaves = ItemId::OrnateGreaves;
        let ornate_greaves_type = ImplLoot::get_type(ornate_greaves);
        assert(ornate_greaves_type == Type::Bludgeon_or_Metal(()), 'ornate greaves is metal');

        let greaves = ItemId::Greaves;
        let greaves_type = ImplLoot::get_type(greaves);
        assert(greaves_type == Type::Bludgeon_or_Metal(()), 'greaves is metal');

        let chain_boots = ItemId::ChainBoots;
        let chain_boots_type = ImplLoot::get_type(chain_boots);
        assert(chain_boots_type == Type::Bludgeon_or_Metal(()), 'chain boots is metal');

        let heavy_boots = ItemId::HeavyBoots;
        let heavy_boots_type = ImplLoot::get_type(heavy_boots);
        assert(heavy_boots_type == Type::Bludgeon_or_Metal(()), 'heavy boots is metal');

        let demonhide_boots = ItemId::DemonhideBoots;
        let demonhide_boots_type = ImplLoot::get_type(demonhide_boots);
        assert(demonhide_boots_type == Type::Blade_or_Hide(()), 'demonhide boots is hide');

        let dragonskin_boots = ItemId::DragonskinBoots;
        let dragonskin_boots_type = ImplLoot::get_type(dragonskin_boots);
        assert(dragonskin_boots_type == Type::Blade_or_Hide(()), 'dragonskin boots is hide');

        let studded_leather_boots = ItemId::StuddedLeatherBoots;
        let studded_leather_boots_type = ImplLoot::get_type(studded_leather_boots);
        assert(
            studded_leather_boots_type == Type::Blade_or_Hide(()), 'studded leather boots is hide'
        );

        let hard_leather_boots = ItemId::HardLeatherBoots;
        let hard_leather_boots_type = ImplLoot::get_type(hard_leather_boots);
        assert(hard_leather_boots_type == Type::Blade_or_Hide(()), 'hard leather boots is hide');

        let leather_boots = ItemId::LeatherBoots;
        let leather_boots_type = ImplLoot::get_type(leather_boots);
        assert(leather_boots_type == Type::Blade_or_Hide(()), 'leather boots is hide');

        let divine_slippers = ItemId::DivineSlippers;
        let divine_slippers_type = ImplLoot::get_type(divine_slippers);
        assert(divine_slippers_type == Type::Magic_or_Cloth(()), 'divine slippers is cloth');

        let silk_slippers = ItemId::SilkSlippers;
        let silk_slippers_type = ImplLoot::get_type(silk_slippers);
        assert(silk_slippers_type == Type::Magic_or_Cloth(()), 'silk slippers is cloth');

        let wool_shoes = ItemId::WoolShoes;
        let wool_shoes_type = ImplLoot::get_type(wool_shoes);
        assert(wool_shoes_type == Type::Magic_or_Cloth(()), 'wool shoes is cloth');

        let linen_shoes = ItemId::LinenShoes;
        let linen_shoes_type = ImplLoot::get_type(linen_shoes);
        assert(linen_shoes_type == Type::Magic_or_Cloth(()), 'linen shoes is cloth');

        let shoes = ItemId::Shoes;
        let shoes_type = ImplLoot::get_type(shoes);
        assert(shoes_type == Type::Magic_or_Cloth(()), 'shoes is cloth');

        let holy_gauntlets = ItemId::HolyGauntlets;
        let holy_gauntlets_type = ImplLoot::get_type(holy_gauntlets);
        assert(holy_gauntlets_type == Type::Bludgeon_or_Metal(()), 'holy gauntlets is metal');

        let ornate_gauntlets = ItemId::OrnateGauntlets;
        let ornate_gauntlets_type = ImplLoot::get_type(ornate_gauntlets);
        assert(ornate_gauntlets_type == Type::Bludgeon_or_Metal(()), 'ornate gauntlets is metal');

        let gauntlets = ItemId::Gauntlets;
        let gauntlets_type = ImplLoot::get_type(gauntlets);
        assert(gauntlets_type == Type::Bludgeon_or_Metal(()), 'gauntlets is metal');

        let chain_gloves = ItemId::ChainGloves;
        let chain_gloves_type = ImplLoot::get_type(chain_gloves);
        assert(chain_gloves_type == Type::Bludgeon_or_Metal(()), 'chain gloves is metal');

        let heavy_gloves = ItemId::HeavyGloves;
        let heavy_gloves_type = ImplLoot::get_type(heavy_gloves);
        assert(heavy_gloves_type == Type::Bludgeon_or_Metal(()), 'heavy gloves is metal');

        let demons_hands = ItemId::DemonsHands;
        let demons_hands_type = ImplLoot::get_type(demons_hands);
        assert(demons_hands_type == Type::Blade_or_Hide(()), 'demons hands is hide');

        let dragonskin_gloves = ItemId::DragonskinGloves;
        let dragonskin_gloves_type = ImplLoot::get_type(dragonskin_gloves);
        assert(dragonskin_gloves_type == Type::Blade_or_Hide(()), 'dragonskin gloves is hide');

        let studded_leather_gloves = ItemId::StuddedLeatherGloves;
        let studded_leather_gloves_type = ImplLoot::get_type(studded_leather_gloves);
        assert(
            studded_leather_gloves_type == Type::Blade_or_Hide(()), 'studded leather gloves is hide'
        );

        let hard_leather_gloves = ItemId::HardLeatherGloves;
        let hard_leather_gloves_type = ImplLoot::get_type(hard_leather_gloves);
        assert(hard_leather_gloves_type == Type::Blade_or_Hide(()), 'hard leather gloves is hide');

        let leather_gloves = ItemId::LeatherGloves;
        let leather_gloves_type = ImplLoot::get_type(leather_gloves);
        assert(leather_gloves_type == Type::Blade_or_Hide(()), 'leather gloves is hide');

        let necklace = ItemId::Necklace;
        let necklace_type = ImplLoot::get_type(necklace);
        assert(necklace_type == Type::Necklace(()), 'necklace is necklace');

        let amulet = ItemId::Amulet;
        let amulet_type = ImplLoot::get_type(amulet);
        assert(amulet_type == Type::Necklace(()), 'amulet is necklace');

        let pendant = ItemId::Pendant;
        let pendant_type = ImplLoot::get_type(pendant);
        assert(pendant_type == Type::Necklace(()), 'pendant is necklace');

        let gold_ring = ItemId::GoldRing;
        let gold_ring_type = ImplLoot::get_type(gold_ring);
        assert(gold_ring_type == Type::Ring(()), 'gold ring is ring');

        let silver_ring = ItemId::SilverRing;
        let silver_ring_type = ImplLoot::get_type(silver_ring);
        assert(silver_ring_type == Type::Ring(()), 'silver ring is ring');

        let bronze_ring = ItemId::BronzeRing;
        let bronze_ring_type = ImplLoot::get_type(bronze_ring);
        assert(bronze_ring_type == Type::Ring(()), 'bronze ring is ring');

        let platinum_ring = ItemId::PlatinumRing;
        let platinum_ring_type = ImplLoot::get_type(platinum_ring);
        assert(platinum_ring_type == Type::Ring(()), 'platinum ring is ring');

        let titanium_ring = ItemId::TitaniumRing;
        let titanium_ring_type = ImplLoot::get_type(titanium_ring);
        assert(titanium_ring_type == Type::Ring(()), 'titanium ring is ring');
    }

    #[test]
    #[available_gas(2772740)]
    fn test_get_item_verify_tier() {
        let t1_items = array![
            ItemId::Necklace,
            ItemId::Pendant,
            ItemId::Amulet,
            ItemId::PlatinumRing,
            ItemId::TitaniumRing,
            ItemId::GoldRing,
            ItemId::GhostWand,
            ItemId::Grimoire,
            ItemId::DivineRobe,
            ItemId::Crown,
            ItemId::BrightsilkSash,
            ItemId::DivineSlippers,
            ItemId::DivineGloves,
            ItemId::Katana,
            ItemId::DemonHusk,
            ItemId::DemonCrown,
            ItemId::DemonhideBelt,
            ItemId::DemonsHands,
            ItemId::DemonhideBoots,
            ItemId::Warhammer,
            ItemId::HolyChestplate,
            ItemId::AncientHelm,
            ItemId::HolyGreaves,
            ItemId::HolyGauntlets
        ];

        let mut item_index = 0;
        loop {
            if item_index == t1_items.len() {
                break;
            }
            let item_id = *t1_items.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.tier == Tier::T1(()), 'item is tier 1');
            item_index += 1;
        };

        let t2_items = array![
            ItemId::SilverRing,
            ItemId::Falchion,
            ItemId::Quarterstaff,
            ItemId::GraveWand,
            ItemId::Chronicle,
            ItemId::SilkRobe,
            ItemId::DivineHood,
            ItemId::SilkSash,
            ItemId::SilkSlippers,
            ItemId::SilkGloves,
            ItemId::DragonsCrown,
            ItemId::DragonskinBelt,
            ItemId::DragonskinBoots,
            ItemId::DragonskinArmor,
            ItemId::OrnateChestplate,
            ItemId::WarBelt,
            ItemId::OrnateHelm,
            ItemId::OrnateGreaves,
            ItemId::OrnateGauntlets,
        ];

        let mut item_index = 0;
        loop {
            if item_index == t2_items.len() {
                break;
            }
            let item_id = *t2_items.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.tier == Tier::T2(()), 'item is tier 2');
            item_index += 1;
        };

        let t3_items = array![
            ItemId::LinenRobe,
            ItemId::SilkHood,
            ItemId::WoolSash,
            ItemId::WoolShoes,
            ItemId::WoolGloves,
            ItemId::Scimitar,
            ItemId::StuddedLeatherArmor,
            ItemId::WarCap,
            ItemId::Greaves,
            ItemId::Gauntlets,
            ItemId::Scimitar,
            ItemId::StuddedLeatherBoots,
            ItemId::Maul,
            ItemId::PlateMail,
            ItemId::GreatHelm,
            ItemId::PlatedBelt,
        ];

        let mut item_index = 0;
        loop {
            if item_index == t3_items.len() {
                break;
            }
            let item_id = *t3_items.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.tier == Tier::T3(()), 'item is tier 3');
            item_index += 1;
        };

        let t4_items = array![
            ItemId::HardLeatherBelt,
            ItemId::HardLeatherBoots,
            ItemId::HardLeatherArmor,
            ItemId::LeatherCap,
            ItemId::HardLeatherGloves,
            ItemId::LongSword,
            ItemId::ChainMail,
            ItemId::FullHelm,
            ItemId::ChainBoots,
            ItemId::ChainGloves,
            ItemId::Mace,
        ];

        let mut item_index = 0;
        loop {
            if item_index == t4_items.len() {
                break;
            }
            let item_id = *t4_items.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.tier == Tier::T4(()), 'item is tier 4');
            item_index += 1;
        };

        let t5_items = array![
            ItemId::Cap,
            ItemId::Club,
            ItemId::Sash,
            ItemId::Helm,
            ItemId::Shirt,
            ItemId::Shoes,
            ItemId::Gloves,
            ItemId::RingMail,
            ItemId::HeavyBoots,
            ItemId::HeavyBelt,
            ItemId::ShortSword,
            ItemId::HeavyGloves,
            ItemId::LeatherBelt,
            ItemId::LeatherBoots,
        ];

        let mut item_index = 0;
        loop {
            if item_index == t5_items.len() {
                break;
            }
            let item_id = *t5_items.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.tier == Tier::T5(()), 'item is tier 5');
            item_index += 1;
        };
    }

    #[test]
    #[available_gas(2829820)]
    fn test_get_item_verify_type() {
        let magic = array![
            ItemId::GhostWand,
            ItemId::GraveWand,
            ItemId::BoneWand,
            ItemId::Wand,
            ItemId::Grimoire,
            ItemId::Chronicle,
            ItemId::Tome,
            ItemId::Book,
            ItemId::DivineRobe,
            ItemId::SilkRobe,
            ItemId::LinenRobe,
            ItemId::Robe,
            ItemId::Shirt,
            ItemId::Crown,
            ItemId::DivineHood,
            ItemId::SilkHood,
            ItemId::LinenHood,
            ItemId::Hood,
            ItemId::BrightsilkSash,
            ItemId::SilkSash,
            ItemId::WoolSash,
            ItemId::LinenSash,
            ItemId::Sash,
            ItemId::DivineSlippers,
            ItemId::SilkSlippers,
            ItemId::WoolShoes,
            ItemId::LinenShoes,
            ItemId::Shoes,
            ItemId::DivineGloves,
            ItemId::SilkGloves,
            ItemId::WoolGloves,
            ItemId::LinenGloves,
            ItemId::Gloves
        ];

        let mut item_index = 0;
        loop {
            if item_index == magic.len() {
                break;
            }
            let item_id = *magic.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.item_type == Type::Magic_or_Cloth(()), 'item is magic');
            item_index += 1;
        };

        let blades_and_hide = array![
            ItemId::Katana,
            ItemId::Falchion,
            ItemId::Scimitar,
            ItemId::LongSword,
            ItemId::ShortSword,
            ItemId::DemonHusk,
            ItemId::DragonskinArmor,
            ItemId::StuddedLeatherArmor,
            ItemId::HardLeatherArmor,
            ItemId::LeatherArmor,
            ItemId::DemonCrown,
            ItemId::DragonsCrown,
            ItemId::WarCap,
            ItemId::LeatherCap,
            ItemId::Cap,
            ItemId::DemonhideBelt,
            ItemId::DragonskinBelt,
            ItemId::StuddedLeatherBelt,
            ItemId::HardLeatherBelt,
            ItemId::LeatherBelt,
            ItemId::DemonhideBoots,
            ItemId::DragonskinBoots,
            ItemId::StuddedLeatherBoots,
            ItemId::HardLeatherBoots,
            ItemId::LeatherBoots,
            ItemId::DemonsHands,
            ItemId::DragonskinGloves,
            ItemId::StuddedLeatherGloves,
            ItemId::HardLeatherGloves,
            ItemId::LeatherGloves
        ];

        let mut item_index = 0;
        loop {
            if item_index == blades_and_hide.len() {
                break;
            }
            let item_id = *blades_and_hide.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.item_type == Type::Blade_or_Hide(()), 'item is blade or hide');
            item_index += 1;
        };

        let bludgeon_and_metal = array![
            ItemId::Warhammer,
            ItemId::Quarterstaff,
            ItemId::Maul,
            ItemId::Mace,
            ItemId::Club,
            ItemId::HolyChestplate,
            ItemId::OrnateChestplate,
            ItemId::PlateMail,
            ItemId::ChainMail,
            ItemId::RingMail,
            ItemId::AncientHelm,
            ItemId::OrnateHelm,
            ItemId::GreatHelm,
            ItemId::FullHelm,
            ItemId::Helm,
            ItemId::HolyGreaves,
            ItemId::OrnateGreaves,
            ItemId::Greaves,
            ItemId::ChainBoots,
            ItemId::HeavyBoots,
            ItemId::HolyGauntlets,
            ItemId::OrnateGauntlets,
            ItemId::Gauntlets,
            ItemId::ChainGloves,
            ItemId::HeavyGloves
        ];

        let mut item_index = 0;
        loop {
            if item_index == bludgeon_and_metal.len() {
                break;
            }
            let item_id = *bludgeon_and_metal.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.item_type == Type::Bludgeon_or_Metal(()), 'item is bludgeon or metal');
            item_index += 1;
        };
    }

    #[test]
    #[available_gas(2961270)]
    fn test_get_item_verify_slot() {
        let weapons = array![
            ItemId::GhostWand,
            ItemId::GraveWand,
            ItemId::BoneWand,
            ItemId::Wand,
            ItemId::Katana,
            ItemId::Falchion,
            ItemId::Scimitar,
            ItemId::LongSword,
            ItemId::ShortSword,
            ItemId::Warhammer,
            ItemId::Quarterstaff,
            ItemId::Maul,
            ItemId::Mace,
            ItemId::Club
        ];

        let mut item_index = 0;
        loop {
            if item_index == weapons.len() {
                break;
            }
            let item_id = *weapons.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.slot == Slot::Weapon(()), 'item is a weapon');
            item_index += 1;
        };

        let chest_armor = array![
            ItemId::DivineRobe,
            ItemId::SilkRobe,
            ItemId::LinenRobe,
            ItemId::Robe,
            ItemId::Shirt,
            ItemId::DemonHusk,
            ItemId::DragonskinArmor,
            ItemId::StuddedLeatherArmor,
            ItemId::HardLeatherArmor,
            ItemId::LeatherArmor,
            ItemId::HolyChestplate,
            ItemId::OrnateChestplate,
            ItemId::PlateMail,
            ItemId::ChainMail,
            ItemId::RingMail
        ];

        let mut item_index = 0;
        loop {
            if item_index == chest_armor.len() {
                break;
            }
            let item_id = *chest_armor.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.slot == Slot::Chest(()), 'item is chest armor');
            item_index += 1;
        };

        let head_armor = array![
            ItemId::Crown,
            ItemId::DivineHood,
            ItemId::SilkHood,
            ItemId::LinenHood,
            ItemId::Hood,
            ItemId::DemonCrown,
            ItemId::DragonsCrown,
            ItemId::WarCap,
            ItemId::LeatherCap,
            ItemId::Cap,
            ItemId::AncientHelm,
            ItemId::OrnateHelm,
            ItemId::GreatHelm,
            ItemId::FullHelm,
            ItemId::Helm
        ];
        let mut item_index = 0;
        loop {
            if item_index == head_armor.len() {
                break;
            }
            let item_id = *head_armor.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.slot == Slot::Head(()), 'item is head armor');
            item_index += 1;
        };

        let waist_armor_items = array![
            ItemId::BrightsilkSash,
            ItemId::SilkSash,
            ItemId::WoolSash,
            ItemId::LinenSash,
            ItemId::Sash,
            ItemId::DemonhideBelt,
            ItemId::DragonskinBelt,
            ItemId::StuddedLeatherBelt,
            ItemId::HardLeatherBelt,
            ItemId::LeatherBelt,
            ItemId::OrnateBelt,
            ItemId::WarBelt,
            ItemId::PlatedBelt,
            ItemId::MeshBelt,
            ItemId::HeavyBelt
        ];
        let mut item_index = 0;
        loop {
            if item_index == waist_armor_items.len() {
                break;
            }
            let item_id = *waist_armor_items.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.slot == Slot::Waist(()), 'item is waist armor');
            item_index += 1;
        };

        let hand_armor_items = array![
            ItemId::DivineGloves,
            ItemId::SilkGloves,
            ItemId::WoolGloves,
            ItemId::LinenGloves,
            ItemId::Gloves,
            ItemId::DemonsHands,
            ItemId::DragonskinGloves,
            ItemId::StuddedLeatherGloves,
            ItemId::HardLeatherGloves,
            ItemId::LeatherGloves,
            ItemId::HolyGauntlets,
            ItemId::OrnateGauntlets,
            ItemId::Gauntlets,
            ItemId::ChainGloves,
            ItemId::HeavyGloves
        ];
        let mut item_index = 0;
        loop {
            if item_index == hand_armor_items.len() {
                break;
            }
            let item_id = *hand_armor_items.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.slot == Slot::Hand(()), 'item is hand armor');
            item_index += 1;
        };

        let foot_armor_items = array![
            ItemId::DivineSlippers,
            ItemId::SilkSlippers,
            ItemId::WoolShoes,
            ItemId::LinenShoes,
            ItemId::Shoes,
            ItemId::DemonhideBoots,
            ItemId::DragonskinBoots,
            ItemId::StuddedLeatherBoots,
            ItemId::HardLeatherBoots,
            ItemId::LeatherBoots,
            ItemId::HolyGreaves,
            ItemId::OrnateGreaves,
            ItemId::Greaves,
            ItemId::ChainBoots,
            ItemId::HeavyBoots
        ];

        let mut item_index = 0;
        loop {
            if item_index == foot_armor_items.len() {
                break;
            }
            let item_id = *foot_armor_items.at(item_index);
            let item = ImplLoot::get_item(item_id);
            assert(item.slot == Slot::Foot(()), 'item is foot armor');
            item_index += 1;
        }
    }

    // iterate over all 101 items and make sure none are missing
    #[test]
    #[available_gas(2658950)]
    fn test_get_item_range_check() {
        let mut item_index = 1;
        loop {
            if item_index == 102 {
                break;
            }
            ImplLoot::get_item(item_index);
            item_index += 1;
        }
    }

    #[test]
    #[available_gas(26100)]
    fn test_get_item_zero() {
        let item = ImplLoot::get_item(102);
        assert(item.id == 0, 'item id is 0');
        assert(item.tier == Tier::None(()), 'item is tier none');
        assert(item.slot == Slot::None(()), 'item is slot none');
        assert(item.item_type == Type::None(()), 'item is type none');
    }

    #[test]
    #[available_gas(26100)]
    fn test_get_item_out_of_bounds() {
        let item = ImplLoot::get_item(102);
        assert(item.id == 0, 'item id is 0');
        assert(item.tier == Tier::None(()), 'item is tier none');
        assert(item.slot == Slot::None(()), 'item is slot none');
        assert(item.item_type == Type::None(()), 'item is type none');
    }

    #[test]
    #[available_gas(26100)]
    fn test_get_item_max_value() {
        let item = ImplLoot::get_item(102);
        assert(item.id == 0, 'item id is 0');
        assert(item.tier == Tier::None(()), 'item is tier none');
        assert(item.slot == Slot::None(()), 'item is slot none');
        assert(item.item_type == Type::None(()), 'item is type none');
    }
}
