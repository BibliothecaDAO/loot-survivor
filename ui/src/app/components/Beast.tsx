import { useContracts } from "../hooks/useContracts";
import { NullBeast } from "../types";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import Info from "./Info";
import { BattleDisplay } from "./BattleDisplay";
import { BeastDisplay } from "./BeastDisplay";
import useLoadingStore from "../hooks/useLoadingStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { useQueriesStore } from "../hooks/useQueryStore";
import { useState } from "react";
import useUIStore from "../hooks/useUIStore";

export default function Beast() {
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const { beastContract } = useContracts();
  const { addTransaction } = useTransactionManager();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const { writeAsync } = useContractWrite({ calls });
  const loading = useLoadingStore((state) => state.loading);
  const startLoading = useLoadingStore((state) => state.startLoading);
  const onboarded = useUIStore((state) => state.onboarded);

  const { data } = useQueriesStore();

  const formatBattles = data.battlesByBeastQuery
    ? data.battlesByBeastQuery.battles
    : [];

  let beastData = data.beastByIdQuery
    ? data.beastByIdQuery.beasts[0]
    : NullBeast;

  const attack = {
    contractAddress: beastContract?.address ?? "",
    entrypoint: "attack",
    calldata: [adventurer?.beastId ?? "", "0"],
  };

  const flee = {
    contractAddress: beastContract?.address ?? "",
    entrypoint: "flee",
    calldata: [adventurer?.beastId ?? "", "0"],
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
        addToCalls(attack);
        await handleSubmitCalls(writeAsync).then((tx: any) => {
          if (tx) {
            startLoading(
              "Attack",
              tx.transaction_hash,
              "Attacking",
              "battlesByTxHashQuery",
              adventurer?.id,
              { beast: beastData }
            );
            addTransaction({
              hash: tx.transaction_hash,
              metadata: {
                method: "Attack Beast",
                description: `Attacking ${beastData.beast}`,
              },
            });
          }
        });
      },
      disabled: adventurer?.beastId == undefined || loading,
    },
    {
      id: 2,
      label: buttonText,
      mouseEnter: handleMouseEnter,
      mouseLeave: handleMouseLeave,
      action: async () => {
        addToCalls(flee);
        await handleSubmitCalls(writeAsync).then((tx: any) => {
          if (tx) {
            startLoading(
              "Flee",
              tx.transaction_hash,
              "Fleeing",
              "battlesByTxHashQuery",
              adventurer?.id,
              { beast: beastData }
            );
            addTransaction({
              hash: tx.transaction_hash,
              metadata: {
                method: "Flee Beast",
                description: `Fleeing from ${beastData.beast}`,
              },
            });
          }
        });
      },
      disabled: adventurer?.beastId == undefined || loading || !onboarded,
    },
  ];

  const isBeastDead = beastData?.health == "0";

  return (
    <div className="flex flex-row overflow-hidden">
      <div className="w-1/3">
        <Info adventurer={adventurer} />
      </div>
      <div className="flex flex-col w-1/3 gap-10 p-4">
        {!isBeastDead && <KeyboardControl buttonsData={buttonsData} />}

        {(adventurer?.beastId || formatBattles.length > 0) && (
          <>
            <div className="flex flex-col items-center gap-5 p-2">
              <div className="text-xl uppercase">
                Battle log with {beastData.beast}
              </div>
              <div className="flex flex-col gap-2">
                {formatBattles.map((battle: any, index: number) => (
                  <BattleDisplay
                    key={index}
                    battleData={battle}
                    beastName={beastData.beast}
                  />
                ))}
              </div>
            </div>
          </>
        )}
      </div>

      <div className="w-1/3">
        {adventurer?.beastId || data.lastBattleQuery?.battles[0] ? (
          <>
            <BeastDisplay beastData={beastData} />
          </>
        ) : (
          <div className="flex flex-col items-center h-full overflow-hidden border-2 border-terminal-green">
            <p className="m-auto text-lg uppercase text-terminal-green">
              Beast not yet discovered.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
