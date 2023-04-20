import { useState, useEffect } from "react";
import { Button } from "./Button";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import { useQuery } from "@apollo/client";
import { getBeastById } from "../hooks/graphql/queries";
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

  const { writeAsync, addToCalls, calls } = useTransactionCart();
  const { beastContract } = useContracts();
  const { hashes, addTransaction, transactions } = useTransactionManager();
  const { adventurer, handleUpdateAdventurer } = useAdventurer();
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

  const {
    loading: beastByTokenIdLoading,
    error: beastByTokenIdError,
    data: beastByTokenIdData,
    refetch: beastByTokenIdRefetch,
  } = useQuery(getBeastById, {
    variables: {
      id: formatAdventurer.adventurer?.beast,
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
    calldata: [formatAdventurer.adventurer?.id, "0"],
  };

  const flee = {
    contractAddress: beastContract?.address,
    selector: "flee",
    calldata: [formatAdventurer.adventurer?.id, "0"],
  };

  const buttonsData: ButtonData[] = [
    {
      id: 1,
      label: "ATTACK BEAST!",
      action: async () => {
        addToCalls(attack);
        await writeAsync().then((tx: any) => {
          setHash(tx.transaction_hash);
          addTransaction({
            hash: tx.transaction_hash,
            metadata: {
              method: "Attack Beast",
              desription: "Attacking Beast!",
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
        await writeAsync().then((tx: any) => {
          setHash(tx.transaction_hash);
          addTransaction({
            hash: tx.transaction_hash,
            metadata: {
              method: "Flee Beast",
              desription: "Flee from Beast!",
            },
          });
        });
      },
    },
  ];

  console.log(formatAdventurer.adventurer?.beast);

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
          {hashes && <div className="flex flex-col">Hash: {hashes[-1]}</div>}
          {isLoading && hashes && (
            <div className="loading-ellipsis">Loading</div>
          )}
          {error && <div>Error: {JSON.stringify(error)}</div>}
          {data && <div>Status: {data.status}</div>}
        </>
      </div>

      <div className="flex flex-col w-1/3 bg-terminal-black">
        {formatAdventurer.adventurer?.beast ? (
          <>
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
              <p className="text-lg text-terminal-yellow">XP {beastData.xp}</p>
              <p className="text-lg text-red-600">
                ATTACK TYPE {beastData.attackType}
              </p>
              <p className="text-lg text-red-600">
                ARMOR TYPE {beastData.armorType}
              </p>
            </div>
          </>
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
