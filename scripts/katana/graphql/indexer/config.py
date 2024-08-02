class Config:
    def __init__(self):
        self.BEASTS = {
            1: "Warlock",
            2: "Typhon",
            3: "Jiangshi",
            4: "Anansi",
            5: "Basilisk",
            6: "Gorgon",
            7: "Kitsune",
            8: "Lich",
            9: "Chimera",
            10: "Wendigo",
            11: "Rakshasa",
            12: "Werewolf",
            13: "Banshee",
            14: "Draugr",
            15: "Vampire",
            16: "Goblin",
            17: "Ghoul",
            18: "Wraith",
            19: "Sprite",
            20: "Kappa",
            21: "Fairy",
            22: "Leprechaun",
            23: "Kelpie",
            24: "Pixie",
            25: "Gnome",
            26: "Griffin",
            27: "Manticore",
            28: "Phoenix",
            29: "Dragon",
            30: "Minotaur",
            31: "Qilin",
            32: "Ammit",
            33: "Nue",
            34: "Skinwalker",
            35: "Chupacabra",
            36: "Weretiger",
            37: "Wyvern",
            38: "Roc",
            39: "Harpy",
            40: "Pegasus",
            41: "Hippogriff",
            42: "Fenrir",
            43: "Jaguar",
            44: "Satori",
            45: "DireWolf",
            46: "Bear",
            47: "Wolf",
            48: "Mantis",
            49: "Spider",
            50: "Rat",
            51: "Kraken",
            52: "Colossus",
            53: "Balrog",
            54: "Leviathan",
            55: "Tarrasque",
            56: "Titan",
            57: "Nephilim",
            58: "Behemoth",
            59: "Hydra",
            60: "Juggernaut",
            61: "Oni",
            62: "Jotunn",
            63: "Ettin",
            64: "Cyclops",
            65: "Giant",
            66: "NemeanLion",
            67: "Berserker",
            68: "Yeti",
            69: "Golem",
            70: "Ent",
            71: "Troll",
            72: "Bigfoot",
            73: "Ogre",
            74: "Orc",
            75: "Skeleton",
        }

        self.BEAST_TYPES = {
            # Magical Beasts
            1: 1,
            2: 1,
            3: 1,
            4: 1,
            5: 1,
            6: 1,
            7: 1,
            8: 1,
            9: 1,
            10: 1,
            11: 1,
            12: 1,
            13: 1,
            14: 1,
            15: 1,
            16: 1,
            17: 1,
            18: 1,
            19: 1,
            20: 1,
            21: 1,
            22: 1,
            23: 1,
            24: 1,
            25: 1,
            # Hunter Beasts
            26: 2,
            27: 2,
            28: 2,
            29: 2,
            30: 2,
            31: 2,
            32: 2,
            33: 2,
            34: 2,
            35: 2,
            36: 2,
            37: 2,
            38: 2,
            39: 2,
            40: 2,
            41: 2,
            42: 2,
            43: 2,
            44: 2,
            45: 2,
            46: 2,
            47: 2,
            48: 2,
            49: 2,
            50: 2,
            # Brute Beasts
            51: 3,
            52: 3,
            53: 3,
            54: 3,
            55: 3,
            56: 3,
            57: 3,
            58: 3,
            59: 3,
            60: 3,
            61: 3,
            62: 3,
            63: 3,
            64: 3,
            65: 3,
            66: 3,
            67: 3,
            68: 3,
            69: 3,
            70: 3,
            71: 3,
            72: 3,
            73: 3,
            74: 3,
            75: 3,
        }

        self.BEAST_ATTACK_TYPES = {1: "Magic", 2: "Blade", 3: "Bludgeon"}

        self.ITEMS = {
            1: "Pendant",
            2: "Necklace",
            3: "Amulet",
            4: "Silver Ring",
            5: "Bronze Ring",
            6: "Platinum Ring",
            7: "Titanium Ring",
            8: "Gold Ring",
            9: "Ghost Wand",
            10: "Grave Wand",
            11: "Bone Wand",
            12: "Wand",
            13: "Grimoire",
            14: "Chronicle",
            15: "Tome",
            16: "Book",
            17: "Divine Robe",
            18: "Silk Robe",
            19: "Linen Robe",
            20: "Robe",
            21: "Shirt",
            22: "Crown",
            23: "Divine Hood",
            24: "Silk Hood",
            25: "Linen Hood",
            26: "Hood",
            27: "Brightsilk Sash",
            28: "Silk Sash",
            29: "Wool Sash",
            30: "Linen Sash",
            31: "Sash",
            32: "Divine Slippers",
            33: "Silk Slippers",
            34: "Wool Shoes",
            35: "Linen Shoes",
            36: "Shoes",
            37: "Divine Gloves",
            38: "Silk Gloves",
            39: "Wool Gloves",
            40: "Linen Gloves",
            41: "Gloves",
            42: "Katana",
            43: "Falchion",
            44: "Scimitar",
            45: "Long Sword",
            46: "Short Sword",
            47: "Demon Husk",
            48: "Dragonskin Armor",
            49: "Studded Leather Armor",
            50: "Hard Leather Armor",
            51: "Leather Armor",
            52: "Demon Crown",
            53: "Dragons Crown",
            54: "War Cap",
            55: "Leather Cap",
            56: "Cap",
            57: "Demonhide Belt",
            58: "Dragonskin Belt",
            59: "Studded Leather Belt",
            60: "Hard Leather Belt",
            61: "Leather Belt",
            62: "Demonhide Boots",
            63: "Dragonskin Boots",
            64: "Studded Leather Boots",
            65: "Hard Leather Boots",
            66: "Leather Boots",
            67: "Demons Hands",
            68: "Dragonskin Gloves",
            69: "Studded Leather Gloves",
            70: "Hard Leather Gloves",
            71: "Leather Gloves",
            72: "Warhammer",
            73: "Quarterstaff",
            74: "Maul",
            75: "Mace",
            76: "Club",
            77: "Holy Chestplate",
            78: "Ornate Chestplate",
            79: "Plate Mail",
            80: "Chain Mail",
            81: "Ring Mail",
            82: "Ancient Helm",
            83: "Ornate Helm",
            84: "Great Helm",
            85: "Full Helm",
            86: "Helm",
            87: "Ornate Belt",
            88: "War Belt",
            89: "Plated Belt",
            90: "Mesh Belt",
            91: "Heavy Belt",
            92: "Holy Greaves",
            93: "Ornate Greaves",
            94: "Greaves",
            95: "Chain Boots",
            96: "Heavy Boots",
            97: "Holy Gauntlets",
            98: "Ornate Gauntlets",
            99: "Gauntlets",
            100: "Chain Gloves",
            101: "Heavy Gloves",
        }

        self.CLASSES = {
            1: "Cleric",
            2: "Scout",
            3: "Merchant",
            4: "Warrior",
        }

        self.STATS = {
            2: "Strength",
            3: "Dexterity",
            4: "Vitality",
            5: "Intelligence",
            6: "Wisdom",
            7: "Charisma",
            8: "Luck",
        }

        self.OBSTACLES = {
            # Magical Obstacles
            1: "Demonic Alter",  # T1
            2: "Vortex Of Despair",  # T1
            3: "Eldritch Barrier",  # T1
            4: "Soul Trap",  # T1
            5: "Phantom Vortex",  # T1
            6: "Ectoplasmic Web",  # T2
            7: "Spectral Chains",  # T2
            8: "Infernal Pact",  # T2
            9: "Arcane Explosion",  # T2
            10: "Hypnotic Essence",  # T2
            11: "Mischievous Sprites",  # T3
            12: "Soul Draining Statue",  # T3
            13: "Petrifying Gaze",  # T3
            14: "Summoning Circle",  # T3
            15: "Ethereal Void",  # T3
            16: "Magic Lock",  # T4
            17: "Bewitching Fog",  # T4
            18: "Illusionary Maze",  # T4
            19: "Spellbound Mirror",  # T4
            20: "Ensnaring Shadow",  # T4
            21: "Dark Mist",  # T5
            22: "Curse",  # T5
            23: "Haunting Echo",  # T5
            24: "Hex",  # T5
            25: "Ghostly Whispers",  # T5
            # Sharp Obstacles
            26: "Pendulum Blades",  # T1
            27: "Icy Razor Winds",  # T1
            28: "Acidic Thorns",  # T1
            29: "Dragons Breath",  # T1
            30: "Pendulum Scythe",  # T1
            31: "Flame Jet",  # T2
            32: "Piercing Ice Darts",  # T2
            33: "Glass Sand Storm",  # T2
            34: "Poisoned Dart Wall",  # T2
            35: "Spinning Blade Wheel",  # T2
            36: "Poison Dart",  # T3
            37: "Spiked Tumbleweed",  # T3
            38: "Thunderbolt",  # T3
            39: "Giant Bear Trap",  # T3
            40: "Steel Needle Rain",  # T3
            41: "Spiked Pit",  # T4
            42: "Diamond Dust Storm",  # T4
            43: "Trapdoor Scorpion Pit",  # T4
            44: "Bladed Fan",  # T4
            45: "Bear Trap",  # T4
            46: "Porcupine Quill",  # T5
            47: "Hidden Arrow",  # T5
            48: "Glass Shard",  # T5
            49: "Thorn Bush",  # T5
            50: "Jagged Rocks",  # T5
            # Crushing Obstacles
            51: "Subterranean Tremor",  # T3 (Note: This seems to overwrite 'Collapsing Ceiling')
            52: "Rockslide",  # T1
            53: "Flash Flood",  # T1
            54: "Clinging Roots",  # T1
            55: "Collapsing Cavern",  # T1
            56: "Crushing Walls",  # T2
            57: "Smashing Pillars",  # T2
            58: "Rumbling Catacomb",  # T2
            59: "Whirling Cyclone",  # T2
            60: "Erupting Earth",  # T2
            61: "Subterranean Tremor",  # T3
            62: "Falling Chandelier",  # T3
            63: "Collapsing Bridge",  # T3
            64: "Raging Sandstorm",  # T3
            65: "Avalanching Rocks",  # T3
            66: "Tumbling Boulders",  # T4
            67: "Slamming Iron Gate",  # T4
            68: "Shifting Sandtrap",  # T4
            69: "Erupting Mud Geyser",  # T4
            70: "Crumbling Staircase",  # T4
            71: "Swinging Logs",  # T5
            72: "Unstable Cliff",  # T5
            73: "Toppling Statue",  # T5
            74: "Tumbling Barrels",  # T5
            75: "Rolling Boulder",  # T5
        }

        self.OBSTACLE_TIERS = {
            1: 1,
            2: 2,
            3: 3,
            4: 4,
            5: 5,
            6: 1,
            7: 2,
            8: 3,
            9: 4,
            10: 5,
            11: 1,
            12: 2,
            13: 3,
            14: 4,
            15: 5,
        }

        self.ADVENTURER_STATUS = {
            0: "Idle",
            1: "Battle",
            2: "Travel",
            3: "Quest",
            4: "Dead",
        }

        self.DISCOVERY_TYPES = {
            1: "Beast",
            2: "Obstacle",
            3: "Item",
        }

        self.SUB_DISCOVERY_TYPES = {1: "Health", 2: "Gold", 3: "Loot"}

        self.MATERIALS = {
            0: "Generic",
            1000: "Generic Metal",
            1001: "Ancient Metal",
            1002: "Holy Metal",
            1003: "Ornate Metal",
            1004: "Gold Metal",
            1005: "Silver Metal",
            1006: "Bronze Metal",
            1007: "Platinum Metal",
            1008: "Titanium Metal",
            1009: "Steel Metal",
            2000: "Generic Cloth",
            2001: "Royal Cloth",
            2002: "Divine Cloth",
            2003: "Brightsilk Cloth",
            2004: "Silk Cloth",
            2005: "Wool Cloth",
            2006: "Linen Cloth",
            3000: "Generic Biotic",
            3100: "Demon Generic Biotic",
            3101: "Demon Blood Biotic",
            3102: "Demon Bones Biotic",
            3103: "Demon Brain Biotic",
            3104: "Demon Eyes Biotic",
            3105: "Demon Hide Biotic",
            3106: "Demon Flesh Biotic",
            3107: "Demon Hair Biotic",
            3108: "Demon Heart Biotic",
            3109: "Demon Entrails Biotic",
            3110: "Demon Hands Biotic",
            3111: "Demon Feet Biotic",
            3200: "Dragon Generic Biotic",
            3201: "Dragon Blood Biotic",
            3202: "Dragon Bones Biotic",
            3203: "Dragon Brain Biotic",
            3204: "Dragon Eyes Biotic",
            3205: "Dragon Skin Biotic",
            3206: "Dragon Flesh Biotic",
            3207: "Dragon Hair Biotic",
            3208: "Dragon Heart Biotic",
            3209: "Dragon Entrails Biotic",
            3210: "Dragon Hands Biotic",
            3211: "Dragon Feet Biotic",
            3300: "Animal Generic Biotic",
            3301: "Animal Blood Biotic",
            3302: "Animal Bones Biotic",
            3303: "Animal Brain Biotic",
            3304: "Animal Eyes Biotic",
            3305: "Animal Hide Biotic",
            3306: "Animal Flesh Biotic",
            3307: "Animal Hair Biotic",
            3308: "Animal Heart Biotic",
            3309: "Animal Entrails Biotic",
            3310: "Animal Hands Biotic",
            3311: "Animal Feet Biotic",
            3400: "Human Generic Biotic",
            3401: "Human Blood Biotic",
            3402: "Human Bones Biotic",
            3403: "Human Brain Biotic",
            3404: "Human Eyes Biotic",
            3405: "Human Hide Biotic",
            3406: "Human Flesh Biotic",
            3407: "Human Hair Biotic",
            3408: "Human Heart Biotic",
            3409: "Human Entrails Biotic",
            3410: "Human Hands Biotic",
            3411: "Human Feet Biotic",
            4000: "Generic Paper",
            4001: "Magical Paper",
            5000: "Generic Wood",
            5100: "Generic Hardwood",
            5101: "Walnut Hardwood",
            5102: "Mahogany Hardwood",
            5103: "Maple Hardwood",
            5104: "Oak Hardwood",
            5105: "Rosewood Hardwood",
            5106: "Cherry Hardwood",
            5107: "Balsa Hardwood",
            5108: "Birch Hardwood",
            5109: "Holly Hardwood",
            5200: "Generic Softwood",
            5201: "Cedar Softwood",
            5202: "Pine Softwood",
            5203: "Fir Softwood",
            5204: "Hemlock Softwood",
            5205: "Spruce Softwood",
            5206: "Elder Softwood",
            5207: "Yew Softwood",
        }

        self.ITEM_NAME_PREFIXES = {
            1: "Agony",
            2: "Apocalypse",
            3: "Armageddon",
            4: "Beast",
            5: "Behemoth",
            6: "Blight",
            7: "Blood",
            8: "Bramble",
            9: "Brimstone",
            10: "Brood",
            11: "Carrion",
            12: "Cataclysm",
            13: "Chimeric",
            14: "Corpse",
            15: "Corruption",
            16: "Damnation",
            17: "Death",
            18: "Demon",
            19: "Dire",
            20: "Dragon",
            21: "Dread",
            22: "Doom",
            23: "Dusk",
            24: "Eagle",
            25: "Empyrean",
            26: "Fate",
            27: "Foe",
            28: "Gale",
            29: "Ghoul",
            30: "Gloom",
            31: "Glyph",
            32: "Golem",
            33: "Grim",
            34: "Hate",
            35: "Havoc",
            36: "Honour",
            37: "Horror",
            38: "Hypnotic",
            39: "Kraken",
            40: "Loath",
            41: "Maelstrom",
            42: "Mind",
            43: "Miracle",
            44: "Morbid",
            45: "Oblivion",
            46: "Onslaught",
            47: "Pain",
            48: "Pandemonium",
            49: "Phoenix",
            50: "Plague",
            51: "Rage",
            52: "Rapture",
            53: "Rune",
            54: "Skull",
            55: "Sol",
            56: "Soul",
            57: "Sorrow",
            58: "Spirit",
            59: "Storm",
            60: "Tempest",
            61: "Torment",
            62: "Vengeance",
            63: "Victory",
            64: "Viper",
            65: "Vortex",
            66: "Woe",
            67: "Wrath",
            68: "Lights",
            69: "Shimmering",
        }

        self.ITEM_NAME_SUFFIXES = {
            1: "Bane",
            2: "Root",
            3: "Bite",
            4: "Song",
            5: "Roar",
            6: "Grasp",
            7: "Instrument",
            8: "Glow",
            9: "Bender",
            10: "Shadow",
            11: "Whisper",
            12: "Shout",
            13: "Growl",
            14: "Tear",
            15: "Peak",
            16: "Form",
            17: "Sun",
            18: "Moon",
        }

        self.ITEM_SUFFIXES = {
            1: "Of Power",
            2: "Of Giant",
            3: "Of Titans",
            4: "Of Skill",
            5: "Of Perfection",
            6: "Of Brilliance",
            7: "Of Enlightenment",
            8: "Of Protection",
            9: "Of Anger",
            10: "Of Rage",
            11: "Of Fury",
            12: "Of Vitriol",
            13: "Of The Fox",
            14: "Of Detection",
            15: "Of Reflection",
            16: "Of The Twins",
        }

        self.SLOTS = {
            1: "Weapon",
            2: "Chest",
            3: "Head",
            4: "Waist",
            5: "Foot",
            6: "Hand",
            7: "Neck",
            8: "Ring",
        }

        self.ITEM_TYPES = {
            1: "Necklace",
            2: "Ring",
            3: "Magic",
            4: "Cloth",
            5: "Blade",
            6: "Hide",
            7: "Bludgeon",
            8: "Metal",
        }

        self.ITEM_TIERS = {
            1: 1,  # Pendant
            2: 1,  # Necklace
            3: 1,  # Amulet
            4: 2,  # SilverRing
            5: 3,  # BronzeRing
            6: 1,  # PlatinumRing
            7: 1,  # TitaniumRing
            8: 1,  # GoldRing
            9: 1,  # GhostWand
            10: 2,  # GraveWand
            11: 3,  # BoneWand
            12: 5,  # Wand
            13: 1,  # Grimoire
            14: 2,  # Chronicle
            15: 3,  # Tome
            16: 5,  # Book
            17: 1,  # DivineRobe
            18: 2,  # SilkRobe
            19: 3,  # LinenRobe
            20: 4,  # Robe
            21: 5,  # Shirt
            22: 1,  # Crown
            23: 2,  # DivineHood
            24: 3,  # SilkHood
            25: 4,  # LinenHood
            26: 5,  # Hood
            27: 1,  # BrightsilkSash
            28: 2,  # SilkSash
            29: 3,  # WoolSash
            30: 4,  # LinenSash
            31: 5,  # Sash
            32: 1,  # DivineSlippers
            33: 2,  # SilkSlippers
            34: 3,  # WoolShoes
            35: 4,  # LinenShoes
            36: 5,  # Shoes
            37: 1,  # DivineGloves
            38: 2,  # SilkGloves
            39: 3,  # WoolGloves
            40: 4,  # LinenGloves
            41: 5,  # Gloves
            42: 1,  # Katana
            43: 2,  # Falchion
            44: 3,  # Scimitar
            45: 4,  # LongSword
            46: 5,  # ShortSword
            47: 1,  # DemonHusk
            48: 2,  # DragonskinArmor
            49: 3,  # StuddedLeatherArmor
            50: 4,  # HardLeatherArmor
            51: 5,  # LeatherArmor
            52: 1,  # DemonCrown
            53: 2,  # DragonsCrown
            54: 3,  # WarCap
            55: 4,  # LeatherCap
            56: 5,  # Cap
            57: 1,  # DemonhideBelt
            58: 2,  # DragonskinBelt
            59: 3,  # StuddedLeatherBelt
            60: 4,  # HardLeatherBelt
            61: 5,  # LeatherBelt
            62: 1,  # DemonhideBoots
            63: 2,  # DragonskinBoots
            64: 3,  # StuddedLeatherBoots
            65: 4,  # HardLeatherBoots
            66: 5,  # LeatherBoots
            67: 1,  # DemonsHands
            68: 2,  # DragonskinGloves
            69: 3,  # StuddedLeatherGloves
            70: 4,  # HardLeatherGloves
            71: 5,  # LeatherGloves
            72: 1,  # Warhammer
            73: 2,  # Quarterstaff
            74: 3,  # Maul
            75: 4,  # Mace
            76: 5,  # Club
            77: 1,  # HolyChestplate
            78: 2,  # OrnateChestplate
            79: 3,  # PlateMail
            80: 4,  # ChainMail
            81: 5,  # RingMail
            82: 1,  # AncientHelm
            83: 2,  # OrnateHelm
            84: 3,  # GreatHelm
            85: 4,  # FullHelm
            86: 5,  # Helm
            87: 1,  # OrnateBelt
            88: 2,  # WarBelt
            89: 3,  # PlatedBelt
            90: 4,  # MeshBelt
            91: 5,  # HeavyBelt
            92: 1,  # HolyGreaves
            93: 2,  # OrnateGreaves
            94: 3,  # Greaves
            95: 4,  # ChainBoots
            96: 5,  # HeavyBoots
            97: 1,  # HolyGauntlets
            98: 2,  # OrnateGauntlets
            99: 3,  # Gauntlets
            100: 4,  # ChainGloves
            101: 5,  # HeavyGloves
        }

        self.BEAST_TIERS = {
            # Magical T1s
            1: 1,
            2: 1,
            3: 1,
            4: 1,
            5: 1,
            # Magical T2s
            6: 2,
            7: 2,
            8: 2,
            9: 2,
            10: 2,
            # Magical T3s
            11: 3,
            12: 3,
            13: 3,
            14: 3,
            15: 3,
            # Magical T4s
            16: 4,
            17: 4,
            18: 4,
            19: 4,
            20: 4,
            # Magical T5s
            21: 5,
            22: 5,
            23: 5,
            24: 5,
            25: 5,
            # Hunter T1s
            26: 1,
            27: 1,
            28: 1,
            29: 1,
            30: 1,
            # Hunter T2s
            31: 2,
            32: 2,
            33: 2,
            34: 2,
            35: 2,
            # Hunter T3s
            36: 3,
            37: 3,
            38: 3,
            39: 3,
            40: 3,
            # Hunter T4s
            41: 4,
            42: 4,
            43: 4,
            44: 4,
            45: 4,
            # Hunter T5s
            46: 5,
            47: 5,
            48: 5,
            49: 5,
            50: 5,
            # Brute T1s
            51: 1,
            52: 1,
            53: 1,
            54: 1,
            55: 1,
            # Brute T2s
            56: 2,
            57: 2,
            58: 2,
            59: 2,
            60: 2,
            # Brute T3s
            61: 3,
            62: 3,
            63: 3,
            64: 3,
            65: 3,
            # Brute T4s
            66: 4,
            67: 4,
            68: 4,
            69: 4,
            70: 4,
            # Brute T5s
            71: 5,
            72: 5,
            73: 5,
            74: 5,
            75: 5,
        }

        self.ATTACKERS = {1: "Adventurer", 2: "Beast"}
