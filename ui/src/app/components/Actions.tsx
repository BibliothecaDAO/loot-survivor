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
  const type = useLoadingStore((state) => state.type);
  const updateData = useLoadingStore((state) => state.updateData);

  const [selected, setSelected] = useState<string>("");
  const [activeMenu, setActiveMenu] = useState(0);

  const { data: latestDiscoveriesData, loading: latestDiscoverieslLoading } =
    useQuery(getLatestDiscoveries, {
      variables: {
        adventurerId: adventurer?.id,
      },
      pollInterval: 5000,
    });

  const latestDiscoveries = latestDiscoveriesData
    ? latestDiscoveriesData.discoveries
    : [];

  const exploreTx = {
    contractAddress: adventurerContract?.address ?? "",
    entrypoint: "explore",
    calldata: [adventurer?.id ?? "", "0"],
  };

  const buttonsData = [
    {
      id: 1,
      label: "Into the mist",
      value: "explore",
      action: async () => {
        {
          addToCalls(exploreTx);
          await handleSubmitCalls(writeAsync).then((tx: any) => {
            if (tx) {
              startLoading(
                "Explore",
                tx.transaction_hash,
                "Exploring",
                latestDiscoveries
              );
              addTransaction({
                hash: tx.transaction_hash,
                metadata: {
                  method: "Explore",
                  description: `Exploring with ${adventurer?.name}`,
                },
              });
            }
          });
        }
      },
      disabled: adventurer?.status !== "Idle",
    },
    {
      id: 2,
      label: "Buy Health",
      value: "purchase health",
      action: () => setActiveMenu(1),
      disabled: adventurer?.status !== "Idle",
    },
  ];

  useEffect(() => {
    if (loading && type == "Explore") {
      updateData(latestDiscoveries);
    }
  }, [loading, latestDiscoveries]);

  return (
    <div className="flex flex-row space-x-6 ">
      <div className="w-1/3">
        <Info adventurer={adventurer} />
      </div>
      <div className="flex flex-col w-1/3 m-auto">
        <VerticalKeyboardControl
          buttonsData={buttonsData}
          onSelected={(value) => setSelected(value)}
          onEnterAction={true}
        />
      </div>

      <div className="flex flex-col w-1/3 bg-terminal-black">
        {selected == "explore" && <Discovery discoveries={latestDiscoveries} />}
        {selected == "purchase health" &&
          (adventurer?.status == "Idle" ? (
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
