import { Item } from "../types";
import LootIcon from "./LootIcon";
import Efficacyicon from "./EfficacyIcon";

interface ItemDisplayProps {
  item: Item;
  type?: string;
}

export const ItemDisplay = (item: ItemDisplayProps) => {
  const Item = item?.item;

  const processName = (item: Item) => {
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
  };

  const itemName = processName(Item);
  const slot = Item ? Item.slot : "";

  return (
    <div
      className={`flex-shrink flex gap-2 p-2 mb-1  ${
        Item ? "bg-terminal-green text-terminal-black" : ""
      }`}
    >
      <LootIcon
        type={
          item.type == "feet"
            ? "foot"
            : item.type == "hands"
            ? "hand"
            : item.type
        }
      />
      {Item ? (
        <span className="flex flex-row justify-between w-full">
          <div>
            <span className="flex font-semibold whitespace-nowrap">
              {itemName} {Item?.level} {Item?.xp} XP
              {slot == "Neck" || slot == "Ring" ? " [+1 Luck]" : ""}
            </span>
            <span className="whitespace-nowrap">
              {Item &&
                `Tier ${Item?.rank}, Greatness ${Item?.greatness}, ${
                  Item?.material || "Generic"
                }`}
            </span>
          </div>
          <Efficacyicon type={item.item?.type} />
        </span>
      ) : (
        "Nothing Equipped"
      )}
    </div>
  );
};
