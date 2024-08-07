use adventurer::{adventurer::{Adventurer}, adventurer_meta::{AdventurerMetadata}, bag::{Bag}};

#[starknet::interface]
trait IRenderContract<TContractState> {
    fn token_uri(
        self: @TContractState,
        adventurer_id: u256,
        adventurer: Adventurer,
        adventurer_name: felt252,
        adventurerMetadata: AdventurerMetadata,
        bag: Bag,
        item_specials_seed: u16,
        rank_at_death: u8,
        current_rank: u8,
    ) -> ByteArray;
}

#[starknet::contract]
mod RenderContract {
    use adventurer::{adventurer::{Adventurer}, adventurer_meta::{AdventurerMetadata}, bag::{Bag}};
    use game::game::renderer::{create_metadata};

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl Render of super::IRenderContract<ContractState> {
        fn token_uri(
            self: @ContractState,
            adventurer_id: u256,
            adventurer: Adventurer,
            adventurer_name: felt252,
            adventurerMetadata: AdventurerMetadata,
            bag: Bag,
            item_specials_seed: u16,
            rank_at_death: u8,
            current_rank: u8,
        ) -> ByteArray {
            create_metadata(
                adventurer_id.try_into().unwrap(),
                adventurer,
                adventurer_name,
                adventurerMetadata,
                bag,
                item_specials_seed,
                rank_at_death,
                current_rank,
            )
        }
    }
}
