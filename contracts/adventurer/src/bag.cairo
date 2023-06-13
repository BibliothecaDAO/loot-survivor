use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

use pack::pack::{pack_value, unpack_value, U256TryIntoU32, U256TryIntoU16, U256TryIntoU8};
use pack::constants::{pow, mask};

use super::adventurer::{Adventurer, AdventurerActions, Actions};

#[derive(Drop, Copy, Serde)] // 24 bits
struct Item {
    id: u8, // 7 bits
    xp: u16, // 12 bits
    // this is set as the items are found/purchased
    metadata: u8, // 5 bits 
}

#[derive(Drop, Copy, Serde)]
struct Bag {
    item_1: Item, // club
    item_2: Item, // club
    item_3: Item, // club
    item_4: Item, // club
    item_5: Item, // club
    item_6: Item, // club
    item_7: Item, // club
    item_8: Item, // club
    item_9: Item, // club
    item_10: Item, // club
    item_11: Item, // club
    item_12: Item, // club
}

trait BagActions {
    fn pack(self: Bag) -> felt252;
    fn unpack(packed: felt252) -> Bag;

    // swap item
    // take bag and item to swap and item to equip
    // return bag with swapped items and item that was swapped for
    // we then store the item on the Adventurer
    // fn swap_items(self: Bag, incoming: u8, outgoing: u8) -> (Bag, Item);

    // set item in first available slot
    fn set_item(ref self: Bag, item: Item) -> Bag;

    // finds open slot
    fn find_slot(self: Bag) -> u8;

    // check if bag full
    fn is_full(self: Bag) -> bool;

    // get item by id
    fn get_item(self: Bag, item_id: u8) -> Item;
}

impl ImplBagActions of BagActions {
    fn pack(self: Bag) -> felt252 {
        0
    }
    fn unpack(packed: felt252) -> Bag {
        Bag {
            item_1: Item {
                id: 0, xp: 0, metadata: 0, 
                }, item_2: Item {
                id: 0, xp: 0, metadata: 0, 
                }, item_3: Item {
                id: 0, xp: 0, metadata: 0, 
                }, item_4: Item {
                id: 0, xp: 0, metadata: 0, 
                }, item_5: Item {
                id: 0, xp: 0, metadata: 0, 
                }, item_6: Item {
                id: 0, xp: 0, metadata: 0, 
                }, item_7: Item {
                id: 0, xp: 0, metadata: 0, 
                }, item_8: Item {
                id: 0, xp: 0, metadata: 0, 
                }, item_9: Item {
                id: 0, xp: 0, metadata: 0, 
                }, item_10: Item {
                id: 0, xp: 0, metadata: 0, 
                }, item_11: Item {
                id: 0, xp: 0, metadata: 0, 
                }, item_12: Item {
                id: 0, xp: 0, metadata: 0, 
            },
        }
    }
    fn set_item(ref self: Bag, item: Item) -> Bag {
        assert(self.is_full() == false, 'Bag is full');

        let slot = self.find_slot();

        if slot == 0 {
            self.item_1 = item;
            return self;
        } else if slot == 1 {
            self.item_2 = item;
            return self;
        } else if slot == 2 {
            self.item_3 = item;
            return self;
        } else if slot == 3 {
            self.item_4 = item;
            return self;
        } else if slot == 4 {
            self.item_5 = item;
            return self;
        } else if slot == 5 {
            self.item_6 = item;
            return self;
        } else if slot == 6 {
            self.item_7 = item;
            return self;
        } else if slot == 7 {
            self.item_8 = item;
            return self;
        } else if slot == 8 {
            self.item_9 = item;
            return self;
        } else if slot == 9 {
            self.item_10 = item;
            return self;
        } else if slot == 10 {
            self.item_11 = item;
            return self;
        } else if slot == 11 {
            self.item_12 = item;
            return self;
        } else {
            return self;
        }
    }
    fn find_slot(self: Bag) -> u8 {
        if self.item_1.id == 0 {
            return 0;
        } else if self.item_2.id == 0 {
            return 1;
        } else if self.item_3.id == 0 {
            return 2;
        } else if self.item_4.id == 0 {
            return 3;
        } else if self.item_5.id == 0 {
            return 4;
        } else if self.item_6.id == 0 {
            return 5;
        } else if self.item_7.id == 0 {
            return 6;
        } else if self.item_8.id == 0 {
            return 7;
        } else if self.item_9.id == 0 {
            return 8;
        } else if self.item_10.id == 0 {
            return 9;
        } else if self.item_11.id == 0 {
            return 10;
        } else if self.item_12.id == 0 {
            return 11;
        } else {
            return 12;
        }
    }
    fn is_full(self: Bag) -> bool {
        if self.item_12.id == 0 {
            return false;
        } else {
            return true;
        }
    }
    fn get_item(self: Bag, item_id: u8) -> Item {
        if self.item_1.id == item_id {
            return self.item_1;
        } else if self.item_2.id == item_id {
            return self.item_2;
        } else if self.item_3.id == item_id {
            return self.item_3;
        } else if self.item_4.id == item_id {
            return self.item_4;
        } else if self.item_5.id == item_id {
            return self.item_5;
        } else if self.item_6.id == item_id {
            return self.item_6;
        } else if self.item_7.id == item_id {
            return self.item_7;
        } else if self.item_8.id == item_id {
            return self.item_8;
        } else if self.item_9.id == item_id {
            return self.item_9;
        } else if self.item_10.id == item_id {
            return self.item_10;
        } else if self.item_11.id == item_id {
            return self.item_11;
        } else {
            return self.item_12;
        }
    }
}


