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
  getAdventurerById,
} from "../hooks/graphql/queries";
import { MistIcon } from "../components/icons/Icons";
import { padAddress } from "../lib/utils";
import BeastScreen from "./BeastScreen";

/**
 * @container
 * @description Provides the actions screen for the adventurer.
 */
export default function ActionsScreen() {
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const { gameContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const { addTransaction } = useTransactionManager();
  const { writeAsync } = useContractWrite({ calls });
  const loading = useLoadingStore((state) => state.loading);
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const startLoading = useLoadingStore((state) => state.startLoading);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const hash = useLoadingStore((state) => state.hash);
  const [selected, setSelected] = useState<string>("");

  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);

  const latestDiscoveries = useQueriesStore((state) =>
    state.data.latestDiscoveriesQuery
      ? state.data.latestDiscoveriesQuery.discoveries
      : []
  );

  useCustomQuery(
    "adventurerByIdQuery",
    getAdventurerById,
    {
      id: adventurer?.id ?? 0,
    },
    txAccepted
  );

  useCustomQuery(
    "discoveryByTxHashQuery",
    getDiscoveryByTxHash,
    {
      txHash: padAddress(hash),
    },
    txAccepted
  );

  useCustomQuery(
    "latestDiscoveriesQuery",
    getLatestDiscoveries,
    {
      adventurerId: adventurer?.id ?? 0,
    },
    txAccepted
  );

  const exploreTx = {
    contractAddress: gameContract?.address ?? "",
    entrypoint: "explore",
    calldata: [adventurer?.id?.toString() ?? "", "0"],
  };

  const buttonsData = [
    {
      id: 1,
      label: hasBeast ? "Beast found!!" : "Into the mist",
      icon: <MistIcon />,
      value: "explore",
      action: async () => {
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
      },
      disabled: hasBeast || loading || !adventurer?.id,
      loading: loading,
    },
  ];

  return (
    <div className="flex flex-col sm:flex-row flex-wrap">
      <div className="hidden sm:block sm:w-1/3">
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
          <div className="flex flex-col sm:w-1/3 m-auto my-4 w-full px-4 sm:order-1">
            <VerticalKeyboardControl
              buttonsData={buttonsData}
              onSelected={(value) => setSelected(value)}
              onEnterAction={true}
              size="lg"
            />
          </div>
        </>
      )}
    </div>
  );
}
