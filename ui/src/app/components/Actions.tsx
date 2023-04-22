import { useState } from "react";
import { Button } from "./Button";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurer } from "../types";
import {
  useTransaction,
  useTransactions,
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import Image from "next/image";
import VerticalKeyboardControl from "./VerticalMenu";
import HealthSlider from "./HealthSlider";
import PurchaseHealth from "./PurchaseHealth";
import Info from "./Info";
import Discovery from "./Discovery";

export default function Actions() {
  const [loading, setLoading] = useState(false);
  const { handleSubmitCalls, addToCalls, calls } = useTransactionCart();
  const { adventurerContract } = useContracts();
  const { adventurer, handleUpdateAdventurer } = useAdventurer();
  const { hashes, transactions, addTransaction } = useTransactionManager();
  const [selected, setSelected] = useState<String>("");
  const [activeMenu, setActiveMenu] = useState(0);
  const [hash, setHash] = useState();

  const formatAdventurer = adventurer ? adventurer.adventurer : NullAdventurer;

  const exploreTx = {
    contractAddress: adventurerContract?.address,
    selector: "explore",
    calldata: [formatAdventurer?.id, "0"],
  };

  const buttonsData = [
    {
      id: 1,
      label: "Explore",
      value: "explore",
      action: async () => {
        {
          addToCalls(exploreTx);
          await handleSubmitCalls().then((tx: any) => {
            setHash(tx.transaction_hash);
            addTransaction({
              hash: tx.transaction_hash,
              metadata: {
                method: "Explore",
                description: `Exploring with ${formatAdventurer?.name}`,
              },
            });
          });
        }
      },
    },
    {
      id: 2,
      label: "Purchase Health",
      value: "purchase health",
      action: () => setActiveMenu(1),
    },
  ];

  return (
    <div className="flex flex-row mt-5">
      {!loading ? (
        <div className="w-1/3">
          <Info adventurer={adventurer?.adventurer} />
        </div>
      ) : null}
      <div className="w-1/3 my-auto">
        <VerticalKeyboardControl
          buttonsData={buttonsData}
          onSelected={(value) => setSelected(value)}
          onEnterAction={true}
        />
      </div>

      <div className="flex flex-col w-1/3 bg-terminal-black p-2">
        {selected == "explore" && <Discovery hash={hash} />}
        {selected == "purchase health" && (
          <PurchaseHealth
            isActive={activeMenu == 1}
            onEscape={() => setActiveMenu(0)}
          />
        )}
      </div>
    </div>
  );
}
