import { useState, useEffect, useRef } from "react";
import { useContracts } from "../hooks/useContracts";
import { useWriteContract } from "../hooks/useWriteContract";
import {
  useAccount,
  useWaitForTransaction,
  useTransactionManager,
  useTransactions,
} from "@starknet-react/core";
import { Button } from "./Button";
import { useQuery } from "@apollo/client";
import {
  getItemsByAdventurer,
  getItemsByOwner,
  getAdventurersByOwner,
} from "../hooks/graphql/queries";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import Image from "next/image";
import { padAddress } from "../lib/utils";
// import { GameData } from "./GameData";

const Inventory: React.FC = () => {
  const { account } = useAccount();
  const formatAddress = account ? account.address : "0x0";
  const { writeAsync, addToCalls, calls } = useWriteContract();
  const { adventurerContract } = useContracts();
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { hashes, addTransaction } = useTransactionManager();
  const { adventurer } = useAdventurer();
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const transactions = useTransactions({ hashes });

  // const gameData = new GameData();
  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

  const {
    loading: itemsByAdventurerLoading,
    error: itemsByAdventurerError,
    data: itemsByAdventurerData,
    refetch: itemsByAdventurerRefetch,
  } = useQuery(getItemsByAdventurer, {
    variables: {
      id: formatAdventurer.adventurer?.id,
    },
    pollInterval: 5000,
  });

  console.log(itemsByAdventurerData, itemsByAdventurerError);

  const handleAddEquipItem = (itemId: any) => {
    if (adventurerContract && formatAddress) {
      const equipItem = {
        contractAddress: adventurerContract?.address,
        selector: "equip_item",
        calldata: [formatAdventurer.adventurer?.id, itemId],
      };
      addToCalls(equipItem);
    }
  };

  const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
      case "ArrowUp":
        setSelectedIndex((prev) => Math.max(prev - 1, 0));
        break;
      case "ArrowDown":
        setSelectedIndex((prev) =>
          Math.min(prev + 1, itemsByAdventurerData?.items.length - 1)
        );
        break;
      case "Enter":
        handleAddEquipItem(itemsByAdventurerData?.items[selectedIndex].item.id);
        break;
    }
  };

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIndex]);

  useEffect(() => {}, [adventurerContract, formatAddress, addToCalls, calls]);

  return (
    <div className="flex flex-row bg-terminal-black border-2 border-terminal-green h-full p-20 gap-10">
      <div className="w-[160px] h-[160px] relative border-2 border-white my-auto">
        <Image
          src="/MIKE.png"
          alt="adventurer-image"
          fill={true}
          style={{ objectFit: "contain" }}
        />
      </div>
      <div className="flex flex-col gap-10">
        <div className="text-xl font-medium text-white">EQUIPPED</div>
        <p className="text-terminal-green">
          WEAPON - {formatAdventurer.adventurer?.weaponId}
        </p>
        <p className="text-terminal-green">
          HEAD - {formatAdventurer.adventurer?.headId}
        </p>
        <p className="text-terminal-green">
          CHEST - {formatAdventurer.adventurer?.chestId}
        </p>
        <p className="text-terminal-green">
          FOOT - {formatAdventurer.adventurer?.feetId}
        </p>
        <p className="text-terminal-green">
          HAND - {formatAdventurer.adventurer?.handsId}
        </p>
        <p className="text-terminal-green">
          WAIST - {formatAdventurer.adventurer?.waistId}
        </p>
      </div>
      <div className="flex flex-col gap-10">
        {itemsByAdventurerData?.items.map((item: any, index: number) => (
          <div key={index} className="flex flex-row gap-5">
            <p>{item.item}</p>
            <Button
              key={index}
              ref={(ref) => (buttonRefs.current[index] = ref)}
              className={selectedIndex === index ? "animate-pulse" : ""}
              variant={selectedIndex === index ? "default" : "outline"}
              onClick={() => {
                handleAddEquipItem(item.id);
              }}
            >
              Equip
            </Button>
          </div>
        ))}
      </div>
    </div>
    // <div className="flex flex-row items-center mx-2 text-lg">
    //   <div className="flex p-1 flex-col">
    //     <>
    //       {hash && <div className="flex flex-col">Hash: {hash}</div>}
    //       {isLoading && hash && (
    //         <div className="loading-ellipsis">Loading...</div>
    //       )}
    //       {error && <div>Error: {JSON.stringify(error)}</div>}
    //       {data && <div>Status: {data.status}</div>}
    //     </>
    //   </div>
    // </div>
  );
};

export default Inventory;
