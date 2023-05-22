import { Item } from "../types";
import LootIcon from "./LootIcon";
import Efficacyicon from "./EfficacyIcon";
import { processItemName } from "../lib/utils";

interface ItemDisplayProps {
  item: Item;
  type?: string;
}

export const ItemDisplay = (item: ItemDisplayProps) => {
  const Item = item?.item;

  const itemName = processItemName(Item);
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
              {slot == "Neck" || slot == "Ring"
                ? ` [+${Item?.greatness} Luck]`
                : ""}
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
