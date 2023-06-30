use traits::Into;

trait Packing<T> {
    fn pack(self: T) -> felt252;
    fn unpack(packed: felt252) -> T;
}

#[inline(always)]
fn pack_value(value: felt252, pow: u256) -> u256 {
    value.into() * pow
}

#[inline(always)]
fn unpack_value(value: u256, pow: u256, mask: u256) -> u256 {
    (value / pow) & mask
}
