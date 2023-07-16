import { ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import BN from "bn.js";

import Realms from "./realms.json";
import { Item } from "../types";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function indexAddress(address: string) {
  const newHex =
    address.substring(0, 2) + address.substring(3).replace(/^0+/, "");
  return newHex;
}

export function padAddress(address: string) {
  if (address !== "") {
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

export function displayAddress(string: string) {
  if (string === undefined) return "unknown";
  return string.substring(0, 6) + "..." + string.substring(string.length - 4);
}

const P = new BN(
  "800000000000011000000000000000000000000000000000000000000000001",
  16
);

export function feltToString(felt: BN) {
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

export function groupBySlot(items: any[]) {
  const groups: any = {};

  items.forEach((item) => {
    if (!groups[item.slot]) {
      groups[item.slot] = [];
    }

    groups[item.slot].push(item);
  });

  return groups;
}

type Dictionary = { [key: string]: any };

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

export function shortenHex(hexString: string, numDigits = 6) {
  if (hexString.length <= numDigits) {
    return hexString;
  }

  const halfDigits = Math.floor(numDigits / 2);
  const firstHalf = hexString.slice(0, halfDigits);
  const secondHalf = hexString.slice(-halfDigits);
  return `${firstHalf}...${secondHalf}`;
}

export function convertTime(time: string) {
  const dateTime = new Date(time);

  // Convert the offset to milliseconds
  const currentTimezoneOffsetMinutes = new Date().getTimezoneOffset() * -1;
  const timezoneOffsetMilliseconds = currentTimezoneOffsetMinutes * 60 * 1000;

  const TimeUTC = dateTime.getTime() + timezoneOffsetMilliseconds;
  return TimeUTC;
}

export function getRealmNameById(id: number) {
  return Realms.features.find((realm) => realm.id === id);
}

export function getRankFromList(id: number, data: any[]) {
  return data.findIndex((data) => data.id === id);
}

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

export function processItemName(item: Item) {
  if (item) {
    if (item.prefix1 && item.suffix && item.greatness >= 20) {
      return `${item.prefix1} ${item.prefix2} ${item.item} ${item.suffix} +1`;
    } else if (item.prefix1 && item.suffix) {
      return `${item.prefix1} ${item.prefix2} ${item.item} ${item.suffix}`;
    } else if (item.suffix) {
      return `${item.item} ${item.suffix}`;
    } else {
      return `${item.item}`;
    }
  }
}

export function processBeastName(beastData: any) {
  if (beastData?.prefix1 && beastData?.prefix2) {
    return `"${beastData?.prefix1} ${beastData?.prefix2}" ${beastData?.beast}`;
  } else {
    return `${beastData?.beast}`;
  }
}

export function getRandomElement(arr: string[]): string {
  if (arr.length === 0) {
    throw new Error("Array must not be empty.");
  }
  const randomIndex = Math.floor(Math.random() * arr.length);
  return arr[randomIndex];
}

type MyDict = { [key: string]: any }; // Or replace 'any' with the actual type if you know it

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
