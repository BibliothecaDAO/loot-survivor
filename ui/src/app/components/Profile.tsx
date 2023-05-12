import Info from "./Info";
import { useQueriesStore } from "../hooks/useQueryStore";
import { Button } from "./Button";
import useUIStore from "../hooks/useUIStore";

export default function Profile() {
  const { data } = useQueriesStore();
  const adventurer = data.leaderboardByIdQuery.adventurers[0];
  const setScreen = useUIStore((state) => state.setScreen);
  return (
    <div className="flex">
      <div className="w-1/3 m-auto flex flex-row">
        <Button
          className="animate-pulse"
          onClick={() => setScreen("leaderboard")}
        >
          Back
        </Button>
        <Info adventurer={adventurer} />
      </div>
    </div>
  );
}
