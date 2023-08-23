import { useState } from "react";
import { useContracts } from "../hooks/useContracts";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import useLoadingStore from "../hooks/useLoadingStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import VerticalKeyboardControl from "../components/menu/VerticalMenu";
import Info from "../components/adventurer/Info";
import Discovery from "../components/actions/Discovery";
import { useQueriesStore } from "../hooks/useQueryStore";
import useCustomQuery from "../hooks/useCustomQuery";
import {
  getLatestDiscoveries,
  getDiscoveryByTxHash,
  getLastBeastDiscovery,
  getBeast,
  getBattlesByBeast,
} from "../hooks/graphql/queries";
import { MistIcon } from "../components/icons/Icons";
import { padAddress } from "../lib/utils";
import BeastScreen from "./BeastScreen";
import { NullDiscovery } from "../types";
import useUIStore from "../hooks/useUIStore";
import { Syscalls } from "@/app/lib/utils/Syscalls";

/**
 * @container
 * @description Provides the actions screen for the adventurer.
 */
export default function ActionsScreen() {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const loading = useLoadingStore((state) => state.loading);
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const hash = useLoadingStore((state) => state.hash);
  const [selected, setSelected] = useState<string>("");

  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);

  const latestDiscoveries = useQueriesStore((state) =>
    state.data.latestDiscoveriesQuery
      ? state.data.latestDiscoveriesQuery.discoveries
      : []
  );
  const lastBeast = useQueriesStore(
    (state) => state.data.lastBeastQuery?.discoveries[0] || NullDiscovery
  );

  const { explore } = Syscalls();

  useCustomQuery("discoveryByTxHashQuery", getDiscoveryByTxHash, {
    txHash: padAddress(hash),
  });

  useCustomQuery("latestDiscoveriesQuery", getLatestDiscoveries, {
    adventurerId: adventurer?.id ?? 0,
  });

  useCustomQuery("lastBeastQuery", getLastBeastDiscovery, {
    adventurerId: adventurer?.id ?? 0,
  });

  useCustomQuery("beastQuery", getBeast, {
    adventurerId: adventurer?.id ?? 0,
    beast: lastBeast?.entity,
    seed: lastBeast?.seed,
  });

  useCustomQuery("battlesByBeastQuery", getBattlesByBeast, {
    adventurerId: adventurer?.id ?? 0,
    beast: lastBeast?.entity,
    seed: lastBeast?.seed,
  });

  const buttonsData = [
    {
      id: 1,
      label: loading ? "Exploring..." : hasBeast ? "Beast found!!" : "Explore",
      icon: <MistIcon />,
      value: "explore",
      action: async () => {
        explore(false);
      },
      disabled: hasBeast || loading || !adventurer?.id,
      loading: loading,
    },
    {
      id: 2,
      label: loading
        ? "Exploring..."
        : hasBeast
        ? "Beast found!!"
        : "Till Beast",
      icon: <MistIcon />,
      value: "explore",
      action: async () => {
        explore(true);
      },
      disabled: hasBeast || loading || !adventurer?.id,
      loading: loading,
    },
  ];

  return (
    <div className="flex flex-col sm:flex-row flex-wrap">
      <div className="hidden sm:block sm:w-1/2 lg:w-1/3">
        <Info adventurer={adventurer} />
      </div>

      {hasBeast ? (
        <BeastScreen />
      ) : (
        <>
          {adventurer?.id ? (
            <div className="flex flex-col items-center sm:w-1/3 bg-terminal-black order-1 sm:order-2">
              {selected == "explore" && (
                <Discovery discoveries={latestDiscoveries} />
              )}
            </div>
          ) : (
            <p className="text-xl text-center order-1 sm:order-2">
              Please Select an Adventurer
            </p>
          )}
          <div className="flex flex-col items-center sm:w-1/3 m-auto my-4 w-full px-4 sm:order-1">
            <p className="uppercase text-2xl">Into the Mist</p>
            <VerticalKeyboardControl
              buttonsData={buttonsData}
              onSelected={(value) => setSelected(value)}
              onEnterAction={true}
              size="sm"
            />
          </div>
        </>
      )}
    </div>
  );
}
