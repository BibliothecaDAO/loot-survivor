import { useMemo, useState, useEffect } from "react";
import { useQuery } from "@apollo/client";
import { useAccount } from "@starknet-react/core";
import { getAdventurersByOwner } from "../hooks/graphql/queries";
import { padAddress } from "../lib/utils";
import { AdventurersList } from "./AdventurersList";
import { CreateAdventurer } from "./CreateAdventurer";
import VerticalKeyboardControl from "./VerticalMenu";
import useLoadingStore from "../hooks/useLoadingStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useCustomQuery from "../hooks/useCustomQuery";
import { useQueriesStore } from "../hooks/useQueryStore";

const Adventurer = () => {
  const { account } = useAccount();
  const [activeMenu, setActiveMenu] = useState(0);
  const [selected, setSelected] = useState<String>("");

  const menu = [
    {
      id: 1,
      label: "Choose Adventurer",
      value: "choose adventurer",
      action: () => setSelected,
      disabled: false,
    },
    {
      id: 2,
      label: "Create Adventurer",
      value: "create adventurer",
      action: () => setSelected,
      disabled: false,
    },
  ];

  const { data } = useQueriesStore();

  console.log(data);

  const adventurers = data.adventurersByOwnerQuery
    ? data.adventurersByOwnerQuery.adventurers
    : [];

  return (
    <div className="flex flex-row gap-2 p-4">
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
