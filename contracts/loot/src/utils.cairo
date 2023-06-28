mod NameUtils {
    use lootitems::statistics::constants::{ItemNameSuffix, ItemSuffix};
    
    // name suffixes are the second part of the prefix aka the "Grasp" part of "Demon Grasp"
    // I realize this is a bit confusing but this is what the
    // loot contract refers to them as so I'm just being consistent with the contract
    fn is_name_suffix_set1(name: u8) -> bool {
        return (name == ItemNameSuffix::Bane
            || name == ItemNameSuffix::Song
            || name == ItemNameSuffix::Instrument
            || name == ItemNameSuffix::Shadow
            || name == ItemNameSuffix::Growl
            || name == ItemNameSuffix::Form);
    }

    fn is_name_suffix_set2(name: u8) -> bool {
        return (name == ItemNameSuffix::Root
            || name == ItemNameSuffix::Roar
            || name == ItemNameSuffix::Glow
            || name == ItemNameSuffix::Whisper
            || name == ItemNameSuffix::Tear
            || name == ItemNameSuffix::Sun);
    }

    fn is_name_suffix_set3(name: u8) -> bool {
        return (name == ItemNameSuffix::Bite
            || name == ItemNameSuffix::Grasp
            || name == ItemNameSuffix::Bender
            || name == ItemNameSuffix::Shout
            || name == ItemNameSuffix::Peak
            || name == ItemNameSuffix::Moon);
    }

    fn is_name_prefix_set1(name: u8) -> bool {
        if name < 1 || name > 69 {
            false
        } else {
            (name - 1) % 3 == 0
        }
    }

    fn is_name_prefix_set2(name: u8) -> bool {
        if name < 2 || name > 69 {
            false
        } else {
            (name - 2) % 3 == 0
        }
    }    

    fn is_name_prefix_set3(name: u8) -> bool {
        if name < 3 || name > 69 {
            false
        } else {
            (name - 3) % 3 == 0
        }
    }

    // the item suffix is the suffix of the item such as "of Power"
    fn is_item_suffix_set1(name: u8) -> bool {
        return (name == ItemSuffix::of_Power
            || name == ItemSuffix::of_Titans
            || name == ItemSuffix::of_Perfection
            || name == ItemSuffix::of_Enlightenment
            || name == ItemSuffix::of_Anger
            || name == ItemSuffix::of_Fury
            || name == ItemSuffix::of_the_Fox
            || name == ItemSuffix::of_Reflection);
    }

    fn is_item_suffix_set2(name: u8) -> bool {
        return (name == ItemSuffix::of_Giant
            || name == ItemSuffix::of_Skill
            || name == ItemSuffix::of_Brilliance
            || name == ItemSuffix::of_Protection
            || name == ItemSuffix::of_Rage
            || name == ItemSuffix::of_Vitriol
            || name == ItemSuffix::of_Detection
            || name == ItemSuffix::of_the_Twins);
    }
}
