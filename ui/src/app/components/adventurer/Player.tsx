import Info from "@/app/components/adventurer/Info";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";

export default function Player() {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  return (
    <>
      {adventurer?.id ? (
        <Info adventurer={adventurer} />
      ) : (
        <div className="flex items-center justify-center">
          <p>Please select an adventurer!</p>
        </div>
      )}
    </>
  );
}
