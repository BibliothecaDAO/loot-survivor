mod BeastSettings {

    // Controls the health of the first beast in the game
    const STARTER_BEAST_HEALTH: u16 = 5;

    // Controls the level of the first beast in the game
    const STARTER_BEAST_LEVEL: u16 = 1;

    // Controls the minimum damage
    const MINIMUM_DAMAGE: u16 = 4;

    // Controls the strength boost for beasts
    const STRENGTH_BONUS: u16 = 0;

    // Controls minimum health for beasts
    const MINIMUM_HEALTH: u8 = 5;

    // Controls the amount of gold received for slaying a beast
    // relative to XP. The current setting of 2 will result
    // in adventurers receiving a base gold reward of 1/2 XP when
    // slaying beasts. Set this value to 1 to increase gold reward
    // increase it to lower gold reward. Note, unlike XP, the amount
    // of gold received after slaying a beast includes a random bonus
    // between 0%-100%
    const GOLD_REWARD_DIVISOR: u16 = 2;

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

    const XP_REWARD_MINIMUM: u16 = 4;

    const BEAST_SPECIAL_NAME_UNLOCK_LEVEL: u8 = 15;
}

mod BeastId {
    // ====================================================================================================
    // Magical Beasts
    // ====================================================================================================

    // Magical T1s
    const Warlock: u8 = 1; // A man who practices witchcraft
    const Rakshasa: u8 =
        2; // A mythical being from Hindu mythology known to disrupt sacrifices, desecrate graves, and cause harm
    const Jiangshi: u8 = 3; // A type of reanimated corpse in Chinese legends and folklore
    const Kitsune: u8 =
        4; // A fox with the ability to shape-shift into a human form in Japanese folklore
    const Basilisk: u8 =
        5; // A legendary reptile reputed to be the king of serpents and said to have the power to cause death with a single glance

    // Magical T2s
    const Gorgon: u8 =
        6; // A female creature who turns those who look at her into stone in Greek mythology
    const Anansi: u8 =
        7; // A trickster god known as the spirit of all knowledge of stories, usually taking the shape of a spider
    const Lich: u8 =
        8; // A type of undead creature, often a spellcaster who has become undead to pursue power eternal
    const Chimera: u8 = 9; // A monstrous fire-breathing hybrid creature from Greek mythology
    const Wendigo: u8 =
        10; // A mythical man-eating creature or evil spirit from the folklore of the First Nations Algonquin tribes 

    // Magical T3s
    const Cerberus: u8 =
        11; // A multi-headed dog that guards the gates of the Underworld to prevent the dead from leaving in Greek mythology
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
    const Pixie: u8 =
        18; // A mythical creature of British folklore, considered to be particularly concentrated in the high moorland areas around Devon and Cornwall
    const Sprite: u8 =
        19; // A broad term referring to a number of preternatural legendary creatures
    const Kappa: u8 = 20; // Amphibious yōkai demons found in traditional Japanese folklore

    // Magical T5s
    const Fairy: u8 =
        21; // A type of mythical being or legendary creature in European folklore, particularly Celtic, Slavic, German, English, and French folklore
    const Leprechaun: u8 =
        22; // A diminutive supernatural being in Irish folklore, classed as a type of solitary fairy
    const Kelpie: u8 = 23; // A shape-changing aquatic spirit of Scottish legend
    const Wraith: u8 = 24; // An undead creature or a ghost in Scottish dialect
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
    const Harpy: u8 = 31; // A death spirit with a bird body and a woman's face in Greek mythology
    const Arachne: u8 = 32; // A skilled weaver in Greek mythology who was turned into a spider
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
    const Qilin: u8 =
        39; // A mythical hooved chimerical creature known in various East Asian cultures
    const Pegasus: u8 = 40; // A divine winged stallion in Greek mythology

    // Hunter T4s
    const Hippogriff: u8 =
        41; // A creature with the front half of an eagle and the back half of a horse from medieval literature
    const Fenrir: u8 = 42; // A monstrous wolf in Norse mythology
    const Jaguar: u8 = 43; // An animal known for its power and agility in various cultures
    const Ammit: u8 =
        44; // An ancient Egyptian demon with a body that was part lion, hippopotamus, and crocodile
    const DireWolf: u8 = 45; // A larger and more powerful version of a wolf from fantasy literature

