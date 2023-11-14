import { Contract } from "starknet";
import { Adventurer } from "@/app/types";
import { useUiSounds, soundSelector } from "@/app/hooks/useUiSound";
import { CoinIcon, SkullIcon } from "@/app/components/icons/Icons";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { Button } from "@/app/components/buttons/Button";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import useUIStore from "@/app/hooks/useUIStore";
import { calculateLevel } from "@/app/lib/utils";

interface LiveLeaderboardRowProps {
  adventurer: Adventurer;
  handleRowSelected: (id: number) => void;
  gameContract: Contract;
  gameEntropyUpdateTime: number;
  currentBlock: number;
  idleAdventurers?: string[];
}

const LiveLeaderboardRow = ({
  adventurer,
  handleRowSelected,
  gameContract,
  gameEntropyUpdateTime,
  currentBlock,
  idleAdventurers,
}: LiveLeaderboardRowProps) => {
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );
  const adventurersByOwner = useQueriesStore(
    (state) => state.data.adventurersByOwnerQuery?.adventurers ?? []
  );
  const slayAdventurers = useUIStore((state) => state.slayAdventurers);
  const setSlayAdventurers = useUIStore((state) => state.setSlayAdventurers);

  const ownedAdventurer = adventurersByOwner.some(
    (a) => a.id === adventurer.id
  );

  const topScores = [...adventurersByOwner].sort(
    (a, b) => (b.xp ?? 0) - (a.xp ?? 0)
  );
  const topScoreAdventurer = topScores[0]?.id === adventurer.id;
  const handleSlayAdventurer = async () => {
    removeEntrypointFromCalls("slay_idle_adventurers");
    setSlayAdventurers([...slayAdventurers, adventurer?.id?.toString() ?? "0"]);
    const formattedSlayedAdventurers = [
      ...slayAdventurers,
      adventurer?.id?.toString() ?? "0",
    ];
    const slayIdleAdventurerTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "slay_idle_adventurers",
      calldata: [
        formattedSlayedAdventurers.length.toString(),
        ...formattedSlayedAdventurers,
      ],
      metadata: `Slaying ${adventurer.name}`,
    };
    if (gameContract) {
      addToCalls(slayIdleAdventurerTx);
    }
  };

  return (
    <tr
      className={`text-center border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black cursor-pointer xl:h-2 xl:text-lg 2xl:text-xl 2xl:h-10 ${
        topScoreAdventurer
          ? "bg-terminal-yellow-50"
          : ownedAdventurer
          ? "bg-terminal-green-50"
          : ""
      }`}
      onClick={() => {
        handleRowSelected(adventurer.id ?? 0);
        clickPlay();
      }}
    >
      <td>{`${adventurer.name} - ${adventurer.id}`}</td>
      <td>{calculateLevel(adventurer.xp ?? 0)}</td>
      <td>
        <span className="flex justify-center">{adventurer.xp}</span>
      </td>
      <td>
        <span className="flex justify-center text-terminal-yellow">
          <CoinIcon className="self-center w-4 h-4 sm:w-6 sm:h-6 fill-current" />
          {adventurer.gold ? adventurer.gold : 0}
        </span>
      </td>
      <td>
        <span className="flex justify-center">{adventurer.health}</span>
      </td>
      <td>
        {" "}
        <Button
          onClick={(e) => {
            e.stopPropagation();
            handleSlayAdventurer();
            clickPlay();
          }}
          className="xl:h-2 2xl:h-full"
          disabled={
            slayAdventurers.includes(adventurer?.id?.toString() ?? "0") ||
            adventurer?.health === 0 ||
            !adventurer?.id ||
            !(idleAdventurers ?? []).includes(adventurer?.id.toString())
          }
        >
          <SkullIcon className="w-3" />
        </Button>
      </td>
    </tr>
  );
};

export default LiveLeaderboardRow;
