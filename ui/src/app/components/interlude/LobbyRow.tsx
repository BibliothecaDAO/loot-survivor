import { Adventurer } from "@/app/types";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { useUiSounds } from "@/app/hooks/useUiSound";
import { soundSelector } from "@/app/hooks/useUiSound";

interface LobbyRowProps {
  adventurer: Adventurer;
  handleRowSelected: (id: number) => void;
  currentBlock: number;
}

const LobbyRow = ({
  adventurer,
  handleRowSelected,
  currentBlock,
}: LobbyRowProps) => {
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  const adventurersByOwner = useQueriesStore(
    (state) => state.data.adventurersByOwnerQuery?.adventurers ?? []
  );
  const ownedAdventurer = adventurersByOwner.some(
    (a) => a.id === adventurer.id
  );

  return (
    <tr
      className={`text-center border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black cursor-pointer xl:h-2 xl:text-lg 2xl:text-xl 2xl:h-10 ${
        ownedAdventurer ? "bg-terminal-green-50" : ""
      }`}
      onClick={() => {
        handleRowSelected(adventurer.id ?? 0);
        clickPlay();
      }}
    >
      <td>{`${adventurer.name} - ${adventurer.id}`}</td>
      <td>{adventurer.owner}</td>
      <td>10</td>
      <td>100 XP</td>
      <td>{adventurer?.revealBlock! - currentBlock}</td>
    </tr>
  );
};

export default LobbyRow;