    // Hunter T5s
    const Bear: u8 =
        46; // large, powerful mammals known for their stocky build, thick fur, and strong claws. Recognized for their remarkable strength.
    const Wolf: u8 =
        47; // Carnivorous mammals known for their social nature and hunting prowess, characterized by their sharp teeth, keen senses, and powerful bodies.
    const Scorpion: u8 =
        48; // Arachnid characterized by their segmented body, a pair of pincers, and a long, curved tail ending in a venomous stinger. They are known for their venomous nature and are often recognized by their menacing appearance.
    const Spider: u8 =
        49; // Arachnid characterized by eight legs, ability to produce silk, and their predatory nature. Known for their diverse sizes, shapes, and colors.
    const Rat: u8 =
        50; // Small rodents known for their ability to adapt to various environments, characterized by their small size, sharp teeth, and long tails.
    // ====================================================================================================

    // ====================================================================================================
    // Brute Beasts
    // ====================================================================================================

    // Brute T1s
    const Cyclops: u8 = 51; // One-eyed giants from Greek mythology
    const Golem: u8 = 52; // An animated anthropomorphic being in Jewish folklore
    const Titan: u8 = 53; // A race of deities from Greek mythology
    const Yeti: u8 = 54; // The Abominable Snowman from Himalayan folklore
    const NemeanLion: u8 = 55; // A vicious monster in Greek mythology that lived at Nemea

    // Brute T2s
    const Oni: u8 = 56; // A kind of yōkai, demon, or troll in Japanese folklore
    const Ogre: u8 = 57; // Large, hideous monster beings featured in mythology and fairy tales
    const Juggernaut: u8 = 58; // Unstoppable beings from various mythologies and popular culture
    const Bigfoot: u8 =
        59; // A hairy, upright-walking, ape-like creature that dwells in the wilderness
    const Orc: u8 =
        60; // Corrupted humanoid creatures with foul appearances, known for their cruelty and viciousness, serving as minions of dark lords, skilled in combat, and dwelling in gloomy places.

    // Brute T3s
    const Behemoth: u8 = 61; // A beast from the Book of Job, possibly a dinosaur or an elephant
    const Ent: u8 =
        62; // A race of beings in J. R. R. Tolkien's fantasy world Middle-earth who resemble trees
    const Giant: u8 = 63; // Humanoid beings of incredible strength and size
    const Kraken: u8 = 64; // A giant sea monster from Scandinavian folklore
    const Leviathan: u8 = 65; // A sea monster referenced in the Hebrew Bible

    // Brute T4s
    const Colossus: u8 =
        66; // An exceptionally large and powerful entity from various mythologies and popular culture
    const Nephilim: u8 =
        67; // The offspring of the "sons of God" and the "daughters of men" in the Bible
    const Tarrasque: u8 = 68; // A legendary mythical beast from French folklore
    const Beserker: u8 =
        69; // Legendary warrior known for their intense and uncontrollable battle frenzy, displaying heightened strength, endurance, and a disregard for personal safety. They are often depicted as fierce warriors who enter a trance-like state in combat, exhibiting extraordinary ferocity and unleashing devastating attacks upon their enemies.
    const Balrog: u8 = 70; // A powerful fictional monster in J. R. R. Tolkien's Middle-earth

    // Brute T5s
    const Ettin: u8 = 71; // A two-headed giant in English folklore
    const Jotunn: u8 =
        72; // A type of entity contrasted with gods and other figures, such as dwarfs and elves, in Norse mythology
    const Hydra: u8 = 73; // A serpentine water monster with many heads in Greek and Roman mythology
    const Skeleton: u8 =
        74; // A mythical creature portrayed in Classical times with the head and tail of a bull and the body of a man
    const Troll: u8 = 75; // A creature from Norse mythology and Scandinavian folklore


    // If you add beasts, make sure to update MAX_ID below
    // making this u128 as it's commonly used to select a random beast based
    // on entropy variables which are u128 based
    const MAX_ID: u128 = 75;
}