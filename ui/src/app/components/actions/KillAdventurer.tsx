import { useState } from "react";
import { Button } from "../buttons/Button";
import { useContracts } from "@/app/hooks/useContracts";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { useUiSounds, soundSelector } from "../../hooks/useUiSound";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import { getAdventurerById } from "../../hooks/graphql/queries";
import useLoadingStore from "@/app/hooks/useLoadingStore";
// import { Info } from "../adventurer/Info"

export default function KillAdventurer() {
  const { gameContract } = useContracts();
  const [adventurerTarget, setAdventurerTarget] = useState("");
  const addToCalls = useTransactionCartStore((s) => s.addToCalls);
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  const txAccepted = useLoadingStore((state) => state.txAccepted);

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setAdventurerTarget(event.target.value);
  };

  const purchaseHealthTx = {
    contractAddress: gameContract?.address ?? "",
    entrypoint: "slay_idle_adventurer",
    calldata: [adventurerTarget],
    metadata: `Slaying ${adventurerTarget}`,
  };

  const handleSlayAdventurer = async () => {
    addToCalls(purchaseHealthTx);
  };

  useCustomQuery(
    "adventurerByIdQuery",
    getAdventurerById,
    {
      id: adventurerTarget,
    },
    txAccepted
  );

  return (
    <div className="flex flex-col">
      <h4>Kill Idle Adventurer</h4>
      <label className="flex justify-between">
        <span className="self-center">Adventurer Id:</span>

        <input
          type="number"
          name="name"
          onChange={handleInputChange}
          className="p-1 m-2 bg-terminal-black border border-slate-500"
          maxLength={31}
        />
      </label>
      <Button
        onClick={() => {
          handleSlayAdventurer();
          clickPlay();
        }}
      >
        Kill
      </Button>
    </div>
  );
}
