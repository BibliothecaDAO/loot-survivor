import { useState } from "react";
import { Button } from "./Button";
import { useContracts } from "../hooks/useContracts";
import { useWriteContract } from "../hooks/useWriteContract";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import { useQuery } from "@apollo/client";
import { getItemsByTokenId } from "../hooks/graphql/queries";
import {
  useTransaction,
  useTransactions,
  useTransactionManager,
} from "@starknet-react/core";
import Image from "next/image";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import HealthSlider from "./HealthSlider";
import Info from "./Info";

export default function Beast() {
  const [loading, setLoading] = useState(false);

  const { writeAsync, addToCalls, calls } = useWriteContract();
  const { adventurerContract } = useContracts();
  const { adventurer, handleUpdateAdventurer } = useAdventurer();

  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

  // const accountAddress = account ? account.address : "0x0";
  //   const {
  //     loading: beastByTokenIdLoading,
  //     error: beastByTokenIdError,
  //     data: beastByTokenIdData,
  //     refetch: beastByTokenIdRefetch,
  //   } = useQuery(getBeastByTokenId, {
  //     variables: {
  //       id: tokenid,
  //     },
  //     pollInterval: 5000,
  //   });

  // const [hash, setHash] = useState<string | undefined>(undefined);

  // const attack = {
  //   contractAddress: lootContract?.address,
  //   selector: "attack",
  //   calldata: [formatAddress],
  // };

  // const flee = {
  //   contractAddress: lootContract?.address,
  //   selector: "flee",
  //   calldata: [formatAddress],
  // };

  const buttonsData: ButtonData[] = [
    {
      id: 1,
      label: "ATTACK BEAST!",
      action: async () => {
        // addToCalls(explore);
        // console.log(calls);
        // await writeAsync().then((tx) => setHash(tx.transaction_hash));
      },
    },
    {
      id: 2,
      label: "FLEE BEAST",
      action: async () => await writeAsync(),
    },
  ];

  // const handlePurchase = (health: number) => {
  //   console.log(`Purchased ${health} health.`);
  // };

  return (
    <div className="flex flex-row mt-5">
      {!loading ? (
        <div className="w-1/4">
          <Info />
        </div>
      ) : null}
      <div className="w-1/4">
        <KeyboardControl buttonsData={buttonsData} />
      </div>
      {/* <p>Health Purchase</p>
        <HealthSlider onPurchase={handlePurchase} /> */}

      <div className="flex flex-col w-1/2 bg-terminal-black">HLLO</div>
    </div>
  );
}
