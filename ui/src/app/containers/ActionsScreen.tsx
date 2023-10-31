import { Contract } from "starknet";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import Info from "@/app/components/adventurer/Info";
import Discovery from "@/app/components/actions/Discovery";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import BeastScreen from "@/app/containers/BeastScreen";
import MazeLoader from "@/app/components/icons/MazeLoader";
import useUIStore from "@/app/hooks/useUIStore";
import ActionMenu from "@/app/components/menu/ActionMenu";
import { Beast } from "@/app/types";

interface ActionsScreenProps {
  explore: (till_beast: boolean) => Promise<void>;
  attack: (tillDeath: boolean, beastData: Beast) => Promise<void>;
  flee: (tillDeath: boolean, beastData: Beast) => Promise<void>;
  gameContract: Contract;
  beastsContract: Contract;
}

/**
 * @container
 * @description Provides the actions screen for the adventurer.
 */
export default function ActionsScreen({
  explore,
  attack,
  flee,
  gameContract,
  beastsContract,
}: ActionsScreenProps) {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const loading = useLoadingStore((state) => state.loading);
  const estimatingFee = useUIStore((state) => state.estimatingFee);

  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const resetNotification = useLoadingStore((state) => state.resetNotification);
  const latestDiscoveries = useQueriesStore((state) =>
    state.data.latestDiscoveriesQuery
      ? state.data.latestDiscoveriesQuery.discoveries
      : []
  );

  const buttonsData = [
    {
      id: 1,
      label: loading ? "Exploring..." : hasBeast ? "Beast found!!" : "Once",
      value: "explore",
      action: async () => {
        resetNotification();
        await explore(false);
      },
      disabled: hasBeast || loading || !adventurer?.id || estimatingFee,
      loading: loading,
      className:
        "bg-terminal-green-25 hover:bg-terminal-green hover:text-black",
    },
    {
      id: 2,
      label: loading
        ? "Exploring..."
        : hasBeast
        ? "Beast found!!"
        : "Till Beast",
      value: "explore",
      action: async () => {
        resetNotification();
        await explore(true);
      },
      disabled: hasBeast || loading || !adventurer?.id || estimatingFee,
      loading: loading,
      className:
        "bg-terminal-green-50 hover:bg-terminal-green hover:text-black",
    },
  ];

  return (
    <div className="flex flex-col sm:flex-row flex-wrap h-full w-full">
      <div className="hidden sm:block sm:w-1/2 lg:w-1/3 h-full">
        <Info adventurer={adventurer} gameContract={gameContract} />
      </div>

      {hasBeast ? (
        <BeastScreen
          attack={attack}
          flee={flee}
          beastsContract={beastsContract}
        />
      ) : (
        <div className="flex flex-col sm:flex-row h-full w-full sm:w-1/2 lg:w-2/3">
          {adventurer?.id ? (
            <div className="flex flex-col items-center lg:w-1/2 bg-terminal-black order-1 sm:order-2 h-5/6 sm:h-full">
              <Discovery discoveries={latestDiscoveries} />
            </div>
          ) : (
            <p className="text-xl text-center order-1 sm:order-2">
              Please Select an Adventurer
            </p>
          )}
          <div className="flex flex-col items-center lg:w-1/2 my-4 w-full px-4 sm:order-1 h-1/6 sm:h-full">
            {loading && <MazeLoader />}
            <div className="w-3/4 h-full sm:h-1/6">
              <ActionMenu
                buttonsData={buttonsData}
                size="fill"
                title="Explore"
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
