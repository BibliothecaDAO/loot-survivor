import { Adventurer, NullAdventurer, NullItem } from "@/app/types";
import { HeartIcon, CoinIcon, QuestionMarkIcon } from "../icons/Icons";
import { ItemDisplay } from "./ItemDisplay";
import LevelBar from "./LevelBar";
import { getKeyFromValue } from "../../lib/utils";
import { useQueriesStore } from "../../hooks/useQueryStore";
import useUIStore from "../../hooks/useUIStore";
import { Item } from "../../types";
import { HealthCountDown } from "../CountDown";
import { GameData } from "../GameData";
import { useContracts } from "../../hooks/useContracts";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";

interface InfoProps {
  adventurer: Adventurer | undefined;
  profileExists?: boolean;
  upgradeCost?: number;
}

export default function Info({
  adventurer,
  profileExists,
  upgradeCost,
}: InfoProps) {
  const formatAdventurer = adventurer ? adventurer : NullAdventurer;
  const { data } = useQueriesStore();
  const dropItems = useUIStore((state) => state.dropItems);
  const setDropItems = useUIStore((state) => state.setDropItems);
  const potionAmount = useUIStore((state) => state.potionAmount);
  const upgrades = useUIStore((state) => state.upgrades);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );
  const { gameContract } = useContracts();

  const gameData = new GameData();

  const items = profileExists
    ? data.itemsByProfileQuery
      ? data.itemsByProfileQuery.items
      : []
    : data.itemsByAdventurerQuery
    ? data.itemsByAdventurerQuery.items
    : [];

  const handleDropItems = (item: string) => {
    const newDropItems = [
      ...dropItems,
      getKeyFromValue(gameData.ITEMS, item) ?? "",
    ];
    setDropItems(newDropItems);
    if (gameContract) {
      const dropItemsTx = {
        contractAddress: gameContract?.address,
        entrypoint: "drop",
        calldata: [
          adventurer?.id?.toString() ?? "",
          newDropItems.length.toString(),
          ...newDropItems,
        ],
        metadata: `Dropping ${item}!`,
      };
      removeEntrypointFromCalls(dropItemsTx.entrypoint);
      addToCalls(dropItemsTx);
    }
  };

  const attributes = [
    { key: "STR", value: formatAdventurer.strength ?? 0 },
    { key: "DEX", value: formatAdventurer.dexterity },
    { key: "INT", value: formatAdventurer.intelligence ?? 0 },
    { key: "VIT", value: formatAdventurer.vitality ?? 0 },
    { key: "WIS", value: formatAdventurer.wisdom ?? 0 },
    { key: "CHA", value: formatAdventurer.charisma ?? 0 },
    { key: "LUCK", value: formatAdventurer.luck ?? 0 },
  ];

  const bodyParts = [
    "Weapon",
    "Chest",
    "Head",
    "Waist",
    "Foot",
    "Hand",
    "Neck",
    "Ring",
  ];

  const vitalitySelected = upgrades["Vitality"];

  const totalVitality = (formatAdventurer.vitality ?? 0) + vitalitySelected;

  const maxHealth = Math.min(100 + totalVitality * 10, 720);

  const healthPlus = Math.min(
    (vitalitySelected + potionAmount) * 10,
    maxHealth - (formatAdventurer.health ?? 0)
  );

  const maxHealthPlus = vitalitySelected * 10;

  const totalHealth = Math.min(
    (formatAdventurer.health ?? 0) + healthPlus,
    maxHealth
  );

  return (
    <>
      {adventurer?.id ? (
        <div className="border border-terminal-green h-full">
          <div className="flex flex-row flex-wrap gap-2 p-2 h-full">
            <div className="flex flex-col w-full uppercase h-full">
              <div className="relative flex justify-between w-full text-xl sm:text-2xl lg:text-3xl border-b border-terminal-green">
                {formatAdventurer.name}
                <span className="relative flex items-center text-terminal-yellow">
                  <CoinIcon className="self-center mt-1 w-5 h-5 fill-current" />{" "}
                  {formatAdventurer.gold
                    ? formatAdventurer.gold - (upgradeCost ?? 0)
                    : 0}
                  <span className="absolute top-0 right-[-20px] text-xs">
                    {formatAdventurer.gold === 511 ? "Full" : ""}
                  </span>
                </span>
                <span className="flex items-center ">
                  <HeartIcon className="self-center mt-1 w-5 h-5 fill-current" />{" "}
                  <HealthCountDown health={totalHealth || 0} />
                  {`/${maxHealth}`}
                </span>
                {(potionAmount > 0 || vitalitySelected > 0) && (
                  <p className="absolute top-[-5px] sm:top-[-10px] right-[30px] sm:right-[40px] text-xs sm:text-sm">
                    +{healthPlus}
                  </p>
                )}
                {vitalitySelected > 0 && (
                  <p className="absolute top-[-5px] sm:top-[-10px] right-0 text-xs sm:text-sm">
                    +{maxHealthPlus}
                  </p>
                )}
              </div>
              <hr className="border-terminal-green" />
              <div className="flex justify-between w-full sm:text-sm lg:text-xl pb-1">
                <LevelBar xp={formatAdventurer.xp ?? 0} />
              </div>

              <div className="flex flex-col w-full gap-1 overflow-hidden h-[450px] sm:h-full">
                <div className="flex flex-row w-full font-semibold text-xs sm:text-sm lg:text-base">
                  {attributes.map((attribute) => (
                    <div
                      key={attribute.key}
                      className="flex flex-wrap justify-between p-1 bg-terminal-green text-terminal-black w-full border border-terminal-black"
                    >
                      {attribute.key}
                      <span className="pl-1">{attribute.value}</span>
                    </div>
                  ))}
                </div>
                <div className="w-full flex flex-col sm:gap-1 2xl:gap-0 text-xs h-[400px] sm:h-[425px] overflow-y-auto 2xl:overflow-hidden">
                  {bodyParts.map((part) => (
                    <ItemDisplay
                      item={
                        items.find(
                          (item: Item) =>
                            item.item ===
                              formatAdventurer[part.toLowerCase()] &&
                            item.equipped
                        ) || NullItem
                      }
                      itemSlot={part}
                      handleDrop={handleDropItems}
                      key={part}
                    />
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className="flex items-center justify-center border border-terminal-green xl:h-[500px]">
          <QuestionMarkIcon className="w-1/2 h-1/2" />
        </div>
      )}
    </>
  );
}
