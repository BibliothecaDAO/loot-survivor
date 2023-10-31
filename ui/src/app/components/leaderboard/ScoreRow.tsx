import Lords from "public/icons/lords.svg";
import { useUiSounds, soundSelector } from "@/app/hooks/useUiSound";
import { formatNumber, calculateLevel } from "@/app/lib/utils";
import { Adventurer } from "@/app/types";

interface ScoreLeaderboardRowProps {
  adventurer: Adventurer;
  rank: number;
  handleRowSelected: (id: number) => void;
}

const ScoreRow = ({
  adventurer,
  rank,
  handleRowSelected,
}: ScoreLeaderboardRowProps) => {
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  return (
    <tr
      className="text-center border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black cursor-pointer xl:h-2 xl:text-lg 2xl:text-xl 2xl:h-10"
      onClick={() => {
        handleRowSelected(adventurer.id ?? 0);
        clickPlay();
      }}
    >
      <td>{rank}</td>
      <td>{`${adventurer.name} - ${adventurer.id}`}</td>
      <td>{calculateLevel(adventurer.xp ?? 0)}</td>
      <td>{adventurer.xp}</td>
      <td>
        {((adventurer.totalPayout as number) ?? 0) > 0 ? (
          <span className="flex flex-row gap-1 items-center justify-center">
            <Lords className="h-4 w-4 sm:w-5 sm:h-5 fill-current" />
            {formatNumber(adventurer.totalPayout as number)}
          </span>
        ) : (
          "-"
        )}
      </td>
    </tr>
  );
};

export default ScoreRow;
