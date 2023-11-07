import { ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import BN from "bn.js";
import { z } from "zod";
import { Adventurer, Item, ItemPurchase } from "@/app/types";
import { GameData } from "@/app/lib/data/GameData";
import {
  itemCharismaDiscount,
  itemBasePrice,
  itemMinimumPrice,
  potionBasePrice,
} from "@/app/lib/constants";
import { deathMessages } from "@/app/lib/constants";
import { getBlock } from "@/app/api/api";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatNumber(num: number): string {
  if (Math.abs(num) >= 1000000) {
    return parseFloat((num / 1000000).toFixed(2)) + "m";
  } else if (Math.abs(num) >= 1000) {
    return parseFloat((num / 1000).toFixed(2)) + "k";
  } else {
    return num.toFixed(0);
  }
}

export function indexAddress(address: string) {
  const newHex =
    address.substring(0, 2) + address.substring(3).replace(/^0+/, "");
  return newHex;
}

export function padAddress(address: string) {
  if (address && address !== "") {
    const length = address.length;
    const neededLength = 66 - length;
    let zeros = "";
    for (var i = 0; i < neededLength; i++) {
      zeros += "0";
    }
    const newHex = address.substring(0, 2) + zeros + address.substring(2);
    return newHex;
  } else {
    return "";
  }
}

export function isChecksumAddress(address: string) {
  return /^0x[0-9a-f]{63,64}$/.test(address);
}

export function displayAddress(string: string) {
  if (string === undefined) return "unknown";
  return string.substring(0, 6) + "..." + string.substring(string.length - 4);
}

const P = new BN(
  "800000000000011000000000000000000000000000000000000000000000001",
  16
);

export function feltToString(felt: number) {
  const newStrB = Buffer.from(felt.toString(16), "hex");
  return newStrB.toString();
}

export function stringToFelt(str: string) {
  return "0x" + Buffer.from(str).toString("hex");
}

export function toNegativeNumber(felt: BN) {
  const added = felt.sub(P);
  return added.abs() < felt.abs() ? added : felt;
}

type DataDictionary = Record<number, string>;

export function getValueFromKey(
  data: DataDictionary,
  key: number
): string | null {
  return data[key] || null;
}

export function getKeyFromValue(
  data: DataDictionary,
  value: string
): string | null {
  for (const key in data) {
    if (data[key] === value) {
      return key;
    }
  }
  return null;
}

export function groupBySlot(items: Item[]) {
  const groups: Dictionary = {};
  groups["All"] = [];
  items.forEach((item) => {
    const { slot } = getItemData(item.item ?? "");
    if (slot) {
      if (!groups[slot]) {
        groups[slot] = [];
      }

      groups[slot].push(item);
    }
    groups["All"].push(item);
  });

  return groups;
}

type Dictionary = { [key: string]: Item[] };

export const sortByKey = (key: string) => {
  return (a: Dictionary, b: Dictionary) => {
    if (a[key] < b[key]) {
      return -1;
    } else if (a[key] > b[key]) {
      return 1;
    } else {
      return 0;
    }
  };
};

export const formatTime = (date: Date) => {
  return (
    date.toISOString().slice(0, 10) + " " + date.toISOString().slice(11, 19)
  );
};

export const formatTimeSeconds = (totalSeconds: number) => {
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds - hours * 3600) / 60);
  const seconds = totalSeconds % 60;
  return `${minutes.toString().padStart(2, "0")}:${seconds
    .toString()
    .padStart(2, "0")}`;
};

export function shortenHex(hexString: string, numDigits = 6) {
  if (hexString?.length <= numDigits) {
    return hexString;
  }

  const halfDigits = Math.floor(numDigits / 2);
  const firstHalf = hexString.slice(0, halfDigits);
  const secondHalf = hexString.slice(-halfDigits);
  return `${firstHalf}...${secondHalf}`;
}

export function convertTime(time: number) {
  const dateTime = new Date(time);

  // Convert the offset to milliseconds
  const currentTimezoneOffsetMinutes = new Date().getTimezoneOffset() * -1;
  const timezoneOffsetMilliseconds = currentTimezoneOffsetMinutes * 60 * 1000;

  const TimeUTC = dateTime.getTime() + timezoneOffsetMilliseconds;
  return TimeUTC;
}

export function getRankFromList(id: number, data: Adventurer[]) {
  return data.findIndex((data) => data.id === id);
}

export const getRandomNumber = (to: number) => {
  return (Math.floor(Math.random() * to) + 1).toString();
};

export function getOrdinalSuffix(n: number): string {
  let j = n % 10;
  let k = n % 100;

  if (j == 1 && k != 11) {
    return n + "st";
  }

  if (j == 2 && k != 12) {
    return n + "nd";
  }

  if (j == 3 && k != 13) {
    return n + "rd";
  }

  return n + "th";
}

