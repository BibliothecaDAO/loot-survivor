import { useState } from "react";
import { Button } from "./Button";
import Info from "./Info";
import { useAccount } from "@starknet-react/core";
import { useQuery } from "@apollo/client";
import { getAdventurersByOwner } from "../hooks/graphql/queries";
import { padAddress } from "../lib/utils";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import { useAdventurer } from "../context/AdventurerProvider";

export const AdventurersList = () => {
  const { account } = useAccount();

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
  const buttonsData = [];
  for (let i = 0; i < adventurers.length; i++) {
    buttonsData.push({
      id: i + 1,
      label: adventurers[i].name,
      action: () => handleUpdateAdventurer(adventurers[i].id),
    });
  }

  return (
    <>
      {adventurers.length > 0 ? (
        <div className="flex basis-2/3">
          <div className="w-full">
            <Info />
          </div>
          <KeyboardControl buttonsData={buttonsData} />
        </div>
      ) : (
        <p className="text-lg loading-ellipsis">
          You do not have any adventurers!{" "}
        </p>
      )}
    </>
  );
};
