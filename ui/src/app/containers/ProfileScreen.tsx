import Info from "@/app/components/adventurer/Info";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { Button } from "@/app/components/buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";
import { useState } from "react";
import EncountersScreen from "@/app/containers/EncountersScreen";
import { NullAdventurer } from "@/app/types";

export default function Profile() {
  const { data } = useQueriesStore();
  const profile = useUIStore((state) => state.profile);
  const [encounters, setEncounters] = useState(false);

  const adventurer =
    data.leaderboardByIdQuery?.adventurers[0] ?? NullAdventurer;

  const setScreen = useUIStore((state) => state.setScreen);

  return (
    <div className="w-full">
      <div className="flex flex-col sm:flex-row gap-2 sm:gap-5 items-center sm:items-start justify-center">
        <Button
          className="animate-pulse hidden sm:block"
          onClick={() => setScreen("leaderboard")}
        >
          Back
        </Button>
        <Button
          className="animate-pulse sm:hidden"
          onClick={() => setEncounters(!encounters)}
        >
          {encounters ? "Player" : "Encounters"}
        </Button>
        {!encounters ? (
          <div className="w-full sm:w-1/3">
            <Info adventurer={adventurer} profileExists={true} />
          </div>
        ) : (
          <EncountersScreen profile={profile} />
        )}
        <div className="hidden sm:block w-2/3">
          <EncountersScreen profile={profile} />
        </div>
      </div>
    </div>
  );
}
