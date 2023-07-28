import { useState } from "react";
import { useAccount } from "@starknet-react/core";
// import { getAdventurersByOwner } from "../hooks/graphql/queries";
import { padAddress } from "../lib/utils";
import { AdventurersList } from "../components/start/AdventurersList";
import { CreateAdventurer } from "../components/start/CreateAdventurer";
import VerticalKeyboardControl from "../components/menu/VerticalMenu";
import { useQueriesStore } from "../hooks/useQueryStore";
import LootIconLoader from "../components/icons/Loader";
import useCustomQuery from "../hooks/useCustomQuery";
import useLoadingStore from "../hooks/useLoadingStore";
import {
  getAdventurerById,
  getAdventurerByXP,
  getAdventurersByOwner,
} from "../hooks/graphql/queries";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { useMediaQuery } from "react-responsive";
import { NullAdventurer } from "../types";

/**
 * @container
 * @description Provides the start screen for the adventurer.
 */
export default function AdventurerScreen() {
  const [activeMenu, setActiveMenu] = useState(0);
  const [selected, setSelected] = useState<String>("");
  const [loading, setLoading] = useState(false);
  const { account } = useAccount();
  const adventurer = useAdventurerStore((state) => state.adventurer);

  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const txAccepted = useLoadingStore((state) => state.txAccepted);

  const adventurers = useQueriesStore(
    (state) => state.data.adventurersByOwnerQuery?.adventurers || []
  );
  const queryAdventurer = useQueriesStore(
    (state) => state.data.adventurerByIdQuery?.adventurers[0] || NullAdventurer
  );
  const resetData = useQueriesStore((state) => state.resetData);

  const owner = account?.address ? padAddress(account.address) : "";

  // useCustomQuery(
  //   "adventurerByIdQuery",
  //   getAdventurerById,
  //   {
  //     id: adventurer?.id ?? 0,
  //   },
  //   txAccepted
  // );

  useCustomQuery(
    "adventurersByXPQuery",
    getAdventurerByXP,
    undefined,
    txAccepted
  );

  // TODO: Remove polling
  useCustomQuery(
    "adventurersByOwnerQuery",
    getAdventurersByOwner,
    {
      owner: owner,
    },
    true
  );

  const menu = [
    {
      id: 1,
      label: "Choose Adventurer",
      value: "choose adventurer",
      action: () => setSelected("choose adventurer"),
      disabled: adventurers.length == 0,
    },
    {
      id: 2,
      label: "Create Adventurer",
      value: "create adventurer",
      action: () => {
        setSelected("create adventurer");
        setAdventurer(NullAdventurer);
        resetData("adventurerByIdQuery");
      },
      disabled: false,
    },
  ];

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  if (loading) {
    return <LootIconLoader />;
  }

  return (
    <div className="flex flex-col gap-2 sm:gap-0 sm:flex-row flex-wrap">
      <div className="w-full sm:w-2/12">
        <VerticalKeyboardControl
          buttonsData={menu}
          onSelected={(value) => setSelected(value)}
          isActive={activeMenu == 0}
          setActiveMenu={setActiveMenu}
          size={isMobileDevice ? "sm" : "lg"}
        />
      </div>

      {selected === "choose adventurer" && (
        <div className="flex flex-col sm:w-5/6">
          <p className="text-center text-xl sm:hidden uppercase">Adventurers</p>

          <AdventurersList
            isActive={activeMenu == 1}
            onEscape={() => setActiveMenu(0)}
            adventurers={adventurers}
          />
        </div>
      )}
      {selected === "create adventurer" && (
        <div className="flex flex-col sm:mx-auto sm:justify-center sm:flex-row gap-2 sm:w-8/12 md:w-10/12">
          <div className="sm:mr-5">
            <CreateAdventurer
              isActive={activeMenu == 2}
              onEscape={() => setActiveMenu(0)}
              adventurers={adventurers}
            />
          </div>
        </div>
      )}
    </div>
  );
}
