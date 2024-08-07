import { Adventurer } from "@/app/types";
import { useUiSounds, soundSelector } from "@/app/hooks/useUiSound";
import { CoinIcon } from "@/app/components/icons/Icons";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { calculateLevel } from "@/app/lib/utils";

interface LiveLeaderboardRowProps {
  adventurer: Adventurer;
  handleRowSelected: (id: number) => void;
}

const LiveLeaderboardRow = ({
  adventurer,
  handleRowSelected,
}: LiveLeaderboardRowProps) => {
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  const adventurersByOwner = useQueriesStore(
    (state) => state.data.adventurersByOwnerQuery?.adventurers ?? []
  );

  const ownedAdventurer = adventurersByOwner.some(
    (a) => a.id === adventurer.id
  );

  const topScores = [...adventurersByOwner].sort(
    (a, b) => (b.xp ?? 0) - (a.xp ?? 0)
  );
  const topScoreAdventurer = topScores[0]?.id === adventurer.id;

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
    </tr>
  );
};

export default LiveLeaderboardRow;
