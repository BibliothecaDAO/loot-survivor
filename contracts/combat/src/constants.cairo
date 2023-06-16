#[derive(Drop, Copy, PartialEq)]
enum WeaponEffectiveness {
    Weak: (),
    Fair: (),
    Strong: (),
}

mod CombatSettings {
    // ElementalDamageBonus controls the intensity of elemental damage
    // 0 = disables elemental
    // 1 = elemental has maximum effect (0x, 1x, 2x)
    // 2 = elemental bonus is half of base damage (-0.5x, 1x, 1.5x)
    // 3 = elemental bonus is 1/3 of base damage (-0.66x, 1x, 1.66x)
    const ElementalDamageBonus: u16 = 2; // u16 because this is used with other u16s
    const MaxLuckForCriticalHit: u8 = 40; // max luck for critical hit. Will produce 50% chance
    const MaxTier: u8 = 5;
    const LowestItemTierPlusOne: u16 = 6; // using u16 because this is used with other u16s
}

#[derive(Drop, PartialEq)]
enum ItemCategory {
    Weapon: (),
    Armor: (),
    Necklace: (),
    Ring: (),
}

#[derive(Copy, Drop, PartialEq)]
enum WeaponType {
    Magic: (),
    Blade: (),
    Bludgeon: (),
}

#[derive(Copy, Drop, PartialEq)]
enum ArmorType {
    Cloth: (),
    Hide: (),
    Metal: (),
}
