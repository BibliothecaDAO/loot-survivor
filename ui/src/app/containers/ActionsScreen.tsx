import { useState } from "react";
import { useContracts } from "../hooks/useContracts";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import useLoadingStore from "../hooks/useLoadingStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import VerticalKeyboardControl from "../components/menu/VerticalMenu";
import PurchaseHealth from "../components/actions/PurchaseHealth";
import Info from "../components/adventurer/Info";
import Discovery from "../components/actions/Discovery";
import useUIStore from "../hooks/useUIStore";
import { useQueriesStore } from "../hooks/useQueryStore";
import useCustomQuery from "../hooks/useCustomQuery";
import { getLatestDiscoveries } from "../hooks/graphql/queries";
import {
  MistIcon,
  HealthPotionsIcon,
  TargetIcon,
} from "../components/icons/Icons";
import { useMediaQuery } from "react-responsive";
import KillAdventurer from "../components/actions/KillAdventurer";

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
  const onboarded = useUIStore((state) => state.onboarded);

  const [selected, setSelected] = useState<string>("");
  const [activeMenu, setActiveMenu] = useState(0);

  const { data } = useQueriesStore();

  useCustomQuery(
    "latestDiscoveriesQuery",
    getLatestDiscoveries,
    {
      adventurerId: adventurer?.id ?? 0,
    },
    txAccepted
  );

  const latestDiscoveries = data.latestDiscoveriesQuery
    ? data.latestDiscoveriesQuery.discoveries
    : [];

  console.log(latestDiscoveries);

  const buttonsData = [
    {
      id: 1,
      label:
        adventurer?.beastHealth ?? 0 > 0 ? "Beast found!!" : "Into the mist",
      icon: <MistIcon />,
      value: "explore",
      action: async () => {
        // if (!isMobileDevice) {
        //   {
        //     addToCalls(exploreTx);
        //     startLoading(
        //       "Explore",
        //       "Exploring",
        //       "discoveryByTxHashQuery",
        //       adventurer?.id
        //     );
        //     await handleSubmitCalls(writeAsync).then((tx: any) => {
        //       if (tx) {
        //         setTxHash(tx.transaction_hash);
        //         addTransaction({
        //           hash: tx.transaction_hash,
        //           metadata: {
        //             method: `Explore with ${adventurer?.name}`,
        //           },
        //         });
        //       }
        //     });
        //   }
        // }
      },
      disabled: (adventurer?.beastHealth ?? 0) > 0 || loading,
      loading: loading,
    },
  ];
  if (onboarded) {
    buttonsData.push({
      id: 2,
      label: "Slay Adventurer",
      icon: <TargetIcon />,
      value: "kill adventurer",
      action: async () => setActiveMenu(2),
      disabled: loading,
      loading: loading,
    });
  }

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  return (
    <div className="flex flex-col sm:flex-row gap-5 sm:gap-0 overflow-hidden flex-wrap">
      <div className="hidden sm:block sm:w-1/3">
        <Info adventurer={adventurer} />
      </div>
      {isMobileDevice ? (
        <>
          <div className="flex flex-col items-center sm:w-1/3 bg-terminal-black">
            {selected == "explore" && (
              <Discovery discoveries={latestDiscoveries} />
            )}
          </div>
          <div className="flex flex-col sm:w-1/3 m-auto my-4 w-full px-8">
            <VerticalKeyboardControl
              buttonsData={buttonsData}
              onSelected={(value) => setSelected(value)}
              onEnterAction={true}
            />
          </div>
        </>
      ) : (
        <>
          <div className="flex flex-col sm:w-1/3 m-auto my-4 w-full px-8">
            <VerticalKeyboardControl
              buttonsData={buttonsData}
              onSelected={(value) => setSelected(value)}
              onEnterAction={true}
            />
          </div>

          <div className="flex flex-col sm:w-1/3 bg-terminal-black">
            {selected == "explore" && (
              <Discovery discoveries={latestDiscoveries} />
            )}
            {selected == "kill adventurer" && <KillAdventurer />}
          </div>
        </>
      )}
    </div>
  );
}
