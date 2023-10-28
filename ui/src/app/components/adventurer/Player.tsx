import { Contract } from "starknet";
import Info from "@/app/components/adventurer/Info";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";

interface PlayerProps {
  gameContract: Contract;
}

export default function Player({ gameContract }: PlayerProps) {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  return (
    <>
      {adventurer?.id ? (
        <Info adventurer={adventurer} gameContract={gameContract} />
      ) : (
        <div className="flex items-center justify-center">
          <p>Please select an adventurer!</p>
        </div>
      )}
    </>
  );
}
