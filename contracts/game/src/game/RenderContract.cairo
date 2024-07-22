use adventurer::{adventurer::{Adventurer}, adventurer_meta::{AdventurerMetadata}, bag::{Bag}};

#[starknet::interface]
trait IRenderContract<TContractState> {
    fn token_uri(
        self: @TContractState,
        adventurer_id: u256,
        adventurer: Adventurer,
        adventurerMetadata: AdventurerMetadata,
        bag: Bag,
        item_specials_seed: felt252
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
            adventurerMetadata: AdventurerMetadata,
            bag: Bag,
            item_specials_seed: felt252
        ) -> ByteArray {
            create_metadata(
                adventurer_id.try_into().unwrap(),
                adventurer,
                adventurerMetadata,
                bag,
                item_specials_seed
            )
        }
    }
}
