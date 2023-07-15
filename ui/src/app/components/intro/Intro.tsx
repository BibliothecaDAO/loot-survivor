import { useState, useEffect, useCallback } from "react";
import { Button } from "../buttons/Button";
import WalletSelect from "./WalletSelect";
import { TypeAnimation } from "react-type-animation";
import { prologue, chapter1 } from "../../lib/constants";
import LootIconLoader from "../icons/Loader";
import Image from "next/image";

const Intro = () => {
  const [screen, setScreen] = useState(0);
  const [selectedIndex, setSelectedIndex] = useState<number>(0);

  const [initiated, setInitiated] = useState<boolean>(false);

  const [introComplete, setIntroComplete] = useState<boolean>(false);

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
    /* {!initiated ? (
        <div className="flex flex-wrap justify-center p-20 w-fill">
          <LootIconLoader size="w-8" />
          <div className="flex justify-center w-full mt-10">
            <Button
              className="animate-pulse"
              onMouseEnter={handleMouseEnter}
              onMouseLeave={handleMouseLeave}
              onClick={() => setInitiated(true)}
            >
              {buttonText}{" "}
            </Button>
          </div>
        </div>
      ) : ( */
    <>
      {screen == 0 ? (
        <div className="flex flex-col w-full h-full p-4 sm:p-8">
          <div className="flex flex-col">
            <div className="sm:p-4 text-xs sm:text-xl leading-loose">
              <TypeAnimation
                sequence={[
                  prologue,
                  () => {
                    setScreen(1);
                  },
                ]}
                wrapper="span"
                cursor={true}
                speed={40}
                style={{ fontSize: "2em" }}
              />
            </div>
            <div className="w-full ">
              <Image
                className="mx-auto animate-pulse border border-terminal-green"
                src={"/scenes/scene2.png"}
                alt="start"
                width={425}
                height={425}
              />
            </div>
          </div>
          {/* <div>
            <Button onClick={() => setScreen(1)} variant={"default"}>
              skip
            </Button>
          </div> */}
        </div>
      ) : screen == 1 ? (
        <div className="flex flex-col w-full h-full p-4 sm:p-8">
          <div className="flex flex-col">
            <div className="w-full">
              <div className="p-2 sm:p-4 text-xs sm:text-xl leading-loose">
                <TypeAnimation
                  key={screen.toString()}
                  sequence={[
                    chapter1,
                    () => {
                      setScreen(2);
                    },
                  ]}
                  wrapper="span"
                  cursor={true}
                  speed={40}
                  style={{ fontSize: "2em" }}
                />
              </div>
              <div className="w-full pb-5">
                <Image
                  className="mx-auto animate-pulse border border-terminal-green"
                  src={"/scenes/scene1.png"}
                  alt="second screen"
                  width={450}
                  height={450}
                />
              </div>
            </div>

            {/* <div>
              <Button onClick={() => setScreen(2)} variant={"default"}>
                skip
              </Button>
            </div> */}
          </div>
          <div className="flex flex-row gap-10 m-auto">
            <Button
              onClick={() => setScreen(2)}
              className={
                "m-auto w-40" + (selectedIndex == 1 ? "animate-pulse" : "")
              }
              variant={selectedIndex == 1 ? "default" : "ghost"}
            >
              <p className="text-base whitespace-nowrap">LAUNCH ON GOERLI</p>
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
