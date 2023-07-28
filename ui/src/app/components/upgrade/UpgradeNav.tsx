import { useMediaQuery } from "react-responsive";
import { useState } from "react";

interface UpgradeNavProps {
  activeSection: number;
}

interface NavItem {
  label: string;
  section: number;
}

const mainUpgradeNav: NavItem[] = [
  { label: "Loot Fountain", section: 1 },
  { label: "Upgrade Stat", section: 2 },
];

const mobileUpgradeNav = [
  { label: "Potions", section: 1 },
  { label: "Loot Fountain", section: 2 },
  { label: "Upgrade Stat", section: 3 },
];

export const UpgradeNav = ({ activeSection }: UpgradeNavProps) => {
  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });
  const nav = isMobileDevice ? mobileUpgradeNav : mainUpgradeNav;
  return (
    <div className="flex flex-row justify-center items-center w-full text-shadow-none">
      {nav.map((item: NavItem, index: number) => (
        <span key={index} className="flex flex-row">
          <div
            className={`uppercase ${
              activeSection >= item.section
                ? "text-terminal-green"
                : "text-slate-600"
            }`}
          >
            {item.label}
          </div>
          {item.section !== nav.length && (
            <div
              className={
                activeSection > item.section
                  ? "text-terminal-green"
                  : "text-slate-600"
              }
            >
              ........
            </div>
          )}
        </span>
      ))}
    </div>
  );
};
