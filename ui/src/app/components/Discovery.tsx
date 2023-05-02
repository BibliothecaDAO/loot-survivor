import { NullAdventurer } from "../types";
import { DiscoveryDisplay } from "./DiscoveryDisplay";
import useAdventurerStore from "../hooks/useAdventurerStore";

interface DiscoveryProps {
  discoveries: any[];
}

const Discovery = ({ discoveries }: DiscoveryProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const formatAdventurer = adventurer ? adventurer.adventurer : NullAdventurer;

  return (
    <div className="flex flex-col items-center gap-5 m-auto text-xl">
      {discoveries.length > 0 ? (
        <>
          <h3 className="text-center">Your travels</h3>
          <div className="flex flex-col items-center gap-2">
            {discoveries.map((discovery: any, index: number) => (
              <div key={index}>
                <DiscoveryDisplay discoveryData={discovery} />
              </div>
            ))}
          </div>
        </>
      ) : (
        <p>You have not yet made any discoveries!</p>
      )}
    </div>
  );
};

export default Discovery;
