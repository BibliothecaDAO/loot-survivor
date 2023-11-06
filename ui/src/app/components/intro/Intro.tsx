import { useState, useEffect, useCallback } from "react";
import { TypeAnimation } from "react-type-animation";
import Image from "next/image";
import { Button } from "@/app/components/buttons/Button";
import { prologue, chapter1, chapter2, chapter3 } from "@/app/lib/constants";

interface IntroProps {
  onIntroComplete: () => void;
}

const Intro: React.FC<IntroProps> = ({ onIntroComplete }) => {
  const [screen, setScreen] = useState(0);
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const [flash, setFlash] = useState(false);

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

  useEffect(() => {
    setFlash(true);
    const timer = setTimeout(() => {
      setFlash(false);
    }, 500);
    return () => clearTimeout(timer);
  }, [screen]);

  const renderScreen = (src: string, alt: string, sequence: any) => (
    <div className="flex w-full h-full p-2">
      <Image
        className="absolute object-cover animate-pulse"
        src={src}
        alt={alt}
        fill
        priority
      />

      <div className="w-full z-10 pt-20">
        <div className="text-xs sm:text-xl leading-normal sm:leading-loose z-10">
          <TypeAnimation
            key={screen.toString()}
            sequence={sequence}
            wrapper="span"
            cursor={true}
            speed={40}
            style={{ fontSize: "2em" }}
          />
        </div>

        <div className="flex  mt-10">
          <Button
            className="animate-pulse"
            size={"sm"}
            variant={"outline"}
            onClick={() => setScreen(4)}
          >
            [skip]
          </Button>
        </div>
      </div>
    </div>
  );

  return (
    <>
      {flash && screen != 0 && <div className="flash" />}
      {screen == 0 &&
        renderScreen("/scenes/intro/incave.png", "start", [
          prologue,
          () => setTimeout(() => setScreen(1), 3000),
        ])}
      {screen == 1 &&
        renderScreen("/scenes/intro/cave.png", "cave", [
          chapter1,
          () => setTimeout(() => setScreen(2), 3000),
        ])}
      {screen == 2 &&
        renderScreen("/scenes/intro/fountain.png", "skulls", [
          chapter2,
          () => setTimeout(() => setScreen(3), 3000),
        ])}
      {screen == 3 &&
        renderScreen("/scenes/intro/fountain.png", "fountain", [
          chapter3,
          () => setTimeout(() => setScreen(4), 3000),
        ])}
    </>
  );
};

export default Intro;
