import { useState } from "react";
import { Button } from "../buttons/Button";
import { useContracts } from "@/app/hooks/useContracts";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { useUiSounds, soundSelector } from "../../hooks/useUiSound";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import { getAdventurerById } from "../../hooks/graphql/queries";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import TopInfo from "../adventurer/TopInfo";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { AdventurerTemplate } from "@/app/types/templates";
import { useBlock } from "@starknet-react/core";

export default function KillAdventurer() {
  const { gameContract } = useContracts();
  const [adventurerTarget, setAdventurerTarget] = useState("");
  const addToCalls = useTransactionCartStore((s) => s.addToCalls);
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const { data: blockData } = useBlock({
    refetchInterval: false,
    blockIdentifier: "latest",
  });

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
    "adventurerToSlayQuery",
    getAdventurerById,
    {
      id: adventurerTarget,
    },
    txAccepted
  );

  // const slayAdventurer = data.adventurerToSlayQuery
  //   ? data.adventurerToSlayQuery.adventurers[0]
  //   : NullAdventurer;

  const slayAdventurer = AdventurerTemplate;

  const formatLastActionBlock = (slayAdventurer?.lastAction ?? 0) % 512;
  const formatCurrentBlock = (blockData?.block_number ?? 0) % 512;

  const idleTime =
    formatCurrentBlock >= formatLastActionBlock
      ? formatCurrentBlock - formatLastActionBlock
      : 512 - formatLastActionBlock + formatCurrentBlock;

  const IDLE_DEATH_PENALTY_BLOCKS = 300;

  return (
    <div className="flex flex-col gap-5">
      <div>
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
      </div>
      <Button
        onClick={() => {
          handleSlayAdventurer();
          clickPlay();
        }}
        disabled={idleTime < 300 || slayAdventurer?.health === 0}
      >
        Kill
      </Button>
      <TopInfo adventurer={slayAdventurer} />
    </div>
  );
}
