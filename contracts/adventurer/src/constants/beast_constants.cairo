mod BeastId {
    const Phoenix: u8 = 1;
    const Griffin: u8 = 2;
    const Minotaur: u8 = 3;
    const Basilisk: u8 = 4;
    const Gnome: u8 = 5;

    const Wraith: u8 = 6;
    const Ghoul: u8 = 7;
    const Goblin: u8 = 8;
    const Skeleton: u8 = 9;
    const Golem: u8 = 10;

    const Giant: u8 = 11;
    const Yeti: u8 = 12;
    const Orc: u8 = 13;
    const Beserker: u8 = 14;
    const Ogre: u8 = 15;

    const Dragon: u8 = 16;
    const Vampire: u8 = 17;
    const Werewolf: u8 = 18;
    const Spider: u8 = 19;
    const Rat: u8 = 20;

    // If you add beasts, make sure to update MAX_ID below
    // making this u64 as it's commonly used to select a random beast based
    // on entropy variables which are u64 based
    const MAX_ID: u64 = 20;
}

mod BeastTier {
    const Phoenix: u8 = 1;
    const Griffin: u8 = 2;
    const Minotaur: u8 = 3;
    const Basilisk: u8 = 4;
    const Gnome: u8 = 5;

    const Wraith: u8 = 2;
    const Ghoul: u8 = 3;
    const Goblin: u8 = 2;
    const Skeleton: u8 = 3;
    const Golem: u8 = 1;

    const Giant: u8 = 1;
    const Yeti: u8 = 2;
    const Orc: u8 = 3;
    const Beserker: u8 = 4;
    const Ogre: u8 = 5;

    const Dragon: u8 = 1;
    const Vampire: u8 = 2;
    const Werewolf: u8 = 3;
    const Spider: u8 = 4;
    const Rat: u8 = 5;
}

// TODO: Ideally these would use loot::statistics::constants::Type;
// @loaf to look into "Only literal constants are currently supported." atm
mod BeastAttackType {
    const Phoenix: u8 = 1;
    const Griffin: u8 = 1;
    const Minotaur: u8 = 1;
    const Basilisk: u8 = 1;
    const Gnome: u8 = 1;

    const Wraith: u8 = 1;
    const Ghoul: u8 = 1;
    const Goblin: u8 = 3;
    const Skeleton: u8 = 3;
    const Golem: u8 = 3;

    const Giant: u8 = 3;
    const Yeti: u8 = 3;
    const Orc: u8 = 3;
    const Beserker: u8 = 3;
    const Ogre: u8 = 3;

    const Dragon: u8 = 3;
    const Vampire: u8 = 3;
    const Werewolf: u8 = 3;
    const Spider: u8 = 3;
    const Rat: u8 = 3;
}

// TODO: Ideally these would use loot::statistics::constants::Type;
// @loaf to look into "Only literal constants are currently supported." atm
mod BeastArmorType {
    const Phoenix: u8 = 1;
    const Griffin: u8 = 1;
    const Minotaur: u8 = 1;
    const Basilisk: u8 = 1;
    const Gnome: u8 = 1;

    const Wraith: u8 = 1;
    const Ghoul: u8 = 1;
    const Goblin: u8 = 3;
    const Skeleton: u8 = 3;
    const Golem: u8 = 3;

    const Giant: u8 = 3;
    const Yeti: u8 = 3;
    const Orc: u8 = 3;
    const Beserker: u8 = 3;
    const Ogre: u8 = 3;

    const Dragon: u8 = 3;
    const Vampire: u8 = 3;
    const Werewolf: u8 = 3;
    const Spider: u8 = 3;
    const Rat: u8 = 3;
}

mod BeastSlotIds {
    const Health: u8 = 0;
    const Adventurer: u8 = 1;
    const XP: u8 = 2;
    const Level: u8 = 3;
    const SlainOnDate: u8 = 4;
}

// TODO: Ideally these would use loot::statistics::constants::Slot;
// @loaf to look into "Only literal constants are currently supported." atm
mod BeastAttackLocation {
    const Phoenix: u8 = 3;
    const Griffin: u8 = 2;
    const Minotaur: u8 = 6;
    const Basilisk: u8 = 4;
    const Gnome: u8 = 5;

    const Wraith: u8 = 2;
    const Ghoul: u8 = 6;
    const Goblin: u8 = 4;
    const Skeleton: u8 = 5;
    const Golem: u8 = 3;

    const Giant: u8 = 6;
    const Yeti: u8 = 4;
    const Orc: u8 = 5;
    const Beserker: u8 = 3;
    const Ogre: u8 = 2;

    const Dragon: u8 = 4;
    const Vampire: u8 = 5;
    const Werewolf: u8 = 3;
    const Spider: u8 = 2;
    const Rat: u8 = 6;
}
