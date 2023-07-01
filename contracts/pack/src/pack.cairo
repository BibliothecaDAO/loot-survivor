use option::OptionTrait;
use traits::{Into, TryInto};

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

#[inline(always)]
fn rshift_split(value: u256, bits: u256) -> (u256, u256) {
    integer::U256DivRem::div_rem(value, bits.try_into().expect('0 bits'))
}

#[cfg(test)]
mod tests {
    use super::rshift_split;
    use pack::constants::pow;

    #[test]
    #[available_gas(10000000)]
    fn test_rshift_split_pass() {
        let v = 0b11010101;

        let (q, r) = rshift_split(v, pow::TWO_POW_1);
        assert(q == 0b1101010, 'q 1 bit');
        assert(r == 0b1, 'r 1 bit');

        let (q, r) = rshift_split(v, pow::TWO_POW_2);
        assert(q == 0b110101, 'q 2 bits');
        assert(r == 0b01, 'r 2 bits');

        let (q, r) = rshift_split(v, pow::TWO_POW_3);
        assert(q == 0b11010, 'q 3 bits');
        assert(r == 0b101, 'r 3 bits');

        let (q, r) = rshift_split(v, pow::TWO_POW_4);
        assert(q == 0b1101, 'q 4 bits');
        assert(r == 0b0101, 'r 4 bits');

        let (q, r) = rshift_split(v, pow::TWO_POW_8);
        assert(q == 0, 'q 8 bits');
        assert(r == v, 'r 8 bits');
    }

    #[test]
    #[available_gas(10000000)]
    #[should_panic]
    fn test_rshift_split_0() {
        rshift_split(0b1101, 0);
    }
}
