import { Contract } from "starknet";
import { MdClose } from "react-icons/md";
import LootIcon from "@/app/components/icons/LootIcon";
import Efficacyicon from "@/app/components/icons/EfficacyIcon";
import { Item } from "@/app/types";
import {
  getItemData,
  processItemName,
  calculateLevel,
  getKeyFromValue,
} from "@/app/lib/utils";
import useUIStore from "@/app/hooks/useUIStore";
import { GameData } from "@/app/lib/data/GameData";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";

interface InventoryDisplayProps {
  itemsOwnedInSlot: Item[];
  itemSlot: string;
  setShowInventoryItems: (showInventoryItems: boolean) => void;
  equipItems: string[];
  gameContract: Contract;
}

export const InventoryDisplay = ({
  itemsOwnedInSlot,
  itemSlot,
  setShowInventoryItems,
  equipItems,
  gameContract,
}: InventoryDisplayProps) => {
  return (
    <div className="flex flex-row items-center justify-between w-full h-full">
      {itemsOwnedInSlot.length > 0 ? (
        <div className="flex flex-row gap-1 overflow-x-auto item-scroll h-full">
          {itemsOwnedInSlot.map((item, index) => (
            <InventoryCard
              itemSlot={itemSlot}
              item={item}
              equipItems={equipItems}
              gameContract={gameContract}
              key={index}
            />
          ))}
        </div>
      ) : (
        <p>No items to equip.</p>
      )}
      <button onClick={() => setShowInventoryItems(false)}>
        <MdClose className="w-5 h-5" />
      </button>
    </div>
  );
};

interface InventoryCardProps {
  itemSlot: string;
  item: Item;
  equipItems: string[];
  gameContract: Contract;
}

export const InventoryCard = ({
  itemSlot,
  item,
  equipItems,
  gameContract,
}: InventoryCardProps) => {
  const { adventurer } = useAdventurerStore();
  const { tier, type, slot } = getItemData(item?.item ?? "");
  const itemName = processItemName(item);

  const setEquipItems = useUIStore((state) => state.setEquipItems);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );

  const gameData = new GameData();

  const handleEquipItems = (item: string) => {
    const formattedNewEquipItems = handleCheckSameSlot(slot, equipItems);
    const newEquipItems = [
      ...formattedNewEquipItems,
      getKeyFromValue(gameData.ITEMS, item) ?? "",
    ];
    setEquipItems(newEquipItems);
    if (gameContract) {
      const equipItemTx = {
        contractAddress: gameContract?.address,
        entrypoint: "equip",
        calldata: [
          adventurer?.id?.toString() ?? "",
          newEquipItems.length.toString(),
          ...newEquipItems,
        ],
        metadata: `Equipping ${item}!`,
      };
      removeEntrypointFromCalls(equipItemTx.entrypoint);
      addToCalls(equipItemTx);
    }
  };

  const itemId = getKeyFromValue(gameData.ITEMS, item?.item ?? "") ?? "";

  const handleCheckSameSlot = (itemSlot: string, equipItems: string[]) => {
    return equipItems.filter((item) => {
      const itemName = gameData.ITEMS[parseInt(item)];
      const { slot } = getItemData(itemName ?? "");
      return slot !== itemSlot;
    });
  };

  return (
    <div className="flex flex-row items-center justify-between border border-terminal-green p-1">
      <div className="flex flex-row items-center">
        <div className="sm:hidden flex flex-col items-center justify-center p-1 sm:p-2 gap-2">
          <LootIcon size={"w-3"} type={itemSlot ? itemSlot : slot} />
          <Efficacyicon size={"w-3"} type={type} />
        </div>
        <div className="hidden sm:flex flex-col justify-center p-1 sm:p-2 gap-2">
          <LootIcon size={"w-4"} type={itemSlot ? itemSlot : slot} />
          <Efficacyicon size={"w-4"} type={type} />
        </div>
        <span className="flex flex-col sm:gap-1 whitespace-nowrap text-sm sm:text-xxs md:text-lg">
          <div className="flex flex-row font-semibold items-center text-xs space-x-3">
            <span className="self-center">
              {item &&
                `Tier ${tier ?? 0}
                  `}
            </span>
            <span>Greatness {calculateLevel(item?.xp ?? 0)}</span>
            <button
              onClick={() => handleEquipItems(item?.item ?? "")}
              disabled={equipItems.includes(itemId)}
              className="bg-terminal-green text-terminal-black px-1 sm:p-1 uppercase disabled:bg-terminal-black disabled:text-terminal-green"
            >
              <p className="text-xxs sm:text-xs">Equip</p>
            </button>
          </div>
          <p className="text-text-ellipsis">{itemName}</p>
        </span>
      </div>
    </div>
  );
};
