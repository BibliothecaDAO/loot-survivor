import { Item } from "../../types";
import LootIcon from "../icons/LootIcon";
import Efficacyicon from "../icons/EfficacyIcon";
import { processItemName, calculateLevel, getItemData } from "../../lib/utils";

interface ItemDisplayProps {
  item: Item;
}

export const ItemDisplay = ({ item }: ItemDisplayProps) => {
  const itemType = item?.item;

  const itemName = processItemName(item);
  const { tier, type, slot } = getItemData(itemType ?? "");

  return (
    <div
      className={`flex-shrink flex gap-2 p-1 sm:p-2 mb-1 text-sm sm:text-base ${
        item.item ? "bg-terminal-green text-terminal-black" : ""
      }`}
    >
      <LootIcon type={slot} />
      {item.item ? (
        <span className="flex flex-row justify-between w-full">
          <div className="w-full overflow-auto whitespace-normal">
            {" "}
            {/* Added the CSS classes here */}
            <span className="flex font-semibold whitespace-nowrap">
              {itemName} {item?.xp} XP
              {slot == "Neck" || slot == "Ring"
                ? ` [+${calculateLevel(item?.xp ?? 0)} Luck]`
                : ""}
            </span>
            <span className="whitespace-nowrap">
              {item &&
                `Tier ${tier ?? 0}, Greatness ${
                  calculateLevel(item?.xp ?? 0) ?? 0
                }
                `}
            </span>
          </div>
          <Efficacyicon type={type} />
        </span>
      ) : (
        "Nothing Equipped"
      )}
    </div>
  );
};
