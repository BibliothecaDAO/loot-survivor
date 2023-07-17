import { Item } from "../../types";
import LootIcon from "../icons/LootIcon";
import Efficacyicon from "../icons/EfficacyIcon";
import { processItemName, calculateLevel, getItemData } from "../../lib/utils";
import ItemBar from "./ItemBar";
import { GameData } from "../GameData";
import { getKeyFromValue, getValueFromKey } from "../../lib/utils";

interface ItemDisplayProps {
  item: Item;
}

export const ItemDisplay = ({ item }: ItemDisplayProps) => {
  const itemType = item?.item;

  const itemName = processItemName(item);
  const { tier, type, slot } = getItemData(itemType ?? "");
  const gameData = new GameData();

  const itemSuffix = parseInt(
    getKeyFromValue(gameData.ITEM_SUFFIXES, item.special1 ?? "") ?? ""
  );
  const boost = getValueFromKey(gameData.ITEM_SUFFIX_BOOST, itemSuffix ?? 0);

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
            <div className="flex flex-col">
              <span className="flex font-semibold whitespace-nowrap">
                {itemName}
                {slot == "Neck" || slot == "Ring"
                  ? ` [+${calculateLevel(item?.xp ?? 0)} Luck]`
                  : ""}
              </span>
              <div className="flex flex-row justify-between">
                <span className="text-xs sm:text-sm">
                  {item &&
                    `Tier ${tier ?? 0}
                `}
                </span>
                <span className="text-xs sm:text-sm">{boost}</span>
              </div>
            </div>
            <span className="whitespace-nowrap">
              <ItemBar xp={item.xp ?? 0} />
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
