import { useState, useEffect, useRef, useCallback, useMemo } from "react";
import { Contract } from "starknet";
import { Button } from "@/app/components/buttons/Button";
import Info from "@/app/components/adventurer/Info";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { SkullIcon } from "@/app/components/icons/Icons";
import useUIStore from "@/app/hooks/useUIStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import LootIconLoader from "@/app/components/icons/Loader";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import { getAdventurersByOwner } from "@/app/hooks/graphql/queries";
import useNetworkAccount from "@/app/hooks/useNetworkAccount";
import { indexAddress, padAddress } from "@/app/lib/utils";
import { Adventurer } from "@/app/types";

export interface AdventurerListProps {
  isActive: boolean;
  onEscape: () => void;
  handleSwitchAdventurer: (adventurerId: number) => Promise<void>;
  gameContract: Contract;
  adventurersCount: number;
  aliveAdventurersCount: number;
}

export const AdventurersList = ({
  isActive,
  onEscape,
  handleSwitchAdventurer,
  gameContract,
  adventurersCount,
  aliveAdventurersCount,
}: AdventurerListProps) => {
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const [showZeroHealth, setShowZeroHealth] = useState(true);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const network = useUIStore((state) => state.network);
  const { account } = useNetworkAccount();
  const owner = account?.address ? padAddress(account.address) : "";
  const adventurersPerPage = 10;
  const [currentPage, setCurrentPage] = useState<number>(1);
  const skip = (currentPage - 1) * adventurersPerPage;

  const { isLoading } = useQueriesStore();

  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);

  const adventurersVariables = useMemo(() => {
    return {
      owner: indexAddress(owner),
      health: showZeroHealth ? 0 : 1,
      skip: skip,
    };
  }, [owner, skip, showZeroHealth]);

  const adventurersData = useCustomQuery(
    network,
    "adventurersByOwnerQuery",
    getAdventurersByOwner,
    adventurersVariables,
    owner === ""
  );

  const adventurers: Adventurer[] = adventurersData?.adventurers ?? [];

  const totalPages = useMemo(
    () =>
      Math.ceil(
        (showZeroHealth ? adventurersCount : aliveAdventurersCount) /
          adventurersPerPage
      ),
    [adventurersCount, aliveAdventurersCount, showZeroHealth]
  );

  const formatAdventurersCount = showZeroHealth
    ? adventurersCount
    : aliveAdventurersCount;

  const handleClick = (newPage: number): void => {
    if (newPage >= 1 && newPage <= totalPages) {
      setCurrentPage(newPage);
    }
  };

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      switch (event.key) {
        case "ArrowUp":
          setSelectedIndex((prev) => Math.max(prev - 1, 0));
          break;
        case "ArrowDown":
          setSelectedIndex((prev) =>
            Math.min(prev + 1, adventurers.length - 1)
          );
          break;
        case "Enter":
          setAdventurer(adventurers[selectedIndex]);
          break;
        case "Escape":
          onEscape();
          break;
      }
    },
    [setAdventurer, onEscape, selectedIndex, adventurers]
  );

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
    } else {
      window.removeEventListener("keydown", handleKeyDown);
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isActive, handleKeyDown]);

  return (
    <div className="flex flex-col items-center h-full">
      {formatAdventurersCount > 0 ? (
        <div className="flex flex-col gap-2 sm:flex-row w-full h-full items-center sm:items-start">
          <div className="flex flex-col w-full sm:w-1/3 overflow-y-auto default-scroll mx-2 border border-terminal-green sm:border-none h-[350px] xl:h-[500px] 2xl:h-[625px] p-1">
            {adventurers.map((adventurer, index) => (
              <Button
                key={index}
                ref={(ref) => (buttonRefs.current[index] = ref)}
                className={
                  selectedIndex === index && isActive
                    ? "animate-pulse text-lg sm:text-base"
                    : "text-lg sm:text-base"
                }
                variant={
                  selectedIndex === index && isActive ? "default" : "ghost"
                }
                onClick={async () => {
                  setAdventurer(adventurer);
                  await handleSwitchAdventurer(adventurer.id!);
                  setSelectedIndex(index);
                }}
                disabled={adventurer?.health === 0}
              >
                <div className="flex flex-row items-center text-center gap-5">
                  <p>{`${adventurer.name} - ${adventurer.id}`}</p>
                  {adventurer?.health === 0 && (
                    <SkullIcon className="w-3 fill-current" />
                  )}
                </div>
              </Button>
            ))}
            {formatAdventurersCount > 10 && (
              <div className="flex justify-center mt-8">
                <Button
                  variant={"outline"}
                  onClick={() =>
                    currentPage > 1 && handleClick(currentPage - 1)
                  }
                  disabled={currentPage === 1}
                >
                  back
                </Button>

                <Button
                  variant={"outline"}
                  onClick={() =>
                    currentPage < totalPages && handleClick(currentPage + 1)
                  }
                  disabled={currentPage === totalPages}
                >
                  next
                </Button>
              </div>
            )}
          </div>
          <div>
            {formatAdventurersCount > 0 && (
              <Button
                className="w-full h-full"
                size={"xs"}
                onClick={() => setShowZeroHealth(!showZeroHealth)}
              >
                {showZeroHealth ? "Hide" : "Show"} dead
              </Button>
            )}
          </div>
          {adventurers.length > 0 && (
            <div className="hidden sm:block sm:w-6/12 md:w-6/12 lg:w-2/3 w-full h-full">
              {isLoading.global ? (
                <div className="flex justify-center items-center h-full">
                  <LootIconLoader size="w-10" />
                </div>
              ) : (
                <Info
                  adventurer={adventurers[selectedIndex]}
                  gameContract={gameContract}
                />
              )}
            </div>
          )}
        </div>
      ) : (
        <p className="text-lg uppercase flex-1">
          You do not have any adventurers!
        </p>
      )}
    </div>
  );
};
