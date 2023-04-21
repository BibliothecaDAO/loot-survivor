import { useState, useEffect } from "react";
import { Button } from "./Button";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurer } from "../types";
import { useQuery } from "@apollo/client";
import {
  getBeastById,
  getLatestBattlesByAdventurer,
} from "../hooks/graphql/queries";
import {
  useTransaction,
  useTransactions,
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import Image from "next/image";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import HealthSlider from "./HealthSlider";
import Info from "./Info";

export default function Beast() {
  const [loading, setLoading] = useState(false);

  const { handleSubmitCalls, addToCalls, calls } = useTransactionCart();
  const { beastContract } = useContracts();
  const { hashes, addTransaction, transactions } = useTransactionManager();
  const { adventurer, handleUpdateAdventurer } = useAdventurer();
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

  const formatAdventurer = adventurer ? adventurer.adventurer : NullAdventurer;

  const {
    loading: beastByTokenIdLoading,
    error: beastByTokenIdError,
    data: beastByTokenIdData,
    refetch: beastByTokenIdRefetch,
  } = useQuery(getBeastById, {
    variables: {
      id: formatAdventurer?.beastId,
    },
    pollInterval: 5000,
  });

  console.log(beastByTokenIdData, beastByTokenIdError);

  const {
    loading: battlesByAdventurerLoading,
    error: battlesByAdventurerError,
    data: battlesByAdventurerData,
    refetch: battlesByAdventurerRefetch,
  } = useQuery(getLatestBattlesByAdventurer, {
    variables: {
      adventurerId: formatAdventurer?.id,
    },
    pollInterval: 5000,
  });

  useEffect(() => {
    beastByTokenIdRefetch();
  }, [data?.status]);

  let beastData = beastByTokenIdData
    ? beastByTokenIdData.beasts[0]
    : {
        beast: "Pheonix",
        health: "100",
        rank: "1",
        xp: "0",
        attackType: "Blade",
        armorType: "Cloth",
      };

  // const [hash, setHash] = useState<string | undefined>(undefined);

  const attack = {
    contractAddress: beastContract?.address,
    selector: "attack",
    calldata: [formatAdventurer?.beastId, "0"],
  };

  const flee = {
    contractAddress: beastContract?.address,
    selector: "flee",
    calldata: [formatAdventurer?.beastId, "0"],
  };

  const buttonsData: ButtonData[] = [
    {
      id: 1,
      label: "ATTACK BEAST!",
      action: async () => {
        addToCalls(attack);
        await handleSubmitCalls().then((tx: any) => {
          setHash(tx.transaction_hash);
          addTransaction({
            hash: tx.transaction_hash,
            metadata: {
              method: "Attack Beast",
              description: `Attacking ${beastData.beast}`,
            },
          });
        });
      },
    },
    {
      id: 2,
      label: "FLEE BEAST",
      action: async () => {
        addToCalls(flee);
        await handleSubmitCalls().then((tx: any) => {
          setHash(tx.transaction_hash);
          addTransaction({
            hash: tx.transaction_hash,
            metadata: {
              method: "Flee Beast",
              description: `Fleeing from ${beastData.beast}`,
            },
          });
        });
      },
    },
  ];

  const txLoading = data?.status == "RECEIVED" || data?.status == "PENDING";

  return (
    <div className="flex flex-row mt-5">
      {!loading ? (
        <div className="w-1/3">
          <Info adventurer={adventurer?.adventurer} />
        </div>
      ) : null}
      <div className="flex flex-col w-1/3">
        <KeyboardControl buttonsData={buttonsData} />
        <>
          {txLoading && hashes && (
            <div className="loading-ellipsis">Loading</div>
          )}
          {hashes && <div className="flex flex-col">Hash: {hashes[-1]}</div>}
          {error && <div>Error: {JSON.stringify(error)}</div>}
          {data && <div>Status: {data.status}</div>}
        </>
      </div>

      <div className="flex flex-row w-1/3 bg-terminal-black">
        {formatAdventurer?.beastId ? (
          <div className="flex flex-col">
            <div className="w-[250px] h-[250px] relative ">
              <Image
                src="/pheonix.png"
                alt="beast-image"
                fill={true}
                style={{ objectFit: "contain" }}
              />
            </div>
            <div className="flex flex-col items-center mt-9">
              <div className="text-xl font-medium text-white">
                {beastData.beast}
              </div>
              <p className="text-lg text-terminal-green">
                HEALTH {beastData.health}
              </p>
              <p className="text-lg text-terminal-yellow">
                RANK {beastData.rank}
              </p>
              <p className="text-lg text-terminal-yellow">
                LEVEL {beastData.level}
              </p>
              <p className="text-lg text-terminal-yellow">XP {beastData.xp}</p>
              <p className="text-lg text-red-600">{beastData.attackType}</p>
              <p className="text-lg text-red-600">{beastData.armorType}</p>
            </div>
          </div>
        ) : (
          <p className="text-lg text-terminal-green m-auto">
            BEAST NOT YET DISCOVERED
          </p>
        )}
        <div className="flex flex-col gap-5 items-center">
          <p>Recent Encounters:</p>
          <div className="flex flex-col gap-2">
            <p>Attacked Pheonix for 7 damage</p>
            <p>Attacked by Pheonix taking 5 damage</p>
          </div>
        </div>
      </div>
    </div>
  );
}
