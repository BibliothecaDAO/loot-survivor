import { useState, useEffect } from "react";
import { useSpring, animated, config } from "react-spring";
import { useContracts } from "../hooks/useContracts";
import { NullAdventurer, NullBeast } from "../types";
import { useQuery } from "@apollo/client";
import {
  getBeastById,
  getBattlesByBeast,
  getLastBattleByAdventurer,
} from "../hooks/graphql/queries";
import {
  useTransactionManager,
  useWaitForTransaction,
  useContractWrite,
} from "@starknet-react/core";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import BattleInfo from "./Info";
import { BattleDisplay } from "./BattleDisplay";
import { BeastDisplay } from "./BeastDisplay";
import Battle from "../../../public/battle.png";
import { Button } from "./Button";
import { shortenHex } from "../lib/utils";
import { TxActivity } from "./TxActivity";
import useLoadingStore from "../hooks/useLoadingStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import useAdventurerStore from "../hooks/useAdventurerStore";

export default function BattleScene() {
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
  const type = useLoadingStore((state) => state.type);
  const updateData = useLoadingStore((state) => state.updateData);

  const [finished, setFinished] = useState(false);

  const showBattleScene = true;

  const entryAnimation = useSpring({
    from: { opacity: 0, transform: "translateY(100%)" },
    to: { opacity: 1, transform: "translateY(0%)" },
    config: { tension: 20, friction: 5, mass: 1 },
    onRest: () => setFinished(true),
  });

  const shakeAnimation = useSpring({
    from: { transform: "translateX(0px)" },
    to: async (next: any) => {
      let loopCount = 0;
      while (loopCount < 10) {
        await next({ transform: "translateX(10px)" });
        await next({ transform: "translateX(-10px)" });
        loopCount++;
      }
      await next({ transform: "translateX(0px)" });
    },
    config: { duration: 100 },
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

  let beastData = beastByTokenIdData ? beastByTokenIdData.beasts[0] : NullBeast;

  const attack = {
    contractAddress: beastContract?.address ?? "",
    entrypoint: "attack",
    calldata: [formatAdventurer?.beastId ?? "", "0"],
  };

  const flee = {
    contractAddress: beastContract?.address ?? "",
    entrypoint: "flee",
    calldata: [formatAdventurer?.beastId ?? "", "0"],
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
              formatBattles
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
    },
    {
      id: 2,
      label: "FLEE BEAST",
      action: async () => {
        addToCalls(flee);
        await handleSubmitCalls(writeAsync).then((tx: any) => {
          if (tx) {
            startLoading("Flee", tx.transaction_hash, "Fleeing", formatBattles);
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
    },
  ];

  const isBeastDead = beastData?.health == "0";

  useEffect(() => {
    if (loading && (type == "Attack" || type == "Flee")) {
      updateData(formatBattles);
    }
  }, [formatBattles]);

  return (
    <div
      className="flex flex-col items-center justify-center h-screen bg-cover bg-no-repeat bg-center border border-terminal-green"
      style={{
        backgroundImage: `linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url(./battle.png)`,
      }}
    >
      <div className="flex flex-row space-x-8 w-full">
        <animated.div
          className="flex flex-row w-1/3 bg-black"
          style={entryAnimation}
        >
          <animated.div style={finished ? shakeAnimation : {}}>
            <BattleInfo adventurer={adventurer?.adventurer} />
          </animated.div>
        </animated.div>
        <div className="flex flex-col w-1/3 gap-10">
          {(formatAdventurer?.beastId || lastBattleData?.battles[0]) && (
            <>
              <div className="flex flex-col items-center gap-5 p-2">
                <div className="text-xl uppercase">
                  Battle log with {beastData?.beast}
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
                {!isBeastDead && (
                  <KeyboardControl
                    buttonsData={buttonsData}
                    disabled={formatAdventurer?.beastId == undefined || loading}
                  />
                )}
              </div>
            </>
          )}
        </div>

        <animated.div
          className="flex flex-row w-1/3 bg-black"
          style={entryAnimation}
        >
          {formatAdventurer?.beastId || lastBattleData?.battles[0] ? (
            <>
              <animated.div style={finished ? shakeAnimation : {}}>
                <BeastDisplay beastData={beastData} />
              </animated.div>
            </>
          ) : (
            <p className="text-5xl text-white text-center w-1/2 m-auto">
              You are not in a battle
            </p>
          )}
        </animated.div>
      </div>
    </div>
  );
}
