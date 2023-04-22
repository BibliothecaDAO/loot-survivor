import { useState, useEffect } from "react";
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

export const ANSIArt = ({ imageUrl, newWidth = 60 }: any) => {
  const [ansiArt, setAnsiArt] = useState("");

  useEffect(() => {
    const getColorCode = (pixel: any) => {
      const [r, g, b] = pixel;
      return `rgba(${r}, ${g}, ${b}, 255)`;
    };

    const loadAndRenderImage = async () => {
      const img = new Image();
      img.src = imageUrl;

      await new Promise((resolve) => {
        img.onload = resolve;
      });

      const canvas = document.createElement("canvas");
      const ctx = canvas.getContext("2d") as CanvasRenderingContext2D;
      const aspectRatio = img.height / img.width;
      const height = Math.floor(aspectRatio * newWidth);

      canvas.width = newWidth;
      canvas.height = height;

      ctx.drawImage(img, 0, 0, newWidth, height);

      const imageData = ctx.getImageData(0, 0, newWidth, height).data;
      const blockSize = 1;
      let ansiArtHtml = "";

      for (let y = 0; y < height; y += blockSize) {
        for (let x = 0; x < newWidth; x += blockSize) {
          const i = (y * newWidth + x) * 4;
          const pixel = [imageData[i], imageData[i + 1], imageData[i + 2]];
          const colorCode = getColorCode(pixel);
          const block = "\u2588";

          ansiArtHtml += `<span style="color: ${colorCode};">${block}</span>`;
        }
        ansiArtHtml += "<br>";
      }

      setAnsiArt(ansiArtHtml);
    };

    loadAndRenderImage();
  }, [imageUrl, newWidth]);

  return ansiArt;
};
