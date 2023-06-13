use num_bigint::BigUint;
use num_traits::{One, Pow, Zero};

fn main() {
    let mut base: BigUint = BigUint::one();
    for i in 1..=252 {
        base = &base * 2u32;
        println!(
            "const TWO_POW_{}: u256 = 0x{}; // 2^{}",
            i,
            base.to_str_radix(16),
            i
        );
    }
}
