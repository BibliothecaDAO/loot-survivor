import Info from "../components/adventurer/Info";
import { useQueriesStore } from "../hooks/useQueryStore";
import { Button } from "../components/buttons/Button";
import useUIStore from "../hooks/useUIStore";
import useCustomQuery from "../hooks/useCustomQuery";
import { getAdventurerById } from "../hooks/graphql/queries";
import { useState } from "react";
import EncountersScreen from "./EncountersScreen";
import { useMediaQuery } from "react-responsive";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";

export default function Profile() {
  const { data } = useQueriesStore();
  const profile = useUIStore((state) => state.profile);
  const [encounters, setEncounters] = useState(false);
  useCustomQuery(
    "leaderboardByIdQuery",
    getAdventurerById,
    {
      id: profile ?? 0,
    },
    false
  );
  const adventurer = data.leaderboardByIdQuery?.adventurers[0];

  const setScreen = useUIStore((state) => state.setScreen);

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  return (
    <div className="w-full">
      <div className="flex flex-col sm:flex-row gap-5 sm:gap-10 items-center sm:items-start justify-center">
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
          <div className="w-full sm:w-1/3 ml-4">
            <Info adventurer={adventurer} profileExists={true} />
          </div>
        ) : (
          <EncountersScreen profile={profile} />
        )}
        {!isMobileDevice && <EncountersScreen profile={profile} />}
      </div>
    </div>
  );
}
