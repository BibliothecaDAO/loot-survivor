mod NameUtils {
    use lootitems::constants::{ItemNameSuffix, ItemSuffix, ItemId};

    fn is_special3_set1(name: u8) -> bool {
        (name == ItemNameSuffix::Bane
            || name == ItemNameSuffix::Song
            || name == ItemNameSuffix::Instrument
            || name == ItemNameSuffix::Shadow
            || name == ItemNameSuffix::Growl
            || name == ItemNameSuffix::Form)
    }

    fn is_special3_set2(name: u8) -> bool {
        (name == ItemNameSuffix::Root
            || name == ItemNameSuffix::Roar
            || name == ItemNameSuffix::Glow
            || name == ItemNameSuffix::Whisper
            || name == ItemNameSuffix::Tear
            || name == ItemNameSuffix::Sun)
    }

    fn is_special3_set3(name: u8) -> bool {
        (name == ItemNameSuffix::Bite
            || name == ItemNameSuffix::Grasp
            || name == ItemNameSuffix::Bender
            || name == ItemNameSuffix::Shout
            || name == ItemNameSuffix::Peak
            || name == ItemNameSuffix::Moon)
    }

    fn is_special2_set1(name: u8) -> bool {
        if name < 1 || name > 69 {
            false
        } else {
            (name - 1) % 3 == 0
        }
    }

    fn is_special2_set2(name: u8) -> bool {
        if name < 2 || name > 69 {
            false
        } else {
            (name - 2) % 3 == 0
        }
    }

    fn is_special2_set3(name: u8) -> bool {
        if name < 3 || name > 69 {
            false
        } else {
            (name - 3) % 3 == 0
        }
    }

    // the item suffix is the suffix of the item such as "of Power"
    fn is_special1_set1(name: u8) -> bool {
        name == ItemSuffix::of_Power
            || name == ItemSuffix::of_Titans
            || name == ItemSuffix::of_Perfection
            || name == ItemSuffix::of_Enlightenment
            || name == ItemSuffix::of_Anger
            || name == ItemSuffix::of_Fury
            || name == ItemSuffix::of_the_Fox
            || name == ItemSuffix::of_Reflection
    }

    fn is_special1_set2(name: u8) -> bool {
        name == ItemSuffix::of_Giant
            || name == ItemSuffix::of_Skill
            || name == ItemSuffix::of_Brilliance
            || name == ItemSuffix::of_Protection
            || name == ItemSuffix::of_Rage
            || name == ItemSuffix::of_Vitriol
            || name == ItemSuffix::of_Detection
            || name == ItemSuffix::of_the_Twins
    }
}

mod ItemUtils {
    use lootitems::{loot::Loot, constants::{ItemNameSuffix, ItemSuffix, ItemId}};
    use combat::constants::CombatEnums::{Type, Tier, Slot};


    #[inline(always)]
    fn is_necklace(id: u8) -> bool {
        id < ItemId::SilverRing
    }

    #[inline(always)]
    fn is_ring(id: u8) -> bool {
        id > ItemId::Amulet && id < ItemId::GhostWand
    }

    #[inline(always)]
    fn is_weapon(id: u8) -> bool {
        (id > ItemId::GoldRing && id < ItemId::DivineRobe)
            || (id > ItemId::Gloves && id < ItemId::DemonHusk)
            || (id > ItemId::LeatherGloves && id < ItemId::HolyChestplate)
    }

    #[inline(always)]
    fn is_chest_armor(id: u8) -> bool {
        (id > ItemId::Book && id < ItemId::Crown)
            || (id > ItemId::ShortSword && id < ItemId::DemonCrown)
            || (id > ItemId::Club && id < ItemId::AncientHelm)
    }

    #[inline(always)]
    fn is_head_armor(id: u8) -> bool {
        (id > ItemId::Shirt && id < ItemId::BrightsilkSash)
            || (id > ItemId::LeatherArmor && id < ItemId::DemonhideBelt)
            || (id > ItemId::RingMail && id < ItemId::OrnateBelt)
    }

    #[inline(always)]
    fn is_waist_armor(id: u8) -> bool {
        (id > ItemId::Hood && id < ItemId::DivineSlippers)
            || (id > ItemId::Cap && id < ItemId::DemonhideBoots)
            || (id > ItemId::Helm && id < ItemId::HolyGreaves)
    }

