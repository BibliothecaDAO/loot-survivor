use adventurer::{adventurer::{Adventurer}, adventurer_meta::{AdventurerMetadata}, bag::{Bag}};

#[starknet::interface]
trait IRenderContract<TContractState> {
    fn token_uri(
        self: @TContractState,
        adventurer_id: felt252,
        adventurer: Adventurer,
        adventurerMetadata: AdventurerMetadata,
        bag: Bag
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
            adventurer_id: felt252,
            adventurer: Adventurer,
            adventurerMetadata: AdventurerMetadata,
            bag: Bag
        ) -> ByteArray {
            create_metadata(adventurer_id, adventurer, adventurerMetadata, bag)
        }
    }
}
