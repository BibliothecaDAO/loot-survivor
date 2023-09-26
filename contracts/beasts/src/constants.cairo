mod BeastSettings {
    // Controls the health of the first beast in the game
    const STARTER_BEAST_HEALTH: u16 = 3;

    // Controls the level of the first beast in the game
    const STARTER_BEAST_LEVEL: u16 = 1;

    // Controls the minimum damage
    const MINIMUM_DAMAGE: u16 = 2;

    // Controls the strength boost for beasts
    const STRENGTH_BONUS: u16 = 0;

    // Controls minimum health for beasts
    const MINIMUM_HEALTH: u8 = 5;
    const MAXIMUM_HEALTH: u16 = 511; // 2^9 - 1

    // Controls the amount of gold received for slaying a beast
    // relative to XP. The current setting of 2 will result
    // in adventurers receiving a base gold reward of 1/2 XP when
    // slaying beasts. Set this value to 1 to increase gold reward
    // increase it to lower gold reward. Note, unlike XP, the amount
    // of gold received after slaying a beast includes a random bonus
    // between 0%-100%
    const GOLD_BASE_REWARD_DIVISOR: u16 = 2;

    // controls the size of the base gold reward bonus. The higher
    // this number, the smaller the base gold bonus will be. With the
    // setting at 5, the gold reward bonus base is 20% of the earned
    // xp
    const GOLD_REWARD_BONUS_DIVISOR: u16 = 4;

    // controls the range of the gold bonus when slaying beasts
    // the higher this number the wider the range of the gold bonus
    const GOLD_REWARD_BONUS_MAX_MULTPLIER: u128 = 4;

    // control the minimum base gold reward. Note the bonus
    // will be applied to this so even when the minimun is used
    // the actual amount may be slightly higher based on bonus
    const GOLD_REWARD_BASE_MINIMUM: u16 = 4;

    const MINIMUM_XP_REWARD: u16 = 4;

    const BEAST_SPECIAL_NAME_UNLOCK_LEVEL: u8 = 15;

    // controls at what level adventurers will discover random beasts
    // vs starter beasts which are always the same and maximally easy
    const STARTER_BEAST_LEVEL_THRESHOLD: u8 = 1;
}

mod BeastId {
    // ====================================================================================================
    // Magical Beasts
    // ====================================================================================================

    // Magical T1s
    const Warlock: u8 = 1; // A man who practices witchcraft
    const Typhon: u8 =
        2; // The deadliest monster of Greek mythology known as the "Father of All Monsters"
    const Jiangshi: u8 = 3; // A type of reanimated corpse in Chinese legends and folklore
    const Anansi: u8 =
        4; // A trickster god known as the spirit of all knowledge of stories, usually taking the shape of a spider
    const Basilisk: u8 =
        5; // A legendary reptile reputed to be the king of serpents and said to have the power to cause death with a single glance

    // Magical T2s
    const Gorgon: u8 =
        6; // A female creature who turns those who look at her into stone in Greek mythology
    const Kitsune: u8 =
        7; // A fox with the ability to shape-shift into a human form in Japanese folklore
    const Lich: u8 =
        8; // A type of undead creature, often a spellcaster who has become undead to pursue power eternal
    const Chimera: u8 = 9; // A monstrous fire-breathing hybrid creature from Greek mythology
    const Wendigo: u8 =
        10; // A mythical man-eating creature or evil spirit from the folklore of the First Nations Algonquin tribes 

    // Magical T3s
    const Rakshasa: u8 =
        11; // A mythical being from Hindu mythology known to disrupt sacrifices, desecrate graves, and cause harm
    const Werewolf: u8 =
        12; // A human with the ability to shapeshift into a wolf, either purposely or after being placed under a curse
    const Banshee: u8 =
        13; // A female spirit in Irish folklore who heralds the death of a family member by wailing
    const Draugr: u8 = 14; // Undead creatures from Norse mythology
    const Vampire: u8 =
        15; // A creature from folklore that subsists by feeding on the vital essence (usually in the form of blood) of the living

    // Magical T4s
    const Goblin: u8 =
        16; // A monstrous creature from European folklore, first attested in stories from the Middle Ages
    const Ghoul: u8 =
        17; // A demon or monster in Arabian mythology, associated with graveyards and consuming human flesh
    const Wraith: u8 = 18; // An undead creature or a ghost in Scottish dialect
    const Sprite: u8 =
        19; // A broad term referring to a number of preternatural legendary creatures
    const Kappa: u8 = 20; // Amphibious yōkai demons found in traditional Japanese folklore

    // Magical T5s
    const Fairy: u8 =
        21; // A type of mythical being or legendary creature in European folklore, particularly Celtic, Slavic, German, English, and French folklore
    const Leprechaun: u8 =
        22; // A diminutive supernatural being in Irish folklore, classed as a type of solitary fairy
    const Kelpie: u8 = 23; // A shape-changing aquatic spirit of Scottish legend
    const Pixie: u8 =
        24; // A mythical creature of British folklore, considered to be particularly concentrated in the high moorland areas around Devon and Cornwall
    const Gnome: u8 =
        25; // A diminutive spirit in Renaissance magic and alchemy, first introduced by Paracelsus in the 16th century
    // ====================================================================================================

    // ====================================================================================================
    // Hunter Beasts
    // ====================================================================================================

