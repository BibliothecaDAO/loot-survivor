import { useState, useEffect } from "react";
import { Button } from "./Button";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurer } from "../types";
import { useQuery, useLazyQuery } from "@apollo/client";
import {
  getBeastById,
  getLatestBattlesByAdventurer,
  getBattlesByBeast,
  getAdventurerById,
  getLastBattleByAdventurer,
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
import { BattleDisplay } from "./BattleDisplay";
import { BeastDisplay } from "./BeastDisplay";

export default function Beast() {
  const { handleSubmitCalls, addToCalls, calls } = useTransactionCart();
  const { beastContract } = useContracts();
  const { hashes, addTransaction, transactions } = useTransactionManager();
  const { adventurer, handleUpdateAdventurer, setAdventurer } = useAdventurer();
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

  const formatAdventurer = adventurer ? adventurer?.adventurer : NullAdventurer;

  const {
    loading: lastBattleLoading,
    error: lastBattleError,
    data: lastBattleData,
    refetch: lastBattleRefetch,
  } = useQuery(getLastBattleByAdventurer, {
    variables: {
      adventurerId: formatAdventurer?.id,
    },
    pollInterval: 5000,
  });

  const {
    loading: battlesByBeastLoading,
    error: battlesByBeastError,
    data: battlesByBeastData,
    refetch: battlesByBeastRefetch,
  } = useQuery(getBattlesByBeast, {
    variables: {
      adventurerId: formatAdventurer?.id,
      beastId: formatAdventurer?.beastId
        ? formatAdventurer?.beastId
        : lastBattleData?.battles[0]?.beastId,
    },
    pollInterval: 5000,
  });

  const formatBattles = battlesByBeastData ? battlesByBeastData.battles : [];

  const {
    loading: beastByTokenIdLoading,
    error: beastByTokenIdError,
    data: beastByTokenIdData,
    refetch: beastByTokenIdRefetch,
  } = useQuery(getBeastById, {
    variables: {
      id: formatAdventurer?.beastId
        ? formatAdventurer?.beastId
        : lastBattleData?.battles[0]?.beastId,
    },
    pollInterval: 5000,
  });

  // const { data: updatedAdventurerData, error: testError } = useQuery(
  //   getAdventurerById,
  //   {
  //     variables: {
  //       id: formatAdventurer?.id,
  //     },
  //     pollInterval: 5000,
  //   }
  // );

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
      <div className="w-1/3">
        <Info adventurer={adventurer?.adventurer} />
      </div>
      <div className="flex flex-col gap-10 w-1/3">
        <KeyboardControl
          buttonsData={buttonsData}
          disabled={formatAdventurer?.beastId == undefined}
        />
        <div className="flex flex-col p-4">
          {txLoading && hash && <div className="loading-ellipsis">Loading</div>}
          {hash && <div className="flex flex-col">Hash: {hash}</div>}
          {data && <div>Status: {data.status}</div>}
        </div>
      </div>

      <div className="flex flex-row w-1/3 bg-terminal-black">
        {formatAdventurer?.beastId || lastBattleData?.battles[0] ? (
          <>
            <BeastDisplay beastData={beastData} />
            <div className="flex flex-col gap-5 items-center">
              <p>Battle log:</p>
              <div className="flex flex-col gap-2">
                {formatBattles.map((battle: any, index: number) => (
                  <BattleDisplay
                    battleData={battle}
                    beastName={beastData.beast}
                  />
                ))}
              </div>
            </div>
          </>
        ) : (
          <p className="text-lg text-terminal-green m-auto">
            BEAST NOT YET DISCOVERED
          </p>
        )}
      </div>
    </div>
  );
}
