//mod WeaponEffectiveness {
//    const weak: u8 = 1;
//    const fair: u8 = 2;
//    const strong: u8 = 3;
//}
//

#[derive(Drop, PartialEq)]
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
}
