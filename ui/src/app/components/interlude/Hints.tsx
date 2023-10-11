import { useEffect, useState } from "react";
import { ActionsTutorial } from "../tutorial/ActionsTutorial";
import { AdventurerTutorial } from "../tutorial/AdventurerTutorial";
import { BeastTutorial } from "../tutorial/BeastTutorial";
import { UpgradeTutorial } from "../tutorial/UpgradeTutorial";
import RowLoader from "../animations/RowLoadre";

export default function Hints() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const tutorials = [
    <ActionsTutorial key={0} />,
    <AdventurerTutorial key={1} />,
    <BeastTutorial key={2} />,
    <UpgradeTutorial key={3} />,
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
    <div className="flex flex-col w-1/2 items-center justify-center h-full">
      <p className="text-4xl h-1/6 flex justify-center items-center">Hints</p>
      <div className="flex flex-col border border-terminal-green bg-black p-12 h-5/6 w-3/4">
        <div className="w-full h-1/6">
          <RowLoader />
        </div>
        <div className="w-full h-5/6">{tutorials[currentIndex]}</div>
      </div>
    </div>
  );
}
