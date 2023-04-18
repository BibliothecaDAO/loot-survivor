import { useState } from "react";
import { Button } from "./Button";
import Info from "./Info";
import { useAccount } from "@starknet-react/core";
import { useQuery } from "@apollo/client";
import { getAdventurersByOwner } from "../hooks/graphql/queries";
import { padAddress } from "../lib/utils";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import VerticalKeyboardControl from "./VerticalMenu";
import { useAdventurer } from "../context/AdventurerProvider";
import FormComponent from "./Form";

export const CreateAdventurer = () => {
  const { account } = useAccount();
  const accountAddress = account ? account.address : "0x0";

  const { handleUpdateAdventurer } = useAdventurer();

  return (
    <div className="flex bg-black border border-white border-dotted">
      <FormComponent />
    </div>
  );
};
