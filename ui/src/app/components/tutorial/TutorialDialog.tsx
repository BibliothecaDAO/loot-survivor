import { useState } from "react";
import useUIStore from "@/app/hooks/useUIStore";
import { AdventurerTutorial } from "./AdventurerTutorial";
import { ActionsTutorial } from "./ActionsTutorial";
import { BeastTutorial } from "./BeastTutorial";
import { FinalTutorial } from "./FinalTutorial";
import { Button } from "../buttons/Button";

export const TutorialDialog = () => {
  const screen = useUIStore((state) => state.screen);
  const showTutorialDialog = useUIStore((state) => state.showTutorialDialog);
  const [onFinal, setOnFinal] = useState(false);
  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed flex flex-col gap-5 items-center justify-between text-center p-5 top-1/8 left-1/8 sm:left-1/4 w-3/4 sm:w-1/2 h-3/4 rounded-lg border border-terminal-green bg-terminal-black z-50 overflow-y-auto">
        {screen == "start" && <AdventurerTutorial />}
        {screen == "play" && <ActionsTutorial />}
        {screen == "beast" && <BeastTutorial />}
        {screen == "upgrade" && <FinalTutorial onFinal={setOnFinal} />}
        <Button
          className="w-1/4"
          onClick={() => showTutorialDialog(false)}
          disabled={onFinal}
        >
          Continue
        </Button>
      </div>
    </>
  );
};
