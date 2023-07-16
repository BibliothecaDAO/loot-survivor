import { useState } from "react";
import { Button } from "../buttons/Button";

export default function KillAdventurer() {
  const [adventurerTarget, setAdventurerTarget] = useState("");

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setAdventurerTarget(event.target.value);
  };
  return (
    <div className="flex flex-col">
      <h4>Kill Idle Adventurer</h4>
      <label className="flex justify-between">
        <span className="self-center">Adventurer Id:</span>

        <input
          type="number"
          name="name"
          onChange={handleInputChange}
          className="p-1 m-2 bg-terminal-black border border-slate-500"
          maxLength={31}
        />
      </label>
      <Button onClick={() => null}>Kill</Button>
    </div>
  );
}
