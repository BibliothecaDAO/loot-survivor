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

const Adventurer = () => {
  const { account } = useAccount();
  const [activeMenu, setActiveMenu] = useState(0);
  const [selected, setSelected] = useState<String>("");
  const loading = useLoadingStore((state) => state.loading);
  const updateData = useLoadingStore((state) => state.updateData);
  const type = useLoadingStore((state) => state.type);

  const accountAddress = account ? account.address : "0x0";

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

  const {
    loading: adventurersByOwnerLoading,
    error: adventurersByOwnerError,
    data: adventurersByOwnerData,
    refetch: adventurersByOwnerRefetch,
  } = useQuery(getAdventurersByOwner, {
    variables: {
      owner: padAddress(accountAddress),
    },
    pollInterval: 5000,
  });

  const adventurers = adventurersByOwnerData
    ? adventurersByOwnerData.adventurers
    : [];

  useEffect(() => {
    if (loading && type == "Create") {
      updateData(adventurers);
    }
  }, [loading, adventurers]);

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
