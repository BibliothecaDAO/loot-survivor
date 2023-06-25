import { Item } from "../types";
import LootIcon from "./LootIcon";
import Efficacyicon from "./EfficacyIcon";
import { processItemName, calculateLevel, getItemData } from "../lib/utils";

interface ItemDisplayProps {
  item: Item;
  type?: string;
}

export const ItemDisplay = (item: ItemDisplayProps) => {
  const Item = item?.item;

  const itemName = processItemName(Item);
  const { tier, type, slot } = getItemData(item.item);

  return (
    <div
      className={`flex-shrink flex gap-2 p-1 sm:p-2 mb-1 text-sm sm:text-base ${
        Item ? "bg-terminal-green text-terminal-black" : ""
      }`}
    >
      <LootIcon type={slot} />
      {Item ? (
        <span className="flex flex-row justify-between w-full">
          <div className="w-full overflow-auto whitespace-normal">
            {" "}
            {/* Added the CSS classes here */}
            <span className="flex font-semibold whitespace-nowrap">
              {itemName} {calculateLevel(Item?.xp ?? 0)} {Item?.xp} XP
              {slot == "Neck" || slot == "Ring"
                ? ` [+${calculateLevel(Item?.xp ?? 0)} Luck]`
                : ""}
            </span>
            <span className="whitespace-nowrap">
              {Item &&
                `Tier ${tier}, Greatness ${calculateLevel(Item?.xp ?? 0)}
                }`}
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
