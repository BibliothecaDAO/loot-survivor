import { useState, useEffect, useRef } from "react";
import { Button } from "./Button";
import Info from "./Info";
import { useAccount } from "@starknet-react/core";
import { useQuery } from "@apollo/client";
import { getAdventurersByOwner } from "../hooks/graphql/queries";
import { padAddress } from "../lib/utils";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import { useAdventurer } from "../context/AdventurerProvider";

export interface AdventurerListProps {
  isActive: boolean;
  onEscape: () => void;
}

export const AdventurersList = ({
  isActive,
  onEscape,
}: AdventurerListProps) => {
  const { account } = useAccount();
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  const accountAddress = account ? account.address : "0x0";
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
  const { handleUpdateAdventurer } = useAdventurer();
  const buttonsData: ButtonData[] = [];
  for (let i = 0; i < adventurers.length; i++) {
    buttonsData.push({
      id: i + 1,
      label: adventurers[i].name,
      action: () => handleUpdateAdventurer(adventurers[i].id),
    });
  }

  const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
      case "ArrowUp":
        setSelectedIndex((prev) => Math.max(prev - 1, 0));
        break;
      case "ArrowDown":
        setSelectedIndex((prev) => Math.min(prev + 1, buttonsData.length - 1));
        break;
      case "Enter":
        buttonsData[selectedIndex].action();
        break;
      case "Escape":
        onEscape();
        break;
    }
  };

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
    } else {
      window.removeEventListener("keydown", handleKeyDown);
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isActive, selectedIndex]);

  return (
    <>
      {!adventurersByOwnerLoading ? (
        adventurers.length > 0 ? (
          <div className="flex basis-2/3">
            <div className="flex flex-col w-1/2">
              {buttonsData.map((buttonData, index) => (
                <Button
                  key={buttonData.id}
                  ref={(ref) => (buttonRefs.current[index] = ref)}
                  className={
                    selectedIndex === index && isActive ? "animate-pulse" : ""
                  }
                  variant={
                    selectedIndex === index && isActive ? "default" : "ghost"
                  }
                  onClick={() => {
                    buttonData.action();
                    setSelectedIndex(index);
                  }}
                >
                  {buttonData.label}
                </Button>
              ))}
            </div>
            <div className="w-1/2">
              <Info adventurer={adventurers[selectedIndex]} />
            </div>
          </div>
        ) : (
          <p className="text-lg">You do not have any adventurers!</p>
        )
      ) : (
        <p className="text-lg loading-ellipsis">Loading adventurers</p>
      )}
    </>
  );
};
