import Info from "./Info";
import useAdventurerStore from "../../hooks/useAdventurerStore";

export default function Player() {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  return (
    <>
      {adventurer?.id ? (
        <div className="w-full">
          <Info adventurer={adventurer} />
        </div>
      ) : (
        <div className="flex items-center justify-center">
          <p>Please select an adventurer!</p>
        </div>
      )}
    </>
  );
}
