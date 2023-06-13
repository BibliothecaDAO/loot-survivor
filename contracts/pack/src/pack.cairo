use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

impl U256TryIntoU64 of TryInto<u256, u64> {
    fn try_into(self: u256) -> Option<u64> {
        let intermediate: Option<felt252> = self.try_into();
        match intermediate {
            Option::Some(felt) => felt.try_into(),
            Option::None(()) => Option::None(())
        }
    }
}

impl U256TryIntoU32 of TryInto<u256, u32> {
    fn try_into(self: u256) -> Option<u32> {
        let intermediate: Option<felt252> = self.try_into();
        match intermediate {
            Option::Some(felt) => felt.try_into(),
            Option::None(()) => Option::None(())
        }
    }
}

impl U256TryIntoU16 of TryInto<u256, u16> {
    fn try_into(self: u256) -> Option<u16> {
        let intermediate: Option<felt252> = self.try_into();
        match intermediate {
            Option::Some(felt) => felt.try_into(),
            Option::None(()) => Option::None(())
        }
    }
}

impl U256TryIntoU8 of TryInto<u256, u8> {
    fn try_into(self: u256) -> Option<u8> {
        let intermediate: Option<felt252> = self.try_into();
        match intermediate {
            Option::Some(felt) => felt.try_into(),
            Option::None(()) => Option::None(())
        }
    }
}
fn pack_value(value: felt252, pow: u256) -> u256 {
    u256_from_felt252(value) * pow
}

fn unpack_value(value: u256, pow: u256, mask: u256) -> u256 {
    (value / pow) & mask
}
