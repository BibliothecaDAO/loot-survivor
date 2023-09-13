import { useEffect, useState, useMemo } from "react";
import { useAccount } from "@starknet-react/core";
// import { getAdventurersByOwner } from "../hooks/graphql/queries";
import { AdventurersList } from "../components/start/AdventurersList";
import { CreateAdventurer } from "../components/start/CreateAdventurer";
import VerticalKeyboardControl from "../components/menu/VerticalMenu";
import { useQueriesStore } from "../hooks/useQueryStore";
import LootIconLoader from "../components/icons/Loader";
import useLoadingStore from "../hooks/useLoadingStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { NullAdventurer } from "../types";
import useUIStore from "../hooks/useUIStore";

interface AdventurerScreenProps {
  spawn: (...args: any[]) => any;
  handleSwitchAdventurer: (...args: any[]) => any;
}

/**
 * @container
 * @description Provides the start screen for the adventurer.
 */
export default function AdventurerScreen({
  spawn,
  handleSwitchAdventurer,
}: AdventurerScreenProps) {
  const [activeMenu, setActiveMenu] = useState(0);
  const [loading, setLoading] = useState(false);
  const { account } = useAccount();
  const adventurer = useAdventurerStore((state) => state.adventurer);

  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const { data } = useQueriesStore();
  const adventurers = useQueriesStore(
    (state) => state.data.adventurersByOwnerQuery?.adventurers || []
  );
  const queryAdventurer = useQueriesStore(
    (state) => state.data.adventurerByIdQuery?.adventurers[0] || NullAdventurer
  );
  const resetData = useQueriesStore((state) => state.resetData);
  const startOption = useUIStore((state) => state.startOption);
  const setStartOption = useUIStore((state) => state.setStartOption);

  console.log(startOption);

  // const owner = account?.address ? padAddress(account.address) : "";

  // const ownerVariables = useMemo(() => {
  //   return {
  //     owner: owner,
  //   };
  // }, [owner]);

  // useCustomQuery(
  //   "adventurersByOwnerQuery",
  //   getAdventurersByOwner,
  //   ownerVariables
  // );

  const menu = [
    {
      id: 1,
      label: "Create Adventurer",
      value: "create adventurer",
      action: () => {
        setStartOption("create adventurer");
        setAdventurer(NullAdventurer);
        resetData("adventurerByIdQuery");
      },
      disabled: false,
    },
    {
      id: 2,
      label: "Choose Adventurer",
      value: "choose adventurer",
      action: () => {
        setStartOption("choose adventurer");
      },
      disabled: adventurers.length == 0,
    },
  ];

  useEffect(() => {
    if (adventurers.length == 0) {
      setStartOption("create adventurer");
    }
  }, []);

  if (loading) {
    return <LootIconLoader />;
  }

  return (
    <div className="flex flex-col gap-2 sm:gap-0 sm:flex-row flex-wrap">
      <div className="w-full sm:w-2/12">
        <VerticalKeyboardControl
          buttonsData={menu}
          onSelected={(value) => setStartOption(value)}
          isActive={activeMenu == 0}
          setActiveMenu={setActiveMenu}
          size={"lg"}
        />
      </div>

      {startOption === "create adventurer" && (
        <div className="flex flex-col sm:mx-auto sm:justify-center sm:flex-row gap-2 sm:w-8/12 md:w-10/12">
          <CreateAdventurer
            isActive={activeMenu == 1}
            onEscape={() => setActiveMenu(0)}
            spawn={spawn}
          />
        </div>
      )}

      {startOption === "choose adventurer" && (
        <div className="flex flex-col sm:w-5/6">
          <p className="text-center text-xl sm:hidden uppercase">Adventurers</p>

          <AdventurersList
            isActive={activeMenu == 2}
            onEscape={() => setActiveMenu(0)}
            adventurers={adventurers}
            handleSwitchAdventurer={handleSwitchAdventurer}
          />
        </div>
      )}
    </div>
  );
}
