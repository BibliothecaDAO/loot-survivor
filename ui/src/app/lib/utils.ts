import { ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import BN from "bn.js";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function indexAddress(address: string) {
  const newHex =
    address.substring(0, 2) + address.substring(3).replace(/^0+/, "");
  return newHex;
}

export function padAddress(address: string) {
  const length = address.length;
  const neededLength = 66 - length;
  let zeros = "";
  for (var i = 0; i < neededLength; i++) {
    zeros += "0";
  }
  const newHex = address.substring(0, 2) + zeros + address.substring(2);
  return newHex;
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
  ); // Extract the time portion (hh:mm:ss) from the ISO string
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