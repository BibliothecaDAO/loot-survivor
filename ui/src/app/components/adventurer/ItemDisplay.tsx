import React, { useEffect, useState } from "react";
import { Item } from "../../types";
import LootIcon from "../icons/LootIcon";
import Efficacyicon from "../icons/EfficacyIcon";
import { processItemName, calculateLevel, getItemData } from "../../lib/utils";
import ItemBar from "./ItemBar";
import { GameData } from "../GameData";
import { getKeyFromValue, getValueFromKey } from "../../lib/utils";
import { SwapIcon, DownArrowIcon } from "../icons/Icons";
import { Button } from "../buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";
import { InventoryDisplay } from "./InventoryDisplay";
import { useQueriesStore } from "@/app/hooks/useQueryStore";

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
  const [showInventoryItems, setShowInventoryItems] = useState(false);
  const itemType = item?.item;

  const itemName = processItemName(item);
  const equipItems = useUIStore((state) => state.equipItems);
  const { tier, type, slot } = getItemData(itemType ?? "");
  const { data } = useQueriesStore();
  const gameData = new GameData();

  const itemSuffix = parseInt(
    getKeyFromValue(gameData.ITEM_SUFFIXES, item.special1 ?? "") ?? ""
  );
  const boost = getValueFromKey(gameData.ITEM_SUFFIX_BOOST, itemSuffix ?? 0);

  const screen = useUIStore((state) => state.screen);
  const dropItems = useUIStore((state) => state.dropItems);

  const scrollableRef = React.useRef<HTMLDivElement | null>(null);
  const animationFrameRef = React.useRef<number | null>(null);

  function handleMouseEnter() {
    const el = scrollableRef.current;
    if (!el) return; // Guard clause
    const endPos = el.scrollWidth - el.offsetWidth; // Calculate the width of the overflow

    // Use this to control the speed of the scroll
    const duration = 4000; // In milliseconds

    const start = performance.now();
    const initialScrollLeft = el.scrollLeft;

    requestAnimationFrame(function step(now) {
      const elapsed = now - start;
      let rawProgress = elapsed / duration;

      let progress;
      if (rawProgress <= 0.5) {
        // For the first half, we scale rawProgress from [0, 0.5] to [0, 1]
        progress = rawProgress * 2;
      } else {
        // For the second half, we scale rawProgress from [0.5, 1] to [1, 0]
        progress = 2 - rawProgress * 2;
      }

      el.scrollLeft = initialScrollLeft + progress * endPos;

      if (rawProgress < 1) {
        animationFrameRef.current = requestAnimationFrame(step);
      } else {
        // Restart the animation once it's done
        handleMouseEnter();
      }
    });
  }

  function handleMouseLeave() {
    const el = scrollableRef.current;
    if (!el) return; // Guard clause

    if (animationFrameRef.current !== null) {
      cancelAnimationFrame(animationFrameRef.current);
      animationFrameRef.current = null;
    }

    // When mouse leaves, smoothly scroll back to the start
    el.scrollLeft = 0;
  }

  useEffect(() => {
    const el = scrollableRef.current;

    if (!el) return; // If the element is not there, do nothing.

    // Attach event listeners
    el.addEventListener("mouseenter", handleMouseEnter);
    el.addEventListener("mouseleave", handleMouseLeave);

    // Cleanup event listeners on unmount
    return () => {
      el.removeEventListener("mouseenter", handleMouseEnter);
      el.removeEventListener("mouseleave", handleMouseLeave);
    };
  }, []); // Empty dependency array means this effect runs once when component mounts

  const checkDropping = (item: string) => {
    return dropItems.includes(getKeyFromValue(gameData.ITEMS, item) ?? "");
  };

  // Handle inventory display when user selects swap

  const items = data.itemsByAdventurerQuery
    ? data.itemsByAdventurerQuery.items
    : [];

  const itemsOwnedInSlot = items.filter((ownedItem) => {
    const { slot } = getItemData(ownedItem.item ?? "");
    return slot === itemSlot && item.item !== ownedItem.item;
  });

  const slotEquipped = itemsOwnedInSlot.some((item) =>
    equipItems.includes(getKeyFromValue(gameData.ITEMS, item.item ?? "") ?? "")
  );

  // Check if they have slected to equip a slot then close inventory items
  useEffect(() => {
    if (slotEquipped) {
      setShowInventoryItems(false);
    }
  }, [slotEquipped, equipItems]);

  return (
    <>
      {!showInventoryItems ? (
        <div
          className={`flex flex-row items-center mb-1 text-sm sm:text-base w-full h-[8rem] sm:h-10 md:h-full  ${
            item.item
              ? "bg-terminal-green text-terminal-black overflow-x-auto item-scroll overflow-y-hidden"
              : ""
          }`}
          ref={scrollableRef}
        >
          <div className="sm:hidden flex flex-col items-center justify-center border-r-2 border-terminal-black p-1 sm:p-2 gap-2">
            <LootIcon size={"w-5"} type={itemSlot ? itemSlot : slot} />
            <Efficacyicon size={"w-5"} type={type} />
          </div>
          <div className="hidden sm:flex flex-col justify-center border-r-2 border-terminal-black p-1 sm:p-2 gap-2">
            <LootIcon size={"w-5"} type={itemSlot ? itemSlot : slot} />
            <Efficacyicon size={"w-5"} type={type} />
          </div>

          {item.item ? (
            <div className="flex flex-row justify-between w-full px-1 self-center">
              <div className="w-full whitespace-normal">
                <div className="flex flex-col text-xs sm:text-sm space-between">
                  <div className="flex flex-row font-semibold text-xs space-x-3">
                    <span className="self-center">
                      {item &&
                        `Tier ${tier ?? 0}
                  `}
                    </span>
                    <span className="whitespace-nowrap w-1/2">
                      <ItemBar xp={item.xp ?? 0} />
                    </span>
                    <span className="text-xxs sm:text-sm">{boost}</span>
                  </div>
                  <span className="flex flex-row justify-between gap-5">
                    <span className="flex flex-row gap-1 whitespace-nowrap text-sm sm:text-xxs md:text-lg">
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
                          className="p-1 xl:p-0 sm:h-4 sm:w-8"
                          onClick={() => {
                            setShowInventoryItems(true);
                          }}
                        >
                          <SwapIcon className="w-4 h-4" />
                        </Button>
                      )}
                      {inventory && (
                        <>
                          <div className="sm:hidden">
                            <Button
                              className="sm:h-6 sm:p-2"
                              variant={"contrast"}
                              size={"xxs"}
                              onClick={equip}
                              disabled={disabled}
                            >
                              <p className="text-xxs sm:text-sm">
                                {equipped ? "Equipped" : "Equip"}
                              </p>
                            </Button>
                          </div>
                          <div className="hidden sm:block">
                            <Button
                              className="sm:h-6 sm:p-2"
                              variant={"contrast"}
                              size={"xxs"}
                              onClick={equip}
                              disabled={disabled}
                            >
                              <p className="text-xxs sm:text-sm">
                                {equipped ? "Equipped" : "Equip"}
                              </p>
                            </Button>
                          </div>
                        </>
                      )}
                      {(screen == "play" ||
                        screen == "upgrade" ||
                        screen == "player" ||
                        screen == "inventory") && (
                        <Button
                          variant={"contrast"}
                          size={"xxs"}
                          className="p-1 xl:p-0 sm:h-4 sm:w-8"
                          onClick={() => handleDrop(item.item ?? "")}
                          disabled={checkDropping(item.item ?? "")}
                        >
                          <DownArrowIcon className="w-4 h-4" />
                        </Button>
                      )}
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
      ) : (
        <div className="flex flex-row items-center mb-1 text-sm sm:text-base w-full h-10 sm:h-10 md:h-full">
          <InventoryDisplay
            itemsOwnedInSlot={itemsOwnedInSlot}
            itemSlot={slot}
            setShowInventoryItems={setShowInventoryItems}
            equipItems={equipItems}
          />
        </div>
      )}
    </>
  );
};