    // Hunter T1s
    const Griffin: u8 =
        26; // Mythical creature with the body of a lion and the head and wings of an eagle
    const Manticore: u8 =
        27; // A Persian legendary creature similar to the sphinx but with a scorpion's tail
    const Phoenix: u8 =
        28; // Mythical bird that lived for five or six centuries in the Arabian desert, after this time burning itself on a funeral pyre and rising from the ashes with renewed youth to live through another cycle.
    const Dragon: u8 =
        29; // Large, powerful reptiles with wings and the ability to breathe fire, known for their immense strength, ferocity, and avarice for treasure
    const Minotaur: u8 =
        30; // A creature with the head of a bull and the body of a man in Greek mythology

    // Hunter T2s
    const Qilin: u8 =
        31; // A mythical hooved chimerical creature known in various East Asian cultures
    const Ammit: u8 =
        32; // An ancient Egyptian demon with a body that was part lion, hippopotamus, and crocodile
    const Nue: u8 = 33; // A Japanese chimera with a monkey's face, tiger's body, and snake tail
    const Skinwalker: u8 =
        34; // A person, in Navajo culture, who can turn into, inhabit, or disguise themselves as an animal
    const Chupacabra: u8 =
        35; // A creature from American folklore that is known for drinking the blood of livestock

    // Hunter T3s
    const Weretiger: u8 = 36; // A creature from Asian mythology, humans who can change into tigers
    const Wyvern: u8 =
        37; // A creature with a dragon's head and wings, a reptilian body, and a tail often ending in a diamond or arrow shape
    const Roc: u8 = 38; // An enormous legendary bird of prey from Middle Eastern mythology
    const Harpy: u8 = 39; // A death spirit with a bird body and a woman's face in Greek mythology
    const Pegasus: u8 = 40; // A divine winged stallion in Greek mythology

    // Hunter T4s
    const Hippogriff: u8 =
        41; // A creature with the front half of an eagle and the back half of a horse from medieval literature
    const Fenrir: u8 = 42; // A monstrous wolf in Norse mythology
    const Jaguar: u8 = 43; // An animal known for its power and agility in various cultures
    const Satori: u8 = 44; // New comment required
    const DireWolf: u8 = 45; // A larger and more powerful version of a wolf from fantasy literature

    // Hunter T5s
    const Bear: u8 =
        46; // large, powerful mammals known for their stocky build, thick fur, and strong claws. Recognized for their remarkable strength.
    const Wolf: u8 =
        47; // Carnivorous mammals known for their social nature and hunting prowess, characterized by their sharp teeth, keen senses, and powerful bodies.
    const Mantis: u8 = 48; // New comment required
    const Spider: u8 =
        49; // Arachnid characterized by eight legs, ability to produce silk, and their predatory nature. Known for their diverse sizes, shapes, and colors.
    const Rat: u8 =
        50; // Small rodents known for their ability to adapt to various environments, characterized by their small size, sharp teeth, and long tails.

    // Brute Beasts
    // Brute T1s
    const Kraken: u8 = 51; // A giant sea monster from Scandinavian folklore
    const Colossus: u8 =
        52; // An exceptionally large and powerful entity from various mythologies and popular culture
    const Balrog: u8 = 53; // A powerful fictional monster in J. R. R. Tolkien's Middle-earth
    const Leviathan: u8 = 54; // A sea monster referenced in the Hebrew Bible
    const Tarrasque: u8 = 55; // A legendary mythical beast from French folklore

    // Brute T2s
    const Titan: u8 = 56; // A race of deities from Greek mythology
    const Nephilim: u8 =
        57; // The offspring of the "sons of God" and the "daughters of men" in the Bible
    const Behemoth: u8 = 58; // A beast from the Book of Job, possibly a dinosaur or an elephant
    const Hydra: u8 = 59; // A serpentine water monster with many heads in Greek and Roman mythology
    const Juggernaut: u8 = 60; // Unstoppable beings from various mythologies and popular culture

    // Brute T3s
    const Oni: u8 = 61; // A kind of yōkai, demon, or troll in Japanese folklore
    const Jotunn: u8 =
        62; // A type of entity contrasted with gods and other figures, such as dwarfs and elves, in Norse mythology
    const Ettin: u8 = 63; // A two-headed giant in English folklore
    const Cyclops: u8 = 64; // One-eyed giants from Greek mythology
    const Giant: u8 = 65; // Humanoid beings of incredible strength and size

    // Brute T4s
    const NemeanLion: u8 = 66; // A vicious monster in Greek mythology that lived at Nemea
    const Berserker: u8 =
        67; // Legendary warrior known for their intense and uncontrollable battle frenzy, displaying heightened strength, endurance, and a disregard for personal safety. They are often depicted as fierce warriors who enter a trance-like state in combat, exhibiting extraordinary ferocity and unleashing devastating attacks upon their enemies.
    const Yeti: u8 = 68; // The Abominable Snowman from Himalayan folklore
    const Golem: u8 = 69; // An animated anthropomorphic being in Jewish folklore
    const Ent: u8 =
        70; // A race of beings in J. R. R. Tolkien's fantasy world Middle-earth who resemble trees

    // Brute T5s
    const Troll: u8 = 71; // A creature from Norse mythology and Scandinavian folklore
    const Bigfoot: u8 =
        72; // A hairy, upright-walking, ape-like creature that dwells in the wilderness
    const Ogre: u8 = 73; // Large, hideous monster beings featured in mythology and fairy tales
    const Orc: u8 =
        74; // Corrupted humanoid creatures with foul appearances, known for their cruelty and viciousness, serving as minions of dark lords, skilled in combat, and dwelling in gloomy places.
    const Skeleton: u8 =
        75; // A mythical creature portrayed in Classical times with the head and tail of a bull and the body of a man

    // If you add beasts, make sure to update MAX_ID below
    const MAX_ID: u8 = 75;
}