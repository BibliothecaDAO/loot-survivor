import { useContracts } from "../hooks/useContracts";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import KeyboardControl, { ButtonData } from "../components/KeyboardControls";
import { BattleDisplay } from "../components/beast/BattleDisplay";
import { BeastDisplay } from "../components/beast/BeastDisplay";
import useLoadingStore from "../hooks/useLoadingStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { useQueriesStore } from "../hooks/useQueryStore";
import React, { useState } from "react";
import useUIStore from "../hooks/useUIStore";
import { processBeastName } from "../lib/utils";
import useCustomQuery from "../hooks/useCustomQuery";
import {
  getBattlesByBeast,
  getBeast,
  getLastBeastDiscovery,
  getLastBattleByAdventurer,
} from "../hooks/graphql/queries";
import { NullAdventurer, Battle, NullDiscovery, NullBeast } from "../types";
import { Button } from "../components/buttons/Button";
import { useMediaQuery } from "react-responsive";

/**
 * @container
 * @description Provides the beast screen for adventurer battles.
 */
export default function BeastScreen() {
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const { gameContract } = useContracts();
  const { addTransaction } = useTransactionManager();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const { writeAsync } = useContractWrite({ calls });
  const loading = useLoadingStore((state) => state.loading);
  const startLoading = useLoadingStore((state) => state.startLoading);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const hash = useLoadingStore((state) => state.hash);
  const [showBattleLog, setShowBattleLog] = useState(false);

  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const isAlive = useAdventurerStore((state) => state.computed.isAlive);

  const { data } = useQueriesStore();

  useCustomQuery(
    "lastBeastQuery",
    getLastBeastDiscovery,
    {
      adventurerId: adventurer?.id ?? 0,
    },
    txAccepted
  );

  useCustomQuery(
    "lastBattleQuery",
    getLastBattleByAdventurer,
    {
      adventurerId: adventurer?.id ?? 0,
    },
    txAccepted
  );

  let lastBeast = data.lastBeastQuery
    ? data.lastBeastQuery.discoveries[0]
    : NullDiscovery;

  useCustomQuery(
    "beastQuery",
    getBeast,
    {
      adventurerId: adventurer?.id ?? 0,
      beast: lastBeast?.entity,
      seed: lastBeast?.seed,
    },
    txAccepted
  );

  useCustomQuery(
    "battlesByBeastQuery",
    getBattlesByBeast,
    {
      adventurerId: adventurer?.id ?? 0,
      beast: lastBeast?.entity,
      seed: lastBeast?.seed,
    },
    txAccepted
  );

  let beastData = data.beastQuery ? data.beastQuery.beasts[0] : NullBeast;

  const formatBattles = data.battlesByBeastQuery
    ? data.battlesByBeastQuery.battles
    : [];

  const lastBattle = data.lastBattleQuery?.battles[0];

  const attackTx = {
    contractAddress: gameContract?.address ?? "",
    entrypoint: "attack",
    calldata: [adventurer?.id?.toString() ?? "", "0"],
  };

  const fleeTx = {
    contractAddress: gameContract?.address ?? "",
    entrypoint: "flee",
    calldata: [adventurer?.id?.toString() ?? "", "0"],
  };

  const [buttonText, setButtonText] = useState("Flee!");

  const handleMouseEnter = () => {
    setButtonText("you coward!");
  };

  const handleMouseLeave = () => {
    setButtonText("Flee!");
  };

  const buttonsData: ButtonData[] = [
    {
      id: 1,
      label: "ATTACK BEAST!",
      action: async () => {
        addToCalls(attackTx);
        startLoading(
          "Attack",
          "Attacking",
          "battlesByTxHashQuery",
          adventurer?.id,
          { beast: beastData }
        );
        await handleSubmitCalls(writeAsync).then((tx: any) => {
          if (tx) {
            setTxHash(tx.transaction_hash);
            addTransaction({
              hash: tx.transaction_hash,
              metadata: {
                method: `Attack ${beastData.beast}`,
              },
            });
          }
        });
      },
      disabled:
        adventurer?.beastHealth == undefined ||
        adventurer?.beastHealth == 0 ||
        loading,
      loading: loading,
    },
    {
      id: 2,
      label: buttonText,
      mouseEnter: handleMouseEnter,
      mouseLeave: handleMouseLeave,
      action: async () => {
        addToCalls(fleeTx);
        startLoading(
          "Flee",
          "Fleeing",
          "battlesByTxHashQuery",
          adventurer?.id,
          { beast: beastData }
        );
        await handleSubmitCalls(writeAsync).then((tx: any) => {
          if (tx) {
            setTxHash(tx.transaction_hash);
            addTransaction({
              hash: tx.transaction_hash,
              metadata: {
                method: `Flee ${beastData.beast}`,
              },
            });
          }
        });
      },
      disabled:
        adventurer?.beastHealth == undefined ||
        adventurer?.beastHealth == 0 ||
        loading ||
        beastData?.seed == 0,
      loading: loading,
    },
  ];

  const beastName = processBeastName(
    beastData?.beast ?? "",
    beastData?.special2 ?? "",
    beastData?.special3 ?? ""
  );

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  const BattleLog: React.FC = () => (
    <div className="flex flex-col p-2 items-center">
      <Button
        className="w-1/2 sm:hidden"
        onClick={() => setShowBattleLog(false)}
      >
        Back
      </Button>
      <div className="flex flex-col items-center gap-5 p-2">
        <div className="text-xl uppercase">
          Battle log with {beastData?.beast}
        </div>
        <div className="flex flex-col gap-2 ext-sm overflow-y-auto h-96 text-center">
          {formatBattles.map((battle: Battle, index: number) => (
            <div className="border p-2 border-terminal-green" key={index}>
              <BattleDisplay battleData={battle} beastName={beastName} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  if (isMobileDevice && showBattleLog) {
    return <BattleLog />;
  }

  return (
    <div className="sm:w-2/3 flex flex-col sm:flex-row gap-2 sm:gap-0">
      <div className="sm:w-1/2 order-1 sm:order-2">
        {hasBeast || lastBattle ? (
          <>
            <BeastDisplay beastData={beastData} lastBattle={formatBattles[0]} />
          </>
        ) : (
          <div className="flex flex-col items-center h-full  border-2 border-terminal-green">
            <p className="m-auto text-lg uppercase text-terminal-green">
              Beast not yet discovered.
            </p>
          </div>
        )}
      </div>

      <div className="flex flex-col sm:w-1/2 sm:gap-5 sm:p-4 order-1 text-lg">
        {isAlive && (
          <KeyboardControl
            buttonsData={buttonsData}
            size={isMobileDevice ? "sm" : "lg"}
          />
        )}

        <div className="hidden sm:block">
          {(hasBeast || formatBattles.length > 0) && <BattleLog />}
        </div>

        <Button
          className="sm:hidden uppercase"
          onClick={() => setShowBattleLog(true)}
        >
          Battle log with {beastData?.beast}
        </Button>
      </div>
    </div>
  );
}
