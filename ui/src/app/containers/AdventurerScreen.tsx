import { useEffect, useState } from "react";
import { Contract } from "starknet";
import { AdventurersList } from "@/app/components/start/AdventurersList";
import { CreateAdventurer } from "@/app/components/start/CreateAdventurer";
import ButtonMenu from "@/app/components/menu/ButtonMenu";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { NullAdventurer, FormData } from "@/app/types";
import useUIStore from "@/app/hooks/useUIStore";

interface AdventurerScreenProps {
  spawn: (formData: FormData, goldenTokenId: string) => Promise<void>;
  handleSwitchAdventurer: (adventurerId: number) => Promise<void>;
  lordsBalance?: bigint;
  gameContract: Contract;
  goldenTokenData: any;
  getBalances: () => Promise<void>;
}

/**
 * @container
 * @description Provides the start screen for the adventurer.
 */
export default function AdventurerScreen({
  spawn,
  handleSwitchAdventurer,
  lordsBalance,
  gameContract,
  goldenTokenData,
  getBalances,
}: AdventurerScreenProps) {
  const [activeMenu, setActiveMenu] = useState(0);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const adventurers = useQueriesStore(
    (state) => state.data.adventurersByOwnerQuery?.adventurers || []
  );
  const resetData = useQueriesStore((state) => state.resetData);
  const startOption = useUIStore((state) => state.startOption);
  const setStartOption = useUIStore((state) => state.setStartOption);

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

  return (
    <div className="flex flex-col gap-2 sm:gap-0 sm:flex-row flex-wrap h-full">
      <div className="w-full sm:w-2/12">
        <ButtonMenu
          buttonsData={menu}
          onSelected={(value) => setStartOption(value)}
          isActive={activeMenu == 0}
          setActiveMenu={setActiveMenu}
          size={"xs"}
          className="sm:flex-col"
        />
      </div>

      {startOption === "create adventurer" && (
        <div className="flex flex-col sm:mx-auto sm:justify-center sm:flex-row gap-2 sm:w-8/12 md:w-10/12">
          <CreateAdventurer
            isActive={activeMenu == 1}
            onEscape={() => setActiveMenu(0)}
            spawn={spawn}
            lordsBalance={lordsBalance}
            goldenTokenData={goldenTokenData}
            gameContract={gameContract}
            getBalances={getBalances}
          />
        </div>
      )}

      {startOption === "choose adventurer" && (
        <div className="flex flex-col sm:w-5/6 h-[500px] sm:h-full">
          <p className="text-center text-xl sm:hidden uppercase">Adventurers</p>

          <AdventurersList
            isActive={activeMenu == 2}
            onEscape={() => setActiveMenu(0)}
            adventurers={adventurers}
            handleSwitchAdventurer={handleSwitchAdventurer}
            gameContract={gameContract}
          />
        </div>
      )}
    </div>
  );
}
