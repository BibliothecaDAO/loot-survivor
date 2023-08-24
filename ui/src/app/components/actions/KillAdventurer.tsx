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
import { useBlock } from "@starknet-react/core";
import { NullAdventurer } from "@/app/types";
import LootIconLoader from "../icons/Loader";

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
  const { data, isLoading } = useQueriesStore();

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setAdventurerTarget(event.target.value);
  };

  const slayIdleAdventurerTx = {
    contractAddress: gameContract?.address ?? "",
    entrypoint: "slay_idle_adventurer",
    calldata: [adventurerTarget, "0"],
    metadata: `Slaying ${adventurerTarget}`,
  };

  const handleSlayAdventurer = async () => {
    addToCalls(slayIdleAdventurerTx);
  };

  useCustomQuery("adventurerToSlayQuery", getAdventurerById, {
    id: parseInt(adventurerTarget),
  });

  const slayAdventurer = data.adventurerToSlayQuery
    ? data.adventurerToSlayQuery.adventurers[0]
    : NullAdventurer;

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
        <h4 className="text-lg sm:text-2xl text-center">
          Slay Idle Adventurer
        </h4>
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
        disabled={
          idleTime < IDLE_DEATH_PENALTY_BLOCKS ||
          slayAdventurer?.health === 0 ||
          !slayAdventurer?.id
        }
      >
        {slayAdventurer?.health === 0
          ? "Adventurer is dead!"
          : idleTime < IDLE_DEATH_PENALTY_BLOCKS
          ? "Adventurer hasn't reached penalty time!"
          : !slayAdventurer?.id
          ? "Adventurer not found!"
          : "Slay"}
      </Button>
      {isLoading.adventurerToSlayQuery ? (
        <LootIconLoader />
      ) : (
        <TopInfo adventurer={slayAdventurer} />
      )}
    </div>
  );
}
