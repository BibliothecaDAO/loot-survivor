use option::OptionTrait;
use traits::{TryInto, Into};

use pack::constants::pow;
use pack::pack::{Packing, rshift_split};

#[derive(Drop, Copy, PartialEq, Serde)]
enum AdventurerClass {
    None: (),
    Cleric: (),
    Scout: (),
    Hunter: (),
    Warrior: ()
}

#[generate_trait]
impl ImplAdventurerClass of IAdventurerClass {
    fn to_u8(self: AdventurerClass) -> u8 {
        match self {
            AdventurerClass::None(()) => 0,
            AdventurerClass::Cleric(()) => 1,
            AdventurerClass::Scout(()) => 2,
            AdventurerClass::Hunter(()) => 3,
            AdventurerClass::Warrior(()) => 4,
        }
    }
    fn u8_to_slot(item_type: u8) -> AdventurerClass {
        if item_type == 0 {
            AdventurerClass::None(())
        } else if item_type == 1 {
            AdventurerClass::Cleric(())
        } else if item_type == 2 {
            AdventurerClass::Scout(())
        } else if item_type == 3 {
            AdventurerClass::Hunter(())
        } else if item_type == 4 {
            AdventurerClass::Warrior(())
        } else {
            panic_with_felt252('unknown adventurer class')
        }
    }
}

#[derive(Drop, Copy, Serde)]
struct AdventurerMetadata {
    name: u128,
    home_realm: u16,
    class: AdventurerClass,
    entropy: u128,
}

impl PackingAdventurerMetadata of Packing<AdventurerMetadata> {
    fn pack(self: AdventurerMetadata) -> felt252 {
        (self.entropy.into()
            + self.home_realm.into() * pow::TWO_POW_128
            + self.class.to_u8().into() * pow::TWO_POW_141
            + self.name.into() * pow::TWO_POW_145)
            .try_into()
            .expect('pack AdventurerMetadata')
    }
    fn unpack(packed: felt252) -> AdventurerMetadata {
        let packed = packed.into();
        let (packed, entropy) = rshift_split(packed, pow::TWO_POW_128);
        let (packed, home_realm) = rshift_split(packed, pow::TWO_POW_13);
        let (packed, class) = rshift_split(packed, pow::TWO_POW_4);
        let (_, name) = rshift_split(packed, pow::TWO_POW_107);
        AdventurerMetadata {
            name: name.try_into().expect('unpack AdvMetadata name'),
            home_realm: home_realm.try_into().expect('unpack AdvMetadata home_realm'),
            class: ImplAdventurerClass::u8_to_slot(
                class.try_into().expect('unpack AdvMetadata class')
            ),
            entropy: entropy.try_into().expect('unpack AdvMetadata entropy')
        }
    }

    // TODO: add overflow pack protection
    fn overflow_pack_protection(self: AdventurerMetadata) -> AdventurerMetadata {
        self
    }
}

#[cfg(test)]
#[test]
#[available_gas(50000000)]
fn test_meta() {
    let meta = AdventurerMetadata {
        name: 'abcdefghijklm',
        home_realm: 8000,
        class: AdventurerClass::Warrior(()),
        entropy: 340282366920938463463374607431768211455
    };

    let packed = meta.pack();
    let unpacked: AdventurerMetadata = Packing::unpack(packed);
    assert(meta.name == unpacked.name, 'name');
    assert(meta.home_realm == unpacked.home_realm, 'home_realm');
    assert(meta.class == unpacked.class, 'class');
    assert(meta.entropy == unpacked.entropy, 'entropy');
}
