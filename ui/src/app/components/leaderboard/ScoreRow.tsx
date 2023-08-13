import { Adventurer, NullAdventurer } from "@/app/types";
import Lords from "../../../../public/lords.svg";
import { useUiSounds, soundSelector } from "@/app/hooks/useUiSound";

interface ScoreLeaderboardRowProps {
  index: number;
  adventurer: Adventurer;
  handleRowSelected: (id: number) => void;
}

const ScoreRow = ({
  index,
  adventurer,
  handleRowSelected,
}: ScoreLeaderboardRowProps) => {
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  return (
    <tr
      className="text-center border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black cursor-pointer"
      onClick={() => {
        handleRowSelected(adventurer.id ?? 0);
        clickPlay();
      }}
    >
      <td>{index + 1}</td>
      <td>{`${adventurer.name} - ${adventurer.id}`}</td>
      <td>{adventurer.xp}</td>
      <td>
        <div className="flex flex-row items-center justify-center gap-2">
          <span
            className={` ${
              index == 0
                ? "text-gold"
                : index == 1
                ? "text-silver"
                : index == 2
                ? "text-bronze"
                : ""
            }`}
          >
            {index == 0 ? 10 : index == 1 ? 3 : index == 2 ? 2 : ""}
          </span>

          <Lords className="self-center w-6 h-6 ml-4 fill-current" />
        </div>
      </td>
    </tr>
  );
};

export default ScoreRow;
