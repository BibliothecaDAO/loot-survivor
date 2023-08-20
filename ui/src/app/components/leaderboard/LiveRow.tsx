import { Adventurer } from "@/app/types";
import { useUiSounds, soundSelector } from "@/app/hooks/useUiSound";
import { CoinIcon, DeathSkullIcon } from "../icons/Icons";
import { useContracts } from "@/app/hooks/useContracts";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { Button } from "../buttons/Button";
import { useBlock } from "@starknet-react/core";
import { idleDeathPenaltyBlocks } from "@/app/lib/constants";

interface LiveLeaderboardRowProps {
  index: number;
  adventurer: Adventurer;
  rank: number;
  handleRowSelected: (id: number) => void;
}

const LiveLeaderboardRow = ({
  index,
  adventurer,
  rank,
  handleRowSelected,
}: LiveLeaderboardRowProps) => {
  const { gameContract } = useContracts();
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const { data: blockData } = useBlock({
    refetchInterval: false,
    blockIdentifier: "latest",
  });
  const dead = (adventurer.health ?? 0) <= 0;

  const slayIdleAdventurerTx = {
    contractAddress: gameContract?.address ?? "",
    entrypoint: "slay_idle_adventurer",
    calldata: [adventurer.id ?? 0, "0"],
    metadata: `Slaying ${adventurer.name}`,
  };

  const handleSlayAdventurer = async () => {
    addToCalls(slayIdleAdventurerTx);
  };

  const formatLastActionBlock = (adventurer?.lastAction ?? 0) % 512;
  const formatCurrentBlock = (blockData?.block_number ?? 0) % 512;

  const idleTime =
    formatCurrentBlock >= formatLastActionBlock
      ? formatCurrentBlock - formatLastActionBlock
      : 512 - formatLastActionBlock + formatCurrentBlock;

  return (
    <tr
      className="text-center border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black cursor-pointer xl:h-2 xl:text-lg 2xl:text-xl 2xl:h-4"
      onClick={() => {
        handleRowSelected(adventurer.id ?? 0);
        clickPlay();
      }}
    >
      <td>{rank}</td>
      <td>{`${adventurer.name} - ${adventurer.id}`}</td>
      <td>
        <span className="flex justify-center text-terminal-yellow">
          <CoinIcon className="self-center w-4 h-4 sm:w-6 sm:h-6 fill-current" />
          {adventurer.gold ? adventurer.gold : 0}
        </span>
      </td>
      <td>
        <span className="flex justify-center">{adventurer.xp}</span>
      </td>
      <td>
        <span
          className={`flex justify-center ${
            !dead ? " text-terminal-green" : "text-red-800"
          }`}
        >
          {adventurer.health}
        </span>
      </td>
      <td>
        {" "}
        <Button
          onClick={(e) => {
            e.stopPropagation();
            handleSlayAdventurer();
            clickPlay();
          }}
          className="xl:h-2 2xl:h-4"
          disabled={
            idleTime < idleDeathPenaltyBlocks ||
            adventurer?.health === 0 ||
            !adventurer?.id
          }
        >
          <DeathSkullIcon />
        </Button>
      </td>
    </tr>
  );
};

export default LiveLeaderboardRow;