export function calculateLevel(xp: number) {
  return Math.max(Math.floor(Math.sqrt(xp)), 1);
}

export function processItemName(item: Item) {
  if (item) {
    if (item.special2 && item.special3 && calculateLevel(item.xp ?? 0) >= 20) {
      return `${item.special2} ${item.special3} ${item.item} ${item.special1} +1`;
    } else if (item.special2 && item.special1) {
      return `${item.special2} ${item.special3} ${item.item} ${item.special1}`;
    } else if (item.special1) {
      return `${item.item} ${item.special1}`;
    } else {
      return `${item.item}`;
    }
  }
}

export function getItemData(item: string) {
  const gameData = new GameData();

  const item_name_format = item.replaceAll(" ", "");
  const tier = gameData.ITEM_TIERS[item_name_format];
  const type =
    gameData.ITEM_TYPES[parseInt(getKeyFromValue(gameData.ITEMS, item) ?? "")];
  const slot = gameData.ITEM_SLOTS[item_name_format];
  return { tier, type, slot };
}

export function processBeastName(
  beast: string,
  special2: string,
  special3: string
) {
  if (special2 && special3) {
    return `"${special2} ${special3}" ${beast}`;
  } else {
    return `${beast}`;
  }
}

export function getBeastData(beast: string) {
  const gameData = new GameData();
  const tier =
    gameData.BEAST_TIERS[
      parseInt(getKeyFromValue(gameData.BEASTS, beast) ?? "")
    ];
  const attack =
    gameData.BEAST_ATTACK_TYPES[
      gameData.BEAST_TYPES[
        parseInt(getKeyFromValue(gameData.BEASTS, beast) ?? "")
      ]
    ];
  const armor =
    gameData.BEAST_ARMOR_TYPES[
      gameData.BEAST_TYPES[
        parseInt(getKeyFromValue(gameData.BEASTS, beast) ?? "")
      ]
    ];
  const image = `/monsters/${beast.toLowerCase()}.png`;
  return { tier, attack, armor, image };
}

export function getRandomElement(arr: string[]): string {
  if (arr.length === 0) {
    throw new Error("Array must not be empty.");
  }
  const randomIndex = Math.floor(Math.random() * arr.length);
  return arr[randomIndex];
}

type MyDict = { [key: string]: Item };

export function dedupeByValue(arr: MyDict[], key: string): MyDict[] {
  const seen = new Set();
  return arr.filter((item) => {
    const val = item[key];
    if (seen.has(val)) {
      return false;
    }
    seen.add(val);
    return true;
  });
}

export function capitalizeFirstLetter(str: string) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

export function checkAvailableSlots(ownedItems: Item[]) {
  if (ownedItems.length < 20) {
    return true;
  } else {
    return false;
  }
}

export function getItemPrice(tier: number, charisma: number) {
  const price = (6 - tier) * itemBasePrice - itemCharismaDiscount * charisma;
  if (price < itemMinimumPrice) {
    return itemMinimumPrice;
  } else {
    return price;
  }
}

export function getPotionPrice(adventurerLevel: number, charisma: number) {
  return Math.max(adventurerLevel - potionBasePrice * charisma, 1);
}

export function isFirstElement<T>(arr: T[], element: T): boolean {
  return arr[0] === element;
}

export function removeElement(arr: string[], value: string) {
  const index = arr.lastIndexOf(value);

  if (index > -1) {
    // Check if there's more than one instance of the value
    if (arr.indexOf(value) !== arr.lastIndexOf(value)) {
      // If there's more than one instance, just remove the last one
      arr.splice(index, 1);
    } else {
      // If there's only one instance, remove all
      while (arr.indexOf(value) !== -1) {
        arr.splice(arr.indexOf(value), 1);
      }
    }
  }

  return arr;
}

export function countOccurrences<T>(arr: T[], value: T): number {
  return arr.filter((item) => item === value).length;
}

export function chunkArray<T>(array: T[], chunkSize: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < array?.length; i += chunkSize) {
    const nextChunk = array?.slice(i, i + chunkSize);
    chunks.push(nextChunk);
    if (nextChunk.length < chunkSize) break; // Stop if we've hit the end of the array
  }
  return chunks;
}

export function isObject(value: any): value is object {
  return typeof value === "object" && !Array.isArray(value);
}

export function convertToBoolean(value: number): boolean {
  return value === 1;
}

export function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export const uint256Schema = z.object({
  low: z.bigint(),
  high: z.bigint(),
});

export const balanceSchema = z.object({
  balance: uint256Schema,
});

export function getDeathMessageByRank(rank: number): string {
  // The || {} is to prevent destructure error in case find returns undefined
  if (rank === 0) {
    return "Better luck next time - You can improve!";
  }

  const { message } = deathMessages.find((item) => rank <= item.rank) || {};

  return message || "Better luck next time - You can improve!";
}

