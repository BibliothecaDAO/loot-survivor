import { useState, useEffect } from "react";
import { useContracts } from "../hooks/useContracts";
import { NullAdventurer } from "../types";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import {
  getLatestDiscoveries,
  getLastDiscovery,
} from "../hooks/graphql/queries";
import { useQuery } from "@apollo/client";
import useLoadingStore from "../hooks/useLoadingStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import VerticalKeyboardControl from "./VerticalMenu";
import PurchaseHealth from "./PurchaseHealth";
import Info from "./Info";
import Discovery from "./Discovery";
import useCustomQuery from "../hooks/useCustomQuery";
import useUIStore from "../hooks/useUIStore";
import { useQueriesStore } from "../hooks/useQueryStore";

export default function Actions() {
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const { adventurerContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const { addTransaction } = useTransactionManager();
  const { writeAsync } = useContractWrite({ calls });
  const loading = useLoadingStore((state) => state.loading);
  const startLoading = useLoadingStore((state) => state.startLoading);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const onboarded = useUIStore((state) => state.onboarded);

  const [selected, setSelected] = useState<string>("");
  const [activeMenu, setActiveMenu] = useState(0);

  const { data } = useQueriesStore();

  const latestDiscoveries = data.latestDiscoveriesQuery
    ? data.latestDiscoveriesQuery.discoveries
    : [];

  const exploreTx = {
    contractAddress: adventurerContract?.address ?? "",
    entrypoint: "explore",
    calldata: [adventurer?.id ?? "", "0"],
  };

  const buttonsData = [
    {
      id: 1,
      label: adventurer?.isIdle ? "Into the mist" : "Beast found!!",
      value: "explore",
      action: async () => {
        {
          addToCalls(exploreTx);
          startLoading(
            "Explore",
            "Exploring",
            "discoveryByTxHashQuery",
            adventurer?.id
          );
          await handleSubmitCalls(writeAsync).then((tx: any) => {
            if (tx) {
              setTxHash(tx.transaction_hash);
              addTransaction({
                hash: tx.transaction_hash,
                metadata: {
                  method: `Explore with ${adventurer?.name}`,
                },
              });
            }
          });
        }
      },
      disabled: !adventurer?.isIdle || loading,
      loading: loading,
    },
  ];

  if (onboarded) {
    buttonsData.push({
      id: 2,
      label: "Buy Health",
      value: "purchase health",
      action: async () => setActiveMenu(1),
      disabled: !adventurer?.isIdle || loading,
      loading: loading,
    });
  }

  return (
    <div className="flex flex-row overflow-hidden flex-wrap">
      <div className="sm:w-1/3">
        <Info adventurer={adventurer} />
      </div>
      <div className="flex flex-col sm:w-1/3 m-auto my-4 w-full px-8">
        <VerticalKeyboardControl
          buttonsData={buttonsData}
          onSelected={(value) => setSelected(value)}
          onEnterAction={true}
        />
      </div>

      <div className="flex flex-col sm:w-1/3 bg-terminal-black">
        {selected == "explore" && <Discovery discoveries={latestDiscoveries} />}
        {selected == "purchase health" &&
          (adventurer?.isIdle ? (
            <PurchaseHealth
              isActive={activeMenu == 1}
              onEscape={() => setActiveMenu(0)}
            />
          ) : (
            <p>You are in a battle!</p>
          ))}
      </div>
    </div>
  );
}
