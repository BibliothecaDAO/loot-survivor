import { useContracts } from "../hooks/useContracts";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import KeyboardControl, { ButtonData } from "../components/KeyboardControls";
import Info from "../components/adventurer/Info";
import { BattleDisplay } from "../components/beast/BattleDisplay";
import { BeastDisplay } from "../components/beast/BeastDisplay";
import useLoadingStore from "../hooks/useLoadingStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { useQueriesStore } from "../hooks/useQueryStore";
import { useState } from "react";
import useUIStore from "../hooks/useUIStore";
import { processBeastName } from "../lib/utils";
import useCustomQuery from "../hooks/useCustomQuery";
import {
  getBattlesByBeast,
  getBeastById,
  getLastBeastDiscovery,
  getLastBattleByAdventurer,
} from "../hooks/graphql/queries";
import { useMediaQuery } from "react-responsive";
import { NullBattle } from "../types";
import { DiscoveryTemplate, BattleTemplate } from "../types/templates";

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
  const onboarded = useUIStore((state) => state.onboarded);

  const { data } = useQueriesStore();

  useCustomQuery(
    "lastBeastQuery",
    getLastBeastDiscovery,
    {
      adventurerId: adventurer?.id,
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

  console.log(
    data.battlesByBeastQuery,
    data.lastBattleQuery,
    data.lastBeastQuery
  );

  // let beastData = data.lastBeastQuery
  //   ? data.lastBeastQuery.beasts[0]
  //   : NullBattle;

  let beastData = DiscoveryTemplate;

  useCustomQuery(
    "battlesByBeastQuery",
    getBattlesByBeast,
    {
      adventurerId: adventurer?.id ?? 0,
      beast: beastData?.entity,
      discoveryTime: beastData?.discoveryTime?.toISOString(),
    },
    txAccepted
  );

  // const formatBattles = data.battlesByBeastQuery
  //   ? data.battlesByBeastQuery.battles
  //   : [];

  const formatBattles = [BattleTemplate];

  // const lastBattle = data.lastBattleQuery?.battles[0];

  const lastBattle = BattleTemplate;

  const attack = {
    contractAddress: gameContract?.address ?? "",
    entrypoint: "attack",
    calldata: [adventurer?.id ?? ""],
  };

  const flee = {
    contractAddress: gameContract?.address ?? "",
    entrypoint: "flee",
    calldata: [adventurer?.id ?? ""],
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
                method: `Attack ${beastData.entity}`,
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
        addToCalls(flee);
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
                method: `Flee ${beastData.entity}`,
              },
            });
          }
        });
      },
      disabled:
        adventurer?.beastHealth == undefined ||
        adventurer?.beastHealth == 0 ||
        loading ||
        !onboarded,
      loading: loading,
    },
  ];

  const isBeastDead = adventurer?.health == 0;

  const beastName = processBeastName(
    beastData?.entity,
    beastData?.entityNamePrefix,
    beastData?.entityNameSuffix
  );

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  return (
    <div className="flex flex-col sm:flex-row overflow-hidden flex-wrap">
      <div className="hidden sm:block sm:w-1/3">
        <Info adventurer={adventurer} />
      </div>
      {isMobileDevice ? (
        <>
          <div className="sm:w-1/3">
            {(adventurer?.beastHealth ?? 0 > 0) || lastBattle ? (
              <>
                <BeastDisplay
                  beastData={beastData}
                  lastBattle={formatBattles[0]}
                />
              </>
            ) : (
              <div className="flex flex-col items-center h-full overflow-hidden border-2 border-terminal-green">
                <p className="m-auto text-lg uppercase text-terminal-green">
                  Beast not yet discovered.
                </p>
              </div>
            )}
          </div>

          <div className="flex flex-col sm:w-1/3 gap-5 p-4">
            {!isBeastDead && <KeyboardControl buttonsData={buttonsData} />}

            {((adventurer?.beastHealth ?? 0 > 0) ||
              formatBattles.length > 0) && (
              <>
                <div className="flex flex-col items-center gap-5 p-2">
                  <div className="text-xl uppercase">
                    Battle log with {beastData?.entity}
                  </div>
                  <div className="flex flex-col gap-2 text-sm">
                    {formatBattles.map((battle: any, index: number) => (
                      <BattleDisplay
                        key={index}
                        battleData={battle}
                        beastName={beastName}
                      />
                    ))}
                  </div>
                </div>
              </>
            )}
          </div>
        </>
      ) : (
        <>
          <div className="flex flex-col sm:w-1/3 gap-10 p-4">
            {!isBeastDead && <KeyboardControl buttonsData={buttonsData} />}

            {((adventurer?.beastHealth ?? 0 > 0) ||
              formatBattles.length > 0) && (
              <>
                <div className="flex flex-col items-center gap-5 p-2">
                  <div className="text-xl uppercase">
                    Battle log with {beastData?.entity}
                  </div>
                  <div className="flex flex-col gap-2">
                    {formatBattles.map((battle: any, index: number) => (
                      <BattleDisplay
                        key={index}
                        battleData={battle}
                        beastName={beastName}
                      />
                    ))}
                  </div>
                </div>
              </>
            )}
          </div>

          <div className="sm:w-1/3">
            {(adventurer?.beastHealth ?? 0 > 0) || lastBattle ? (
              <>
                <BeastDisplay
                  beastData={beastData}
                  lastBattle={formatBattles[0]}
                />
              </>
            ) : (
              <div className="flex flex-col items-center h-full overflow-hidden border-2 border-terminal-green">
                <p className="m-auto text-lg uppercase text-terminal-green">
                  Beast not yet discovered.
                </p>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
