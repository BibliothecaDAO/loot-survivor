import { useEffect, useState } from "react";
import { ItemsTutorial } from "../tutorial/ItemsTutorial";
import { UpgradeTutorial } from "../tutorial/UpgradeTutorial";
import { EfficacyHint } from "../tutorial/ElementalTutorial";
import { UnlocksTutorial } from "../tutorial/ItemSpecialsTutorial";
import { ExploreTutorial } from "../tutorial/ExploreTutorial";
import { StrategyTutorial } from "../tutorial/StrategyTutorial";
import RowLoader from "../animations/RowLoader";

export default function Hints() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const tutorials = [
    <EfficacyHint key={0} />,
    <ItemsTutorial key={1} />,
    <UnlocksTutorial key={2} />,
    <UpgradeTutorial key={3} />,
    <ExploreTutorial key={4} />,
    <StrategyTutorial key={5} />,
  ];
  useEffect(() => {
    if (currentIndex < tutorials.length - 1) {
      const timer = setTimeout(() => {
        setCurrentIndex((prev) => prev + 1);
      }, 10000);
      return () => {
        clearTimeout(timer);
      };
    } else if (currentIndex === tutorials.length - 1) {
      const timer = setTimeout(() => {
        setCurrentIndex(0);
      }, 10000);
      return () => clearTimeout(timer);
    }
  }, [currentIndex]);

  return (
    <div className="flex flex-col sm:w-1/2 items-center justify-center h-full">
      <p className="text-4xl h-1/6 flex justify-center items-center">Hints</p>
      <div className="flex flex-col border border-terminal-green bg-black px-2 py-5 sm:p-6 2xl:px-12 2xl:py-6 h-5/6 w-full sm:w-3/4 gap-5">
        <div className="w-full h-1/8 2xl:h-1/6">
          <RowLoader />
        </div>
        <div className="w-full h-5/6">{tutorials[currentIndex]}</div>
      </div>
    </div>
  );
}
