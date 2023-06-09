mod loot;
mod statistics;
// #[derive(Copy, Drop, Clone)]
// struct Item {
//     itemId: u8,
//     xp: u16,
//     prefix1: u8,
//     prefix2: u8,
//     suffix: u8,
//     isEquipped: bool,
// }

// #[derive(Copy, Drop)]
// struct Beast {
//     beastId: u8,
//     level: u16,
//     health: u16,
//     prefix1: u8,
//     prefix2: u8,
//     suffix: u8,
// }

// #[derive(Copy, Drop)]
// struct Adventurer {
//     Name: u64, // name
//     Health: u16, // health
//     XP: u32, // xp 
//     // Adventurers have 7 Stats
//     // 3 Physical
//     Strength: u8,
//     Dexterity: u8,
//     Vitality: u8,
//     // 3 Mental
//     Intelligence: u8,
//     Wisdom: u8,
//     Charisma: u8,
//     // 1 Meta Physical
//     Luck: u8,
//     // Adventurers can carry a maximum of 16 items
//     Item1: Item, // starter weapon (wand) 
//     Item2: Item, // first item purchased (katana)
//     Item3: Item, // second item purchased
//     Item4: Item, // third item purchased
//     Item5: Item,
//     Item6: Item,
//     Item7: Item,
//     Item8: Item,
//     Item9: Item,
//     Item10: Item,
//     Item11: Item,
//     Item12: Item,
//     Item13: Item,
//     Item14: Item,
//     Item15: Item,
//     Item16: Item,
//     // Adventurer in battle will have a beast assigned to them
//     Beast: Beast,
//     // Denotes if the adventurer has a stat 
//     stat_upgrade_available: bool,
// }

// fn item_array(adventurer: @Adventurer) -> Array<Item> {
//     let mut arr = ArrayTrait::<Item>::new();

//     if *adventurer.Item1.itemId != 0 {
//         arr.append(*adventurer.Item1);
//     } else {
//         return arr;
//     }

//     if *adventurer.Item2.itemId != 0 {
//         arr.append(*adventurer.Item2);
//     } else {
//         return arr;
//     }

//     if *adventurer.Item3.itemId != 0 {
//         arr.append(*adventurer.Item3);
//     } else {
//         return arr;
//     }

//     if *adventurer.Item4.itemId != 0 {
//         arr.append(*adventurer.Item4);
//     } else {
//         return arr;
//     }

//     if *adventurer.Item5.itemId != 0 {
//         arr.append(*adventurer.Item5);
//     } else {
//         return arr;
//     }

//     if *adventurer.Item6.itemId != 0 {
//         arr.append(*adventurer.Item6);
//     } else {
//         return arr;
//     }

//     return arr;
// // let mut i: usize = 0;

// // loop {
// //     if *arr.at(i).isEquipped == true {
// //         break ();
// //     }
// //     i += 1;
// // };

// // return *arr.at(i);
// }


