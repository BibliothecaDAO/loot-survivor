import { useState, useEffect, useCallback } from "react";
import { Button } from "../buttons/Button";
import WalletSelect from "./WalletSelect";
import { TypeAnimation } from "react-type-animation";
import { prologue, chapter1, chapter2, chapter3 } from "../../lib/constants";
import Image from "next/image";

interface IntroProps {
  onIntroComplete: () => void;
}

const Intro: React.FC<IntroProps> = ({ onIntroComplete }) => {
  const [screen, setScreen] = useState(0);
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const [buttonText, setButtonText] = useState("do you dare?");

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      switch (event.key) {
        case "ArrowRight":
          setSelectedIndex((prev) => {
            const newIndex = Math.min(prev + 1, 1);
            return newIndex;
          });
          break;
        case "ArrowLeft":
          setSelectedIndex((prev) => {
            const newIndex = Math.max(prev - 1, 0);
            return newIndex;
          });
          break;
        case "Enter":
          setScreen(selectedIndex + 1);
          break;
      }
    },
    [selectedIndex]
  );

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIndex, handleKeyDown]);

  useEffect(() => {
    if (screen === 4) {
      onIntroComplete();
    }
  }, [screen, onIntroComplete]);

  const handleMouseEnter = () => {
    setButtonText("are you sure?");
  };

  const handleMouseLeave = () => {
    setButtonText("do you dare?");
  };

  const [flash, setFlash] = useState(false);

  useEffect(() => {
    setFlash(true);
    const timer = setTimeout(() => {
      setFlash(false);
    }, 500); // 500ms corresponds to the animation duration
    return () => clearTimeout(timer); // clean up on unmount or when the screen changes
  }, [screen]);

  const renderScreen = (src: string, alt: string, sequence: any) => (
    <div className="flex flex-col w-full h-full justify-between">
      <div className="flex flex-col h-full">
        <Image
          className="mx-auto border border-terminal-green absolute object-cover"
          src={src}
          alt={alt}
          fill
        />

        <div className="p-2 pt-20 text-xs sm:text-xl leading-loose z-10">
          <TypeAnimation
            key={screen.toString()}
            sequence={sequence}
            wrapper="span"
            cursor={true}
            speed={40}
            style={{ fontSize: "2em" }}
          />
        </div>
      </div>
      <div className="flex flex-row gap-10 mt-auto">
        <Button
          className="animate-pulse"
          onMouseEnter={handleMouseEnter}
          onMouseLeave={handleMouseLeave}
          onClick={() => setScreen(4)}
        >
          [skip]
        </Button>
      </div>
    </div>
  );

  return (
    <>
      {flash && <div className="flash" />}
      {screen == 0 &&
        renderScreen("/scenes/scene2.png", "start", [
          prologue,
          () => setTimeout(() => setScreen(1), 2000),
        ])}
      {screen == 1 &&
        renderScreen("/scenes/scene1.png", "second screen", [
          chapter1,
          () => setTimeout(() => setScreen(2), 3000),
        ])}
      {screen == 2 &&
        renderScreen("/scenes/cave.png", "cave", [
          chapter2,
          () => setTimeout(() => setScreen(3), 3000),
        ])}
      {screen == 3 &&
        renderScreen("/scenes/fountain.png", "fountain", [
          chapter3,
          () => setTimeout(() => setScreen(4), 3000),
        ])}
    </>
  );
};

export default Intro;
