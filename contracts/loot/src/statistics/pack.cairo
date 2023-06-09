use starknet::{
    StorageAccess, SyscallResult, StorageBaseAddress, storage_read_syscall, storage_write_syscall,
    storage_address_from_base_and_offset
};
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

const MASK_64: u256 = 0xFFFFFFFFFFFFFFFF;
const MASK_160: u256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

const TWO_POW_160: u256 = 10000000000000000000000000000000000000000;

#[derive(Copy, Drop, Serde)]
struct Proposal {
    proposer: felt252,
    last_updated_at: u64,
}

/// Pack the proposal fields into a single felt252.
/// * `proposer` - The proposer of the proposal.
/// * `last_updated_at` - The last time the proposal was updated.
fn pack_proposal_fields(proposer: felt252, last_updated_at: u64) -> felt252 {
    let mut packed = 0;
    packed = packed | proposer.into();
    packed = packed | (u256_from_felt252(last_updated_at.into()) * TWO_POW_160);

    packed.try_into().unwrap()
}

/// Unpack the proposal fields from a single felt252.
/// * `packed` - The packed proposal.
fn unpack_proposal_fields(packed: felt252) -> (felt252, u64) {
    let packed = packed.into();

    let proposer = (packed & MASK_160).try_into().unwrap();
    let last_updated_at: u64 = U256TryIntoU64::try_into(((packed / TWO_POW_160) & MASK_64))
        .unwrap();

    (proposer, last_updated_at)
}


#[test]
#[available_gas(1000000)]
fn test() {
    let packed = pack_proposal_fields(123123123120, 18982);

    let (proposer, last_updated_at) = unpack_proposal_fields(packed);

    proposer.print();
    assert(last_updated_at == 18982, 'tes');
// assert(proposer.into() == 123123123120, 'tes');
}
