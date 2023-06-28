use integer::{u256_from_felt252};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

fn pack_value(value: felt252, pow: u256) -> u256 {
    u256_from_felt252(value) * pow
}

fn unpack_value(value: u256, pow: u256, mask: u256) -> u256 {
    (value / pow) & mask
}
