import { useState, useEffect, useCallback } from "react";
import { Button } from "../buttons/Button";
import WalletSelect from "./WalletSelect";
import { TypeAnimation } from "react-type-animation";
import { prologue, chapter1, chapter2, chapter3 } from "../../lib/constants";
import LootIconLoader from "../icons/Loader";
import Image from "next/image";

const Intro = () => {
  const [screen, setScreen] = useState(0);
  const [selectedIndex, setSelectedIndex] = useState<number>(0);

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

  const [buttonText, setButtonText] = useState("do you dare?");

  const handleMouseEnter = () => {
    setButtonText("are you sure?");
  };

  const handleMouseLeave = () => {
    setButtonText("do you dare?");
  };

  return (
    <>
      {screen == 0 ? (
        <div className="flex flex-col w-full h-full">
          <div className="flex flex-col h-full">
            <Image
              className="mx-auto border border-terminal-green absolute object-fill "
              src={"/scenes/scene2.png"}
              alt="start"
              fill
            />
            <div className="sm:p-4 text-xs sm:text-xl leading-loose z-10 mt-auto">
              <TypeAnimation
                sequence={[
                  prologue,
                  () => {
                    setTimeout(() => {
                      setScreen(1);
                    }, 2000);
                  },
                ]}
                wrapper="span"
                cursor={true}
                speed={40}
                style={{ fontSize: "2em" }}
              />
            </div>
          </div>
          <div className="flex flex-row gap-10 m-auto">
            <div className="flex justify-center w-full mt-10">
              <Button
                className="animate-pulse"
                onMouseEnter={handleMouseEnter}
                onMouseLeave={handleMouseLeave}
                onClick={() => setScreen(4)}
              >
                {buttonText}{" "}
              </Button>
            </div>
          </div>
        </div>
      ) : screen == 1 ? (
        <div className="flex flex-col w-full h-full">
          <div className="flex flex-col">
            <Image
              className="mx-auto border border-terminal-green absolute object-fill "
              src={"/scenes/scene1.png"}
              alt="second screen"
              fill
            />

            <div className="p-2 sm:p-4 text-xs sm:text-xl leading-loose z-10">
              <TypeAnimation
                key={screen.toString()}
                sequence={[
                  chapter1,
                  () => {
                    setTimeout(() => {
                      setScreen(2);
                    }, 3000);
                  },
                ]}
                wrapper="span"
                cursor={true}
                speed={40}
                style={{ fontSize: "2em" }}
              />
            </div>
          </div>
          <div className="flex flex-row gap-10 m-auto">
            <Button
              className="animate-pulse"
              onMouseEnter={handleMouseEnter}
              onMouseLeave={handleMouseLeave}
              onClick={() => setScreen(4)}
            >
              {buttonText}{" "}
            </Button>
          </div>
        </div>
      ) : screen == 2 ? (
        <div className="flex flex-col w-full h-full">
          <div className="flex flex-col">
            <Image
              className="mx-auto border border-terminal-green absolute object-fill"
              src={"/scenes/cave.png"}
              alt="cave"
              fill
            />

            <div className="p-2 sm:p-4 text-xs sm:text-xl leading-loose z-10">
              <TypeAnimation
                key={screen.toString()}
                sequence={[
                  chapter2,
                  () => {
                    setTimeout(() => {
                      setScreen(3);
                    }, 3000);
                  },
                ]}
                wrapper="span"
                cursor={true}
                speed={40}
                style={{ fontSize: "2em" }}
              />
            </div>
          </div>
          <div className="flex flex-row gap-10 m-auto">
            <Button
              className="animate-pulse"
              onMouseEnter={handleMouseEnter}
              onMouseLeave={handleMouseLeave}
              onClick={() => setScreen(4)}
            >
              {buttonText}{" "}
            </Button>
          </div>
        </div>
      ) : screen == 3 ? (
        <div className="flex flex-col w-full h-full">
          <div className="flex flex-col">
            <Image
              className="mx-auto border border-terminal-green absolute object-fill"
              src={"/scenes/fountain.png"}
              alt="fountain"
              fill
            />

            <div className="p-2 sm:p-4 text-xs sm:text-xl leading-loose z-10">
              <TypeAnimation
                key={screen.toString()}
                sequence={[
                  chapter3,
                  () => {
                    setTimeout(() => {
                      setScreen(4);
                    }, 3000);
                  },
                ]}
                wrapper="span"
                cursor={true}
                speed={40}
                style={{ fontSize: "2em" }}
              />
            </div>
          </div>
          <div className="flex flex-row gap-10 m-auto">
            <Button
              className="animate-pulse"
              onMouseEnter={handleMouseEnter}
              onMouseLeave={handleMouseLeave}
              onClick={() => setScreen(4)}
            >
              {buttonText}{" "}
            </Button>
          </div>
        </div>
      ) : (
        <WalletSelect screen={screen} />
      )}
    </>
  );
};

export default Intro;