export const fetchAverageBlockTime = async (
  currentBlock: number,
  numberOfBlocks: number
) => {
  try {
    let totalTimeInterval = 0;

    for (let i = currentBlock - numberOfBlocks; i < currentBlock; i++) {
      const currentBlockData = await getBlock(i);
      const nextBlockData = await getBlock(i + 1);

      const timeInterval = nextBlockData.timestamp - currentBlockData.timestamp;
      totalTimeInterval += timeInterval;
    }
    const averageTime = totalTimeInterval / numberOfBlocks;
    return averageTime;
  } catch (error) {
    console.error("Error:", error);
  }
};

export const fetchBlockTime = async (currentBlock: number) => {
  try {
    const currentBlockData = await getBlock(currentBlock);
    return currentBlockData.timestamp;
  } catch (error) {
    console.error("Error:", error);
  }
};

export const calculateVitBoostRemoved = (
  purchases: ItemPurchase[],
  adventurer: Adventurer,
  items: Item[]
) => {
  const gameData = new GameData();
  const equippedItems = purchases.filter((purchase) => purchase.equip === "1");
  const itemStrings = equippedItems.map(
    (purchase) => gameData.ITEMS[parseInt(purchase?.item) ?? 0]
  );
  const slotStrings = itemStrings.map(
    (itemString) => gameData.ITEM_SLOTS[itemString.split(" ").join("")]
  );

  // loop through slots and check what item is equipped
  const unequippedSuffixBoosts = [];
  for (const slot of slotStrings) {
    if (slot === "Weapon") {
      unequippedSuffixBoosts.push(
        gameData.ITEM_SUFFIX_BOOST[
          parseInt(
            getKeyFromValue(
              gameData.ITEM_SUFFIXES,
              items.find((item) => item.item === adventurer.weapon)?.special1 ??
                ""
            ) ?? "0"
          )
        ]
      );
    }
    if (slot === "Chest") {
      unequippedSuffixBoosts.push(
        gameData.ITEM_SUFFIX_BOOST[
          parseInt(
            getKeyFromValue(
              gameData.ITEM_SUFFIXES,
              items.find((item) => item.item === adventurer.chest)?.special1 ??
                ""
            ) ?? "0"
          )
        ]
      );
    }
    if (slot === "Head") {
      unequippedSuffixBoosts.push(
        gameData.ITEM_SUFFIX_BOOST[
          parseInt(
            getKeyFromValue(
              gameData.ITEM_SUFFIXES,
              items.find((item) => item.item === adventurer.head)?.special1 ??
                ""
            ) ?? "0"
          )
        ]
      );
    }
    if (slot === "Waist") {
      unequippedSuffixBoosts.push(
        gameData.ITEM_SUFFIX_BOOST[
          parseInt(
            getKeyFromValue(
              gameData.ITEM_SUFFIXES,
              items.find((item) => item.item === adventurer.waist)?.special1 ??
                ""
            ) ?? "0"
          )
        ]
      );
    }
    if (slot === "Foot") {
      unequippedSuffixBoosts.push(
        gameData.ITEM_SUFFIX_BOOST[
          parseInt(
            getKeyFromValue(
              gameData.ITEM_SUFFIXES,
              items.find((item) => item.item === adventurer.foot)?.special1 ??
                ""
            ) ?? "0"
          )
        ]
      );
    }
    if (slot === "Hand") {
      unequippedSuffixBoosts.push(
        gameData.ITEM_SUFFIX_BOOST[
          parseInt(
            getKeyFromValue(
              gameData.ITEM_SUFFIXES,
              items.find((item) => item.item === adventurer.hand)?.special1 ??
                ""
            ) ?? "0"
          )
        ]
      );
    }
    if (slot === "Neck") {
      unequippedSuffixBoosts.push(
        gameData.ITEM_SUFFIX_BOOST[
          parseInt(
            getKeyFromValue(
              gameData.ITEM_SUFFIXES,
              items.find((item) => item.item === adventurer.neck)?.special1 ??
                ""
            ) ?? "0"
          )
        ]
      );
    }
    if (slot === "Ring") {
      unequippedSuffixBoosts.push(
        gameData.ITEM_SUFFIX_BOOST[
          parseInt(
            getKeyFromValue(
              gameData.ITEM_SUFFIXES,
              items.find((item) => item.item === adventurer.ring)?.special1 ??
                ""
            ) ?? "0"
          )
        ]
      );
    }
  }
  const filteredSuffixBoosts = unequippedSuffixBoosts.filter(
    (suffix) => suffix !== undefined
  );
  const vitTotal = findAndSumVitValues(filteredSuffixBoosts);
  return vitTotal;
};

function findAndSumVitValues(arr: string[]): number {
  let total = 0;

  arr.forEach((str) => {
    const matches = str.match(/VIT \+\d+/g);

    if (matches) {
      matches.forEach((match) => {
        const value = parseInt(match.split("+")[1]);
        total += value;
      });
    }
  });

  return total;
}
