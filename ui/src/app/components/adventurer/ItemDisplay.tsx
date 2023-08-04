import { Item } from "../../types";
import LootIcon from "../icons/LootIcon";
import Efficacyicon from "../icons/EfficacyIcon";
import { processItemName, calculateLevel, getItemData } from "../../lib/utils";
import ItemBar from "./ItemBar";
import { GameData } from "../GameData";
import { getKeyFromValue, getValueFromKey } from "../../lib/utils";
import { useMediaQuery } from "react-responsive";
import { SwapIcon, DownArrowIcon } from "../icons/Icons";
import { Button } from "../buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";

interface ItemDisplayProps {
  item: Item;
  itemSlot?: string;
  inventory?: boolean;
  equip?: () => void;
  equipped?: boolean;
  disabled?: boolean;
  handleDrop: (value: string) => void;
}

export const ItemDisplay = ({
  item,
  itemSlot,
  inventory,
  equip,
  equipped,
  disabled,
  handleDrop,
}: ItemDisplayProps) => {
  const itemType = item?.item;

  const itemName = processItemName(item);
  const { tier, type, slot } = getItemData(itemType ?? "");
  const gameData = new GameData();

  const itemSuffix = parseInt(
    getKeyFromValue(gameData.ITEM_SUFFIXES, item.special1 ?? "") ?? ""
  );
  const boost = getValueFromKey(gameData.ITEM_SUFFIX_BOOST, itemSuffix ?? 0);

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });
  const screen = useUIStore((state) => state.screen);
  const setScreen = useUIStore((state) => state.setScreen);
  const setInventorySelected = useUIStore(
    (state) => state.setInventorySelected
  );
  const dropItems = useUIStore((state) => state.dropItems);

  const checkDropping = (item: string) => {
    return dropItems.includes(getKeyFromValue(gameData.ITEMS, item) ?? "");
  };

  return (
    <div
      className={`flex flex-row items-center mb-1 text-sm sm:text-base w-full h-10 sm:h-14 ${
        item.item ? "bg-terminal-green text-terminal-black" : ""
      }`}
    >
      <div className="flex flex-col justify-center border-r-2 border-terminal-black p-1 sm:p-2 gap-2">
        <LootIcon
          size={isMobileDevice ? "w-4" : "w-5"}
          type={itemSlot ? itemSlot : slot}
        />
        <Efficacyicon size={isMobileDevice ? "w-4" : "w-5"} type={type} />
      </div>

      {item.item ? (
        <div className="flex flex-row justify-between w-full px-2 self-center">
          <div className="w-full whitespace-normal">
            {" "}
            <div className="flex flex-col text-xs sm:text-sm space-between">
              <div className="flex flex-row font-semibold text-xs space-x-3">
                <span className=" self-center">
                  {item &&
                    `Tier ${tier ?? 0}
                `}
                </span>
                <span className="whitespace-nowrap w-1/2">
                  <ItemBar xp={item.xp ?? 0} />
                </span>
                <span className="text-xxs sm:text-sm">{boost}</span>
              </div>
              <span className="flex flex-row justify-between">
                <span className="flex font-semibold whitespace-nowrap text-[0.6rem] sm:text-lg">
                  <p>{itemName}</p>
                  <span className="text-xxs sm:text-sm">
                    {slot == "Neck" || slot == "Ring"
                      ? ` [+${calculateLevel(item?.xp ?? 0)} Luck]`
                      : ""}
                  </span>
                </span>
                <span className="flex flex-row items-center gap-1">
                  {(screen == "play" ||
                    screen == "upgrade" ||
                    screen == "player") && (
                    <Button
                      variant={"contrast"}
                      size={"xxs"}
                      className="p-1"
                      onClick={() => {
                        setScreen("inventory");
                        setInventorySelected(
                          parseInt(
                            getKeyFromValue(gameData.SLOTS, slot ?? "") ?? ""
                          ) ?? 0
                        );
                      }}
                    >
                      <SwapIcon className="w-4 h-4" />
                    </Button>
                  )}
                  {inventory && (
                    <Button
                      className="sm:h-6 sm:p-2"
                      variant={"contrast"}
                      size={isMobileDevice ? "xxs" : "sm"}
                      onClick={equip}
                      disabled={disabled}
                    >
                      <p className="text-xxs sm:text-sm">
                        {equipped ? "Equipped" : "Equip"}
                      </p>
                    </Button>
                  )}
                  {/* {(screen == "play" ||
                    screen == "upgrade" ||
                    screen == "player" ||
                    screen == "inventory") && (
                    <Button
                      variant={"contrast"}
                      size={"xxs"}
                      className="p-1"
                      onClick={() => handleDrop(item.item ?? "")}
                      disabled={checkDropping(item.item ?? "")}
                    >
                      <DownArrowIcon className="w-4 h-4" />
                    </Button>
                  )} */}
                </span>
              </span>
            </div>
          </div>
        </div>
      ) : (
        <div
          className={`flex-shrink flex gap-2 p-1 sm:p-2 mb-1 text-sm sm:text-base text-terminal-green"}`}
        >
          <p>None Equipped</p>
        </div>
      )}
    </div>
  );
};
