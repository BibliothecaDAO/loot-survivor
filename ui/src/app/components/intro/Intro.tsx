import { useState, useEffect, useCallback } from "react";
import { Button } from "../buttons/Button";
import WalletSelect from "./WalletSelect";
import { TypeAnimation } from "react-type-animation";
import { prologue } from "../../lib/constants";
import LootIconLoader from "../icons/Loader";

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
    <>
      {!initiated ? (
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
      ) : (
        <>
          {screen == 0 ? (
            <div className="flex flex-col w-full h-full p-4 sm:p-8">
              <div className="flex">
                <p className="sm:p-4 text-xs sm:text-xl leading-tight">
                  <TypeAnimation
                    sequence={[
                      prologue,
                      () => {
                        setIntroComplete(true);
                      },
                    ]}
                    wrapper="span"
                    cursor={true}
                    speed={45}
                    // repeat={Infinity}
                    style={{ fontSize: "2em" }}
                  />
                </p>
              </div>
              <div>
                {!introComplete && (
                  <Button
                    onClick={() => setIntroComplete(true)}
                    variant={"outline"}
                  >
                    skip
                  </Button>
                )}
              </div>

              {introComplete && (
                <div className="flex flex-row gap-10 m-auto">
                  {/* <Button
                    onClick={() => setScreen(1)}
                    className={
                      "m-auto w-40" + (selectedIndex == 0 ? "animate-pulse" : "")
                    }
                    variant={selectedIndex == 0 ? "default" : "ghost"}
                  >
                    <p className="text-base whitespace-nowrap">LAUNCH ON DEVNET</p>
                  </Button> */}
                  <Button
                    onClick={() => setScreen(2)}
                    className={
                      "m-auto w-40" +
                      (selectedIndex == 1 ? "animate-pulse" : "")
                    }
                    variant={selectedIndex == 1 ? "default" : "ghost"}
                  >
                    <p className="text-base whitespace-nowrap">
                      LAUNCH ON GOERLI
                    </p>
                  </Button>
                </div>
              )}
            </div>
          ) : (
            <WalletSelect screen={screen} />
          )}
        </>
      )}
    </>
  );
};

export default Intro;
