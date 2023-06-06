import Info from "./Info";
import { useQueriesStore } from "../hooks/useQueryStore";
import { Button } from "./Button";
import useUIStore from "../hooks/useUIStore";
import useCustomQuery from "../hooks/useCustomQuery";
import {
  getAdventurerById,
  getDiscoveries,
  getBattlesByAdventurer,
  getBeastsByAdventurer,
} from "../hooks/graphql/queries";
import { useEffect, useState } from "react";
import { DiscoveryDisplay } from "./DiscoveryDisplay";
import { BattleDisplay } from "./BattleDisplay";
import { NullBeast } from "../types";
import { processBeastName } from "../lib/utils";
import { Encounters } from "./Encounters";

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

  return (
    <div className="w-full m-auto">
      <div className="flex flex-row gap-10 items-start justify-center">
        <Button
          className="animate-pulse"
          onClick={() => setScreen("leaderboard")}
        >
          Back
        </Button>
        <div className="w-1/3 ml-4">
          <Info adventurer={adventurer} profileExists={true} />
        </div>
        <Encounters profile={profile} />
      </div>
    </div>
  );
}
