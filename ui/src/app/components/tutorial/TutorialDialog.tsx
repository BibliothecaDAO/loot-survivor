import { useState } from "react";
import useUIStore from "@/app/hooks/useUIStore";
import { AdventurerTutorial } from "./AdventurerTutorial";
import { ActionsTutorial } from "./ActionsTutorial";
import { BeastTutorial } from "./BeastTutorial";
import { UpgradeTutorial } from "./UpgradeTutorial";
import { FinalTutorial } from "./FinalTutorial";
import { Button } from "../buttons/Button";

export const TutorialDialog = () => {
  const screen = useUIStore((state) => state.screen);
  const showTutorialDialog = useUIStore((state) => state.showTutorialDialog);

  const [tutorialStepIndex, setTutorialStepIndex] = useState(0);
  const tutorialSteps = ["start", "play", "beast", "upgrade", "final"];

  const onNextTutorial = () => {
    if (tutorialStepIndex < tutorialSteps.length - 1) {
      setTutorialStepIndex(tutorialStepIndex + 1);
    }
  };

  const onPreviousTutorial = () => {
    if (tutorialStepIndex > 0) {
      setTutorialStepIndex(tutorialStepIndex - 1);
    }
  };

  const tutorialStep = tutorialSteps[tutorialStepIndex];

  return (
    <>
      <div className="flex flex-col items-center justify-between text-center p-5  w-3/4 sm:w-1/2 border border-terminal-green bg-terminal-black z-50 overflow-y-auto">
        {tutorialStep == "start" && <AdventurerTutorial />}
        {tutorialStep == "play" && <ActionsTutorial />}
        {tutorialStep == "beast" && <BeastTutorial />}
        {tutorialStep == "upgrade" && <UpgradeTutorial />}
        {tutorialStep == "final" && <FinalTutorial />}
        <div className="flex flex-row gap-10 mt-2">
          <Button
            onClick={onPreviousTutorial}
            disabled={tutorialStepIndex === 0}
          >
            Previous
          </Button>
          <Button
            onClick={onNextTutorial}
            disabled={tutorialStepIndex === tutorialSteps.length - 1}
          >
            Next
          </Button>
        </div>
      </div>
    </>
  );
};
