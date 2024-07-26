use keccak::{cairo_keccak, u128_split};
use integer::{BoundedInt, u32_as_non_zero, U32TryIntoNonZero};

#[inline(always)]
fn get_base64_char_set() -> Span<u8> {
    let mut result = array![
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z',
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
        'i',
        'j',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'q',
        'r',
        's',
        't',
        'u',
        'v',
        'w',
        'x',
        'y',
        'z',
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '+',
        '/'
    ];
    result.span()
}

fn bytes_base64_encode(_bytes: ByteArray) -> ByteArray {
    encode_bytes(_bytes, get_base64_char_set())
}


fn encode_bytes(mut bytes: ByteArray, base64_chars: Span<u8>) -> ByteArray {
    let mut result: ByteArray = "";
    if bytes.len() == 0 {
        return result;
    }
    let mut p: u8 = 0;
    let c = bytes.len() % 3;
    if c == 1 {
        p = 2;
        bytes.append_byte(0_u8);
        bytes.append_byte(0_u8);
    } else if c == 2 {
        p = 1;
        bytes.append_byte(0_u8);
    }

    let mut i = 0;
    let bytes_len = bytes.len();
    let last_iteration = bytes_len - 3;
    loop {
        if i == bytes_len {
            break;
        }
        let n: u32 = (bytes.at(i).unwrap()).into()
            * 65536 | (bytes.at(i + 1).unwrap()).into()
            * 256 | (bytes.at(i + 2).unwrap()).into();
        let e1 = (n / 262144) & 63;
        let e2 = (n / 4096) & 63;
        let e3 = (n / 64) & 63;
        let e4 = n & 63;

        if i == last_iteration {
            if p == 2 {
                result.append_byte(*base64_chars[e1]);
                result.append_byte(*base64_chars[e2]);
                result.append_byte('=');
                result.append_byte('=');
            } else if p == 1 {
                result.append_byte(*base64_chars[e1]);
                result.append_byte(*base64_chars[e2]);
                result.append_byte(*base64_chars[e3]);
                result.append_byte('=');
            } else {
                result.append_byte(*base64_chars[e1]);
                result.append_byte(*base64_chars[e2]);
                result.append_byte(*base64_chars[e3]);
                result.append_byte(*base64_chars[e4]);
            }
        } else {
            result.append_byte(*base64_chars[e1]);
            result.append_byte(*base64_chars[e2]);
            result.append_byte(*base64_chars[e3]);
            result.append_byte(*base64_chars[e4]);
        }

        i += 3;
    };
    result
}


trait BytesUsedTrait<T> {
    /// Returns the number of bytes used to represent a `T` value.
    /// # Arguments
    /// * `self` - The value to check.
    /// # Returns
    /// The number of bytes used to represent the value.
    fn bytes_used(self: T) -> u8;
}

impl U8BytesUsedTraitImpl of BytesUsedTrait<u8> {
    fn bytes_used(self: u8) -> u8 {
        if self == 0 {
            return 0;
        }

        return 1;
    }
}

impl USizeBytesUsedTraitImpl of BytesUsedTrait<usize> {
    fn bytes_used(self: usize) -> u8 {
        if self < 0x10000 { // 256^2
            if self < 0x100 { // 256^1
                if self == 0 {
                    return 0;
                } else {
                    return 1;
                };
            }
            return 2;
        } else {
            if self < 0x1000000 { // 256^3
                return 3;
            }
            return 4;
        }
    }
}

impl U64BytesUsedTraitImpl of BytesUsedTrait<u64> {
    fn bytes_used(self: u64) -> u8 {
        if self <= BoundedInt::<u32>::max().into() { // 256^4
            return BytesUsedTrait::<u32>::bytes_used(self.try_into().unwrap());
        } else {
            if self < 0x1000000000000 { // 256^6
                if self < 0x10000000000 {
                    if self < 0x100000000 {
                        return 4;
                    }
                    return 5;
                }
                return 6;
            } else {
                if self < 0x100000000000000 { // 256^7
                    return 7;
                } else {
                    return 8;
                }
            }
        }
    }
}


impl U128BytesTraitUsedImpl of BytesUsedTrait<u128> {
    fn bytes_used(self: u128) -> u8 {
        let (u64high, u64low) = u128_split(self);
        if u64high == 0 {
            return BytesUsedTrait::<u64>::bytes_used(u64low.try_into().unwrap());
        } else {
            return BytesUsedTrait::<u64>::bytes_used(u64high.try_into().unwrap()) + 8;
        }
    }
}

impl U256BytesUsedTraitImpl of BytesUsedTrait<u256> {
    fn bytes_used(self: u256) -> u8 {
        if self.high == 0 {
            return BytesUsedTrait::<u128>::bytes_used(self.low.try_into().unwrap());
        } else {
            return BytesUsedTrait::<u128>::bytes_used(self.high.try_into().unwrap()) + 16;
        }
    }
}
