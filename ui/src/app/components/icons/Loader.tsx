import React, { useState, useEffect } from "react";
import ItemDisplay, { IconSize } from "@/app/components/icons/LootIcon";

interface Loader {
  size?: IconSize;
  className?: string;
}

const LootIconLoader = ({ size = "w-5", className }: Loader) => {
  const [currentType, setCurrentType] = useState("chest");
  const types = [
    "chest",
    "weapon",
    "head",
    "hand",
    "waist",
    "foot",
    "neck",
    "ring",
  ];

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentType((prevType) => {
        const currentIndex = types.findIndex((type) => type === prevType);
        return types[(currentIndex + 1) % types.length];
      });
    }, 100);
    return () => clearInterval(interval);
  }, []);

  return <ItemDisplay className={className} size={size} type={currentType} />;
};

export default LootIconLoader;
