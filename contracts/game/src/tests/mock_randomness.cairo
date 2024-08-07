use starknet::{ContractAddress, ClassHash};

#[derive(Serde, Drop, Copy, PartialEq, starknet::Store)]
enum RequestStatus {
    UNINITIALIZED: (),
    RECEIVED: (),
    FULFILLED: (),
    CANCELLED: (),
    OUT_OF_GAS: (),
    REFUNDED: (),
}

#[starknet::interface]
trait IMockRandomness<TContractState> {
    fn update_status(
        ref self: TContractState,
        requestor_address: ContractAddress,
        request_id: u64,
        new_status: RequestStatus
    );
    fn request_random(
        ref self: TContractState,
        seed: u64,
        callback_address: ContractAddress,
        callback_fee_limit: u128,
        publish_delay: u64,
        num_words: u64,
        calldata: Array<felt252>
    ) -> u64;
    fn cancel_random_request(
        ref self: TContractState,
        request_id: u64,
        requestor_address: ContractAddress,
        seed: u64,
        minimum_block_number: u64,
        callback_address: ContractAddress,
        callback_fee_limit: u128,
        num_words: u64
    );
    fn submit_random(
        ref self: TContractState,
        request_id: u64,
        requestor_address: ContractAddress,
        seed: u64,
        minimum_block_number: u64,
        callback_address: ContractAddress,
        callback_fee_limit: u128,
        callback_fee: u128,
        random_words: Span<felt252>,
        proof: Span<felt252>,
        calldata: Array<felt252>
    );
    fn get_pending_requests(
        self: @TContractState, requestor_address: ContractAddress, offset: u64, max_len: u64
    ) -> Span<felt252>;

    fn get_request_status(
        self: @TContractState, requestor_address: ContractAddress, request_id: u64
    ) -> RequestStatus;
    fn requestor_current_index(self: @TContractState, requestor_address: ContractAddress) -> u64;
    fn get_public_key(self: @TContractState, requestor_address: ContractAddress) -> felt252;
    fn get_payment_token(self: @TContractState) -> ContractAddress;
    fn set_payment_token(ref self: TContractState, token_contract: ContractAddress);
    fn upgrade(ref self: TContractState, impl_hash: ClassHash);
    fn refund_operation(ref self: TContractState, caller_address: ContractAddress, request_id: u64);
    fn get_total_fees(
        self: @TContractState, caller_address: ContractAddress, request_id: u64
    ) -> u256;
    fn get_out_of_gas_requests(
        self: @TContractState, requestor_address: ContractAddress,
    ) -> Span<u64>;
    fn withdraw_funds(ref self: TContractState, receiver_address: ContractAddress);
    fn get_contract_balance(self: @TContractState) -> u256;
    fn compute_premium_fee(self: @TContractState, caller_address: ContractAddress) -> u128;
    fn get_admin_address(self: @TContractState,) -> ContractAddress;
    fn set_admin_address(ref self: TContractState, new_admin_address: ContractAddress);
}

#[starknet::contract]
mod MockRandomness {
    use super::{ContractAddress, IMockRandomness, RequestStatus};
    use starknet::{get_caller_address, get_contract_address, ClassHash};
    use game::game::interfaces::{IGameDispatcher, IGameDispatcherTrait};
    use array::ArrayTrait;
    use traits::Into;

    #[storage]
    struct Storage {
        request_id: LegacyMap::<ContractAddress, u64>,
        request_status: LegacyMap::<(ContractAddress, u64), RequestStatus>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, test: felt252) {
        return ();
    }

    #[abi(embed_v0)]
    impl IMockRandomnessImpl of IMockRandomness<ContractState> {
        fn update_status(
            ref self: ContractState,
            requestor_address: ContractAddress,
            request_id: u64,
            new_status: RequestStatus
        ) {
            self.request_status.write((requestor_address, request_id), new_status);
            return ();
        }

        fn request_random(
            ref self: ContractState,
            seed: u64,
            callback_address: ContractAddress,
            callback_fee_limit: u128,
            publish_delay: u64,
            num_words: u64,
            calldata: Array<felt252>
        ) -> u64 {
            let caller_address = get_caller_address();
            let request_id = self.request_id.read(caller_address);
            self.request_status.write((caller_address, request_id), RequestStatus::RECEIVED(()));
            self.request_id.write(caller_address, request_id + 1);

            // Mock implementation, you can customize it as needed
            let mut data = ArrayTrait::new();
            data.append(1234.into());
            let game_dispatcher = IGameDispatcher { contract_address: callback_address };
            game_dispatcher
                .receive_random_words(starknet::get_contract_address(), 1, data.span(), calldata);
            return request_id;
        }

        fn cancel_random_request(
            ref self: ContractState,
            request_id: u64,
            requestor_address: ContractAddress,
            seed: u64,
            minimum_block_number: u64,
            callback_address: ContractAddress,
            callback_fee_limit: u128,
            num_words: u64
        ) {
            self
                .request_status
                .write((requestor_address, request_id), RequestStatus::CANCELLED(()));
            return ();
        }

        fn submit_random(
            ref self: ContractState,
            request_id: u64,
            requestor_address: ContractAddress,
            seed: u64,
            minimum_block_number: u64,
            callback_address: ContractAddress,
            callback_fee_limit: u128,
            callback_fee: u128,
            random_words: Span<felt252>,
            proof: Span<felt252>,
            calldata: Array<felt252>
        ) {
            self
                .request_status
                .write((requestor_address, request_id), RequestStatus::FULFILLED(()));
            return ();
        }

        fn get_pending_requests(
            self: @ContractState, requestor_address: ContractAddress, offset: u64, max_len: u64
        ) -> Span<felt252> {
            let mut requests = ArrayTrait::<felt252>::new();
            return requests.span();
        }

        fn get_request_status(
            self: @ContractState, requestor_address: ContractAddress, request_id: u64
        ) -> RequestStatus {
            self.request_status.read((requestor_address, request_id))
        }

        fn requestor_current_index(
            self: @ContractState, requestor_address: ContractAddress
        ) -> u64 {
            self.request_id.read(requestor_address)
        }

        fn get_public_key(self: @ContractState, requestor_address: ContractAddress) -> felt252 {
            1234
        }

        fn get_payment_token(self: @ContractState) -> ContractAddress {
            get_contract_address()
        }

        fn set_payment_token(ref self: ContractState, token_contract: ContractAddress) {
            return ();
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            return ();
        }

        fn refund_operation(
            ref self: ContractState, caller_address: ContractAddress, request_id: u64
        ) {
            return ();
        }

        fn get_total_fees(
            self: @ContractState, caller_address: ContractAddress, request_id: u64
        ) -> u256 {
            0.into()
        }

        fn get_out_of_gas_requests(
            self: @ContractState, requestor_address: ContractAddress,
        ) -> Span<u64> {
            let mut requests = ArrayTrait::<u64>::new();
            return requests.span();
        }

        fn withdraw_funds(ref self: ContractState, receiver_address: ContractAddress) {
            return ();
        }

        fn get_contract_balance(self: @ContractState) -> u256 {
            0.into()
        }

        fn compute_premium_fee(self: @ContractState, caller_address: ContractAddress) -> u128 {
            0
        }

        fn get_admin_address(self: @ContractState,) -> ContractAddress {
            get_contract_address()
        }

        fn set_admin_address(ref self: ContractState, new_admin_address: ContractAddress) {
            return ();
        }
    }
}
