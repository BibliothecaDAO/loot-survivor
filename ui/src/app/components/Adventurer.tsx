import { useMemo, useState, useEffect } from "react";
import { useQuery } from "@apollo/client";
import { useAccount } from "@starknet-react/core";
import { getAdventurersByOwner } from "../hooks/graphql/queries";
import { padAddress } from "../lib/utils";
import { AdventurersList } from "./AdventurersList";
import { CreateAdventurer } from "./CreateAdventurer";
import VerticalKeyboardControl from "./VerticalMenu";
import { useQueriesStore } from "../hooks/useQueryStore";
import useUIStore from "../hooks/useUIStore";

const Adventurer = () => {
  const [activeMenu, setActiveMenu] = useState(0);
  const [selected, setSelected] = useState<String>("");
  const setScreen = useUIStore((state) => state.setScreen);

  const { data } = useQueriesStore();

  const adventurers = data.adventurersByOwnerQuery
    ? data.adventurersByOwnerQuery.adventurers
    : [];

  const handleMenu = () => {
    if (adventurers == 0) {
      const menu = [
        {
          id: 1,
          label: "Create Adventurer",
          value: "create adventurer",
          action: () => setSelected,
          disabled: false,
        },
      ];
      return menu;
    } else {
      const menu = [
        {
          id: 1,
          label: "Choose Adventurer",
          value: "choose adventurer",
          action: () => setSelected,
          disabled: adventurers.length == 0,
        },
        {
          id: 2,
          label: "Create Adventurer",
          value: "create adventurer",
          action: () => setSelected,
          disabled: false,
        },
      ];
      return menu;
    }
  };

  const menu = handleMenu();

  return (
    <div className="flex flex-row">
      <div className="w-2/12">
        <VerticalKeyboardControl
          buttonsData={menu}
          onSelected={(value) => setSelected(value)}
          isActive={activeMenu == 0}
          setActiveMenu={setActiveMenu}
        />
      </div>

      {selected === "choose adventurer" && (
        <div className="w-2/3">
          <AdventurersList
            isActive={activeMenu == 1}
            onEscape={() => setActiveMenu(0)}
            adventurers={adventurers}
          />
        </div>
      )}
      {selected === "create adventurer" && (
        <div className="w-full">
          <CreateAdventurer
            isActive={activeMenu == 2}
            onEscape={() => setActiveMenu(0)}
            adventurers={adventurers}
          />
        </div>
      )}
    </div>
  );
};

export default Adventurer;
