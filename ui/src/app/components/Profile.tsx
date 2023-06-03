import Info from "./Info";
import { useQueriesStore } from "../hooks/useQueryStore";
import { Button } from "./Button";
import useUIStore from "../hooks/useUIStore";
import useCustomQuery from "../hooks/useCustomQuery";
import { getAdventurerById } from "../hooks/graphql/queries";

export default function Profile() {
  const { data } = useQueriesStore();
  const profile = useUIStore((state) => state.profile);
  useCustomQuery(
    "leaderboardByIdQuery",
    getAdventurerById,
    {
      id: profile ?? 0,
    },
    undefined
  );
  const adventurer = data.leaderboardByIdQuery?.adventurers[0];
  const setScreen = useUIStore((state) => state.setScreen);
  return (
    <div className="w-1/2 m-auto">
      <div className="flex items-start">
        <Button
          className="animate-pulse"
          onClick={() => setScreen("leaderboard")}
        >
          Back
        </Button>
        <div className="w-full ml-4">
          <Info adventurer={adventurer} profileExists={true} />
        </div>
      </div>
    </div>
  );
}