    #[inline(always)]
    fn is_hand_armor(id: u8) -> bool {
        (id > ItemId::Shoes && id < ItemId::Katana)
            || (id > ItemId::LeatherBoots && id < ItemId::Warhammer)
            || (id > ItemId::HeavyBoots)
    }

    #[inline(always)]
    fn is_foot_armor(id: u8) -> bool {
        (id > ItemId::Sash && id < ItemId::DivineGloves)
            || (id > ItemId::LeatherBelt && id < ItemId::DemonsHands)
            || (id > ItemId::HeavyBelt && id < ItemId::HolyGauntlets)
    }
    #[inline(always)]
    fn is_magic_or_cloth(id: u8) -> bool {
        (id > ItemId::GoldRing && id < ItemId::Katana)
    }
    #[inline(always)]
    fn is_blade_or_hide(id: u8) -> bool {
        (id > ItemId::Gloves && id < ItemId::Warhammer)
    }
    #[inline(always)]
    fn is_bludgeon_or_metal(id: u8) -> bool {
        id > ItemId::LeatherGloves
    }

    #[inline(always)]
    fn get_pendant() -> Loot {
        Loot {
            id: ItemId::Pendant,
            tier: Tier::T1(()),
            item_type: Type::Necklace(()),
            slot: Slot::Neck(())
        }
    }
    #[inline(always)]
    fn get_necklace() -> Loot {
        Loot {
            id: ItemId::Necklace,
            tier: Tier::T1(()),
            item_type: Type::Necklace(()),
            slot: Slot::Neck(())
        }
    }
    #[inline(always)]
    fn get_amulet() -> Loot {
        Loot {
            id: ItemId::Amulet,
            tier: Tier::T1(()),
            item_type: Type::Necklace(()),
            slot: Slot::Neck(())
        }
    }
    #[inline(always)]
    fn get_bronze_ring() -> Loot {
        Loot {
            id: ItemId::BronzeRing,
            tier: Tier::T3(()),
            item_type: Type::Ring(()),
            slot: Slot::Ring(())
        }
    }
    #[inline(always)]
    fn get_silver_ring() -> Loot {
        Loot {
            id: ItemId::SilverRing,
            tier: Tier::T2(()),
            item_type: Type::Ring(()),
            slot: Slot::Ring(())
        }
    }
    #[inline(always)]
    fn get_gold_ring() -> Loot {
        Loot {
            id: ItemId::GoldRing,
            tier: Tier::T1(()),
            item_type: Type::Ring(()),
            slot: Slot::Ring(())
        }
    }
    #[inline(always)]
    fn get_platinum_ring() -> Loot {
        Loot {
            id: ItemId::PlatinumRing,
            tier: Tier::T1(()),
            item_type: Type::Ring(()),
            slot: Slot::Ring(())
        }
    }
    #[inline(always)]
    fn get_titanium_ring() -> Loot {
        Loot {
            id: ItemId::TitaniumRing,
            tier: Tier::T1(()),
            item_type: Type::Ring(()),
            slot: Slot::Ring(())
        }
    }
    #[inline(always)]
    fn get_ghost_wand() -> Loot {
        Loot {
            id: ItemId::GhostWand,
            tier: Tier::T1(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_grave_wand() -> Loot {
        Loot {
            id: ItemId::GraveWand,
            tier: Tier::T2(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_bone_wand() -> Loot {
        Loot {
            id: ItemId::BoneWand,
            tier: Tier::T3(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_wand() -> Loot {
        Loot {
            id: ItemId::Wand,
            tier: Tier::T5(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_grimoire() -> Loot {
        Loot {
            id: ItemId::Grimoire,
            tier: Tier::T1(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_chronicle() -> Loot {
        Loot {
            id: ItemId::Chronicle,
            tier: Tier::T2(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_tome() -> Loot {
        Loot {
            id: ItemId::Tome,
            tier: Tier::T3(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_book() -> Loot {
        Loot {
            id: ItemId::Book,
            tier: Tier::T5(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_divine_robe() -> Loot {
        Loot {
            id: ItemId::DivineRobe,
            tier: Tier::T1(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_silk_robe() -> Loot {
        Loot {
            id: ItemId::SilkRobe,
            tier: Tier::T2(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_linen_robe() -> Loot {
        Loot {
            id: ItemId::LinenRobe,
            tier: Tier::T3(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_robe() -> Loot {
        Loot {
            id: ItemId::Robe,
            tier: Tier::T4(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_shirt() -> Loot {
        Loot {
            id: ItemId::Shirt,
            tier: Tier::T5(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_crown() -> Loot {
        Loot {
            id: ItemId::Crown,
            tier: Tier::T1(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_divine_hood() -> Loot {
        Loot {
            id: ItemId::DivineHood,
            tier: Tier::T2(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_silk_hood() -> Loot {
        Loot {
            id: ItemId::SilkHood,
            tier: Tier::T3(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_linen_hood() -> Loot {
        Loot {
            id: ItemId::LinenHood,
            tier: Tier::T4(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_hood() -> Loot {
        Loot {
            id: ItemId::Hood,
            tier: Tier::T5(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_brightsilk_sash() -> Loot {
        Loot {
            id: ItemId::BrightsilkSash,
            tier: Tier::T1(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_silk_sash() -> Loot {
        Loot {
            id: ItemId::SilkSash,
            tier: Tier::T2(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_wool_sash() -> Loot {
        Loot {
            id: ItemId::WoolSash,
            tier: Tier::T3(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_linen_sash() -> Loot {
        Loot {
            id: ItemId::LinenSash,
            tier: Tier::T4(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_sash() -> Loot {
        Loot {
            id: ItemId::Sash,
            tier: Tier::T5(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_divine_slippers() -> Loot {
        Loot {
            id: ItemId::DivineSlippers,
            tier: Tier::T1(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_silk_slippers() -> Loot {
        Loot {
            id: ItemId::SilkSlippers,
            tier: Tier::T2(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_wool_shoes() -> Loot {
        Loot {
            id: ItemId::WoolShoes,
            tier: Tier::T3(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_linen_shoes() -> Loot {
        Loot {
            id: ItemId::LinenShoes,
            tier: Tier::T4(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_shoes() -> Loot {
        Loot {
            id: ItemId::Shoes,
            tier: Tier::T5(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_divine_gloves() -> Loot {
        Loot {
            id: ItemId::DivineGloves,
            tier: Tier::T1(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_silk_gloves() -> Loot {
        Loot {
            id: ItemId::SilkGloves,
            tier: Tier::T2(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_wool_gloves() -> Loot {
        Loot {
            id: ItemId::WoolGloves,
            tier: Tier::T3(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_linen_gloves() -> Loot {
        Loot {
            id: ItemId::LinenGloves,
            tier: Tier::T4(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_gloves() -> Loot {
        Loot {
            id: ItemId::Gloves,
            tier: Tier::T5(()),
            item_type: Type::Magic_or_Cloth(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_katana() -> Loot {
        Loot {
            id: ItemId::Katana,
            tier: Tier::T1(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_falchion() -> Loot {
        Loot {
            id: ItemId::Falchion,
            tier: Tier::T2(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_scimitar() -> Loot {
        Loot {
            id: ItemId::Scimitar,
            tier: Tier::T3(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_long_sword() -> Loot {
        Loot {
            id: ItemId::LongSword,
            tier: Tier::T4(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_short_sword() -> Loot {
        Loot {
            id: ItemId::ShortSword,
            tier: Tier::T5(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_demon_husk() -> Loot {
        Loot {
            id: ItemId::DemonHusk,
            tier: Tier::T1(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_dragonskin_armor() -> Loot {
        Loot {
            id: ItemId::DragonskinArmor,
            tier: Tier::T2(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_studded_leather_armor() -> Loot {
        Loot {
            id: ItemId::StuddedLeatherArmor,
            tier: Tier::T3(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_hard_leather_armor() -> Loot {
        Loot {
            id: ItemId::HardLeatherArmor,
            tier: Tier::T4(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_leather_armor() -> Loot {
        Loot {
            id: ItemId::LeatherArmor,
            tier: Tier::T5(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_demon_crown() -> Loot {
        Loot {
            id: ItemId::DemonCrown,
            tier: Tier::T1(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_dragons_crown() -> Loot {
        Loot {
            id: ItemId::DragonsCrown,
            tier: Tier::T2(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_war_cap() -> Loot {
        Loot {
            id: ItemId::WarCap,
            tier: Tier::T3(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_leather_cap() -> Loot {
        Loot {
            id: ItemId::LeatherCap,
            tier: Tier::T4(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_cap() -> Loot {
        Loot {
            id: ItemId::Cap,
            tier: Tier::T5(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_demonhide_belt() -> Loot {
        Loot {
            id: ItemId::DemonhideBelt,
            tier: Tier::T1(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_dragonskin_belt() -> Loot {
        Loot {
            id: ItemId::DragonskinBelt,
            tier: Tier::T2(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_studded_leather_belt() -> Loot {
        Loot {
            id: ItemId::StuddedLeatherBelt,
            tier: Tier::T3(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_hard_leather_belt() -> Loot {
        Loot {
            id: ItemId::HardLeatherBelt,
            tier: Tier::T4(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_leather_belt() -> Loot {
        Loot {
            id: ItemId::LeatherBelt,
            tier: Tier::T5(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_demonhide_boots() -> Loot {
        Loot {
            id: ItemId::DemonhideBoots,
            tier: Tier::T1(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_dragonskin_boots() -> Loot {
        Loot {
            id: ItemId::DragonskinBoots,
            tier: Tier::T2(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_studded_leather_boots() -> Loot {
        Loot {
            id: ItemId::StuddedLeatherBoots,
            tier: Tier::T3(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_hard_leather_boots() -> Loot {
        Loot {
            id: ItemId::HardLeatherBoots,
            tier: Tier::T4(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_leather_boots() -> Loot {
        Loot {
            id: ItemId::LeatherBoots,
            tier: Tier::T5(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_demons_hands() -> Loot {
        Loot {
            id: ItemId::DemonsHands,
            tier: Tier::T1(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_dragonskin_gloves() -> Loot {
        Loot {
            id: ItemId::DragonskinGloves,
            tier: Tier::T2(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_studded_leather_gloves() -> Loot {
        Loot {
            id: ItemId::StuddedLeatherGloves,
            tier: Tier::T3(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_hard_leather_gloves() -> Loot {
        Loot {
            id: ItemId::HardLeatherGloves,
            tier: Tier::T4(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_leather_gloves() -> Loot {
        Loot {
            id: ItemId::LeatherGloves,
            tier: Tier::T5(()),
            item_type: Type::Blade_or_Hide(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_warhammer() -> Loot {
        Loot {
            id: ItemId::Warhammer,
            tier: Tier::T1(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_quarterstaff() -> Loot {
        Loot {
            id: ItemId::Quarterstaff,
            tier: Tier::T2(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_maul() -> Loot {
        Loot {
            id: ItemId::Maul,
            tier: Tier::T3(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_mace() -> Loot {
        Loot {
            id: ItemId::Mace,
            tier: Tier::T4(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_club() -> Loot {
        Loot {
            id: ItemId::Club,
            tier: Tier::T5(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Weapon(())
        }
    }
    #[inline(always)]
    fn get_holy_chestplate() -> Loot {
        Loot {
            id: ItemId::HolyChestplate,
            tier: Tier::T1(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_ornate_chestplate() -> Loot {
        Loot {
            id: ItemId::OrnateChestplate,
            tier: Tier::T2(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_plate_mail() -> Loot {
        Loot {
            id: ItemId::PlateMail,
            tier: Tier::T3(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_chain_mail() -> Loot {
        Loot {
            id: ItemId::ChainMail,
            tier: Tier::T4(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_ring_mail() -> Loot {
        Loot {
            id: ItemId::RingMail,
            tier: Tier::T5(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Chest(())
        }
    }
    #[inline(always)]
    fn get_ancient_helm() -> Loot {
        Loot {
            id: ItemId::AncientHelm,
            tier: Tier::T1(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_ornate_helm() -> Loot {
        Loot {
            id: ItemId::OrnateHelm,
            tier: Tier::T2(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_great_helm() -> Loot {
        Loot {
            id: ItemId::GreatHelm,
            tier: Tier::T3(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_full_helm() -> Loot {
        Loot {
            id: ItemId::FullHelm,
            tier: Tier::T4(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_helm() -> Loot {
        Loot {
            id: ItemId::Helm,
            tier: Tier::T5(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Head(())
        }
    }
    #[inline(always)]
    fn get_ornate_belt() -> Loot {
        Loot {
            id: ItemId::OrnateBelt,
            tier: Tier::T1(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_war_belt() -> Loot {
        Loot {
            id: ItemId::WarBelt,
            tier: Tier::T2(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_plated_belt() -> Loot {
        Loot {
            id: ItemId::PlatedBelt,
            tier: Tier::T3(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_mesh_belt() -> Loot {
        Loot {
            id: ItemId::MeshBelt,
            tier: Tier::T4(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_heavy_belt() -> Loot {
        Loot {
            id: ItemId::HeavyBelt,
            tier: Tier::T5(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Waist(())
        }
    }
    #[inline(always)]
    fn get_holy_greaves() -> Loot {
        Loot {
            id: ItemId::HolyGreaves,
            tier: Tier::T1(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_ornate_greaves() -> Loot {
        Loot {
            id: ItemId::OrnateGreaves,
            tier: Tier::T2(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_greaves() -> Loot {
        Loot {
            id: ItemId::Greaves,
            tier: Tier::T3(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_chain_boots() -> Loot {
        Loot {
            id: ItemId::ChainBoots,
            tier: Tier::T4(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_heavy_boots() -> Loot {
        Loot {
            id: ItemId::HeavyBoots,
            tier: Tier::T5(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Foot(())
        }
    }
    #[inline(always)]
    fn get_holy_gauntlets() -> Loot {
        Loot {
            id: ItemId::HolyGauntlets,
            tier: Tier::T1(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_ornate_gauntlets() -> Loot {
        Loot {
            id: ItemId::OrnateGauntlets,
            tier: Tier::T2(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_gauntlets() -> Loot {
        Loot {
            id: ItemId::Gauntlets,
            tier: Tier::T3(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_chain_gloves() -> Loot {
        Loot {
            id: ItemId::ChainGloves,
            tier: Tier::T4(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_heavy_gloves() -> Loot {
        Loot {
            id: ItemId::HeavyGloves,
            tier: Tier::T5(()),
            item_type: Type::Bludgeon_or_Metal(()),
            slot: Slot::Hand(())
        }
    }
    #[inline(always)]
    fn get_blank_item() -> Loot {
        Loot { id: 0, tier: Tier::None(()), item_type: Type::None(()), slot: Slot::None(()) }
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use core::array::ArrayTrait;
    use lootitems::{utils::{NameUtils, ItemUtils}, constants::{ItemId}};

    #[test]
    #[available_gas(151130)]
    fn test_is_necklace() {
        let necklace = array![ItemId::Pendant, ItemId::Necklace, ItemId::Amulet];

        let mut item_index = 0;
        loop {
            if item_index == necklace.len() {
                break;
            }
            let item = *necklace.at(item_index);
            assert(ItemUtils::is_necklace(item), 'should be necklace');
            assert(!ItemUtils::is_head_armor(item), 'not head armor');
            assert(!ItemUtils::is_ring(item), 'not ring1');
            assert(!ItemUtils::is_weapon(item), 'not a weapon');
            assert(!ItemUtils::is_chest_armor(item), 'not chest armor');
            assert(!ItemUtils::is_waist_armor(item), 'not waist armor');
            assert(!ItemUtils::is_hand_armor(item), 'not hand armor');
            assert(!ItemUtils::is_foot_armor(item), 'not foot armor');
            item_index += 1;
        }
    }

    #[test]
    #[available_gas(225210)]
    fn test_is_ring() {
        let rings = array![
            ItemId::SilverRing,
            ItemId::BronzeRing,
            ItemId::PlatinumRing,
            ItemId::TitaniumRing,
            ItemId::GoldRing
        ];

        let mut item_index = 0;
        loop {
            if item_index == rings.len() {
                break;
            }
            let item = *rings.at(item_index);
            assert(ItemUtils::is_ring(item), 'should be ring');
            assert(!ItemUtils::is_necklace(item), 'not necklace');
            assert(!ItemUtils::is_head_armor(item), 'not head armor');
            assert(!ItemUtils::is_weapon(item), 'not a weapon');
            assert(!ItemUtils::is_chest_armor(item), 'not chest armor');
            assert(!ItemUtils::is_waist_armor(item), 'not waist armor');
            assert(!ItemUtils::is_hand_armor(item), 'not hand armor');
            assert(!ItemUtils::is_foot_armor(item), 'not foot armor');
            item_index += 1;
        }
    }

    #[test]
    #[available_gas(560070)]
    fn test_is_weapon() {
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
            let item = *weapons.at(item_index);
            assert(ItemUtils::is_weapon(item), 'should be weapon');
            assert(!ItemUtils::is_necklace(item), 'not necklace');
            assert(!ItemUtils::is_ring(item), 'not ring2');
            assert(!ItemUtils::is_chest_armor(item), 'not chest armor');
            assert(!ItemUtils::is_head_armor(item), 'not head armor');
            assert(!ItemUtils::is_waist_armor(item), 'not waist armor');
            assert(!ItemUtils::is_hand_armor(item), 'not hand armor');
            assert(!ItemUtils::is_foot_armor(item), 'not foot armor');
            item_index += 1;
        }
    }

    #[test]
    #[available_gas(597210)]
    fn test_is_chest_armor() {
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
            let item = *chest_armor.at(item_index);
            assert(ItemUtils::is_chest_armor(item), 'should be chest armor');
            assert(!ItemUtils::is_necklace(item), 'not necklace');
            assert(!ItemUtils::is_ring(item), 'not ring3');
            assert(!ItemUtils::is_weapon(item), 'not a weapon');
            assert(!ItemUtils::is_head_armor(item), 'not head armor');
            assert(!ItemUtils::is_waist_armor(item), 'not waist armor');
            assert(!ItemUtils::is_hand_armor(item), 'not hand armor');
            assert(!ItemUtils::is_foot_armor(item), 'not foot armor');
            item_index += 1;
        }
    }

    #[test]
    #[available_gas(597210)]
    fn test_is_head_armor() {
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
            let item = *head_armor.at(item_index);
            assert(ItemUtils::is_head_armor(item), 'should be head armor');
            assert(!ItemUtils::is_necklace(item), 'not necklace');
            assert(!ItemUtils::is_ring(item), 'not ring4');
            assert(!ItemUtils::is_weapon(item), 'not a weapon');
            assert(!ItemUtils::is_chest_armor(item), 'not chest armor');
            assert(!ItemUtils::is_waist_armor(item), 'not waist armor');
            assert(!ItemUtils::is_hand_armor(item), 'not hand armor');
            assert(!ItemUtils::is_foot_armor(item), 'not foot armor');
            item_index += 1;
        }
    }

    #[test]
    #[available_gas(597210)]
    fn test_is_waist_armor() {
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
            let item = *waist_armor_items.at(item_index);
            assert(ItemUtils::is_waist_armor(item), 'should be waist armor');
            assert(!ItemUtils::is_necklace(item), 'not necklace');
            assert(!ItemUtils::is_ring(item), 'not ring5');
            assert(!ItemUtils::is_weapon(item), 'not a weapon');
            assert(!ItemUtils::is_chest_armor(item), 'not chest armor');
            assert(!ItemUtils::is_head_armor(item), 'not head armor');
            assert(!ItemUtils::is_hand_armor(item), 'not hand armor');
            assert(!ItemUtils::is_foot_armor(item), 'not foot armor');
            item_index += 1;
        }
    }

    #[test]
    #[available_gas(597210)]
    fn test_is_hand_armor() {
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
            let item = *hand_armor_items.at(item_index);
            assert(ItemUtils::is_hand_armor(item), 'should be hand armor');
            assert(!ItemUtils::is_necklace(item), 'not necklace');
            assert(!ItemUtils::is_ring(item), 'not ring6');
            assert(!ItemUtils::is_weapon(item), 'not a weapon');
            assert(!ItemUtils::is_chest_armor(item), 'not chest armor');
            assert(!ItemUtils::is_head_armor(item), 'not head armor');
            assert(!ItemUtils::is_waist_armor(item), 'not waist armor');
            assert(!ItemUtils::is_foot_armor(item), 'not foot armor');
            item_index += 1;
        }
    }

    #[test]
    #[available_gas(597210)]
    fn test_is_foot_armor() {
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
            let item = *foot_armor_items.at(item_index);
            assert(ItemUtils::is_foot_armor(item), 'should be foot armor');
            assert(!ItemUtils::is_necklace(item), 'not necklace');
            assert(!ItemUtils::is_ring(item), 'not ring7');
            assert(!ItemUtils::is_weapon(item), 'not a weapon');
            assert(!ItemUtils::is_chest_armor(item), 'not chest armor');
            assert(!ItemUtils::is_head_armor(item), 'not head armor');
            assert(!ItemUtils::is_waist_armor(item), 'not waist armor');
            assert(!ItemUtils::is_hand_armor(item), 'not hand armor');
            item_index += 1;
        }
    }
}