#[test]
#[available_gas(5000000)]
fn test_set_item() {
    let mut bag = Bag {
        item_1: Item {
            id: 1, xp: 0, metadata: 0
            }, item_2: Item {
            id: 2, xp: 0, metadata: 0
            }, item_3: Item {
            id: 3, xp: 0, metadata: 0
            }, item_4: Item {
            id: 4, xp: 0, metadata: 0
            }, item_5: Item {
            id: 5, xp: 0, metadata: 0
            }, item_6: Item {
            id: 0, xp: 0, metadata: 0
            }, item_7: Item {
            id: 0, xp: 0, metadata: 0
            }, item_8: Item {
            id: 0, xp: 0, metadata: 0
            }, item_9: Item {
            id: 0, xp: 0, metadata: 0
            }, item_10: Item {
            id: 0, xp: 0, metadata: 0
            }, item_11: Item {
            id: 0, xp: 0, metadata: 0
            }, item_12: Item {
            id: 0, xp: 0, metadata: 0
        },
    };

    let item = Item { id: 23, xp: 1, metadata: 5 };

    bag.set_item(item);

    assert(bag.item_6.id == 23, 'Item id should be 23');
}

#[test]
#[available_gas(5000000)]
fn test_is_full() {
    let mut bag = Bag {
        item_1: Item {
            id: 1, xp: 0, metadata: 0
            }, item_2: Item {
            id: 2, xp: 0, metadata: 0
            }, item_3: Item {
            id: 3, xp: 0, metadata: 0
            }, item_4: Item {
            id: 4, xp: 0, metadata: 0
            }, item_5: Item {
            id: 5, xp: 0, metadata: 0
            }, item_6: Item {
            id: 8, xp: 0, metadata: 0
            }, item_7: Item {
            id: 9, xp: 0, metadata: 0
            }, item_8: Item {
            id: 11, xp: 0, metadata: 0
            }, item_9: Item {
            id: 12, xp: 0, metadata: 0
            }, item_10: Item {
            id: 13, xp: 0, metadata: 0
            }, item_11: Item {
            id: 14, xp: 0, metadata: 0
            }, item_12: Item {
            id: 15, xp: 0, metadata: 0
        },
    };

    assert(bag.is_full() == true, 'Bag should be full');
}
