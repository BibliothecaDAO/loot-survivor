import { useState, useEffect } from "react";
import { Button } from "./Button";
import WalletSelect from "./WalletSelect";
import { TypeAnimation } from "react-type-animation";
import { prologue } from "../lib/constants";

const Intro = () => {
  const [screen, setScreen] = useState(0);
  const [selectedIndex, setSelectedIndex] = useState<number>(0);

  const [introComplete, setIntroComplete] = useState<boolean>(false);

  const handleKeyDown = (event: KeyboardEvent) => {
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
  };
  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIndex]);

  return (
    <>
      {screen == 0 ? (
        <div className="flex flex-col w-full h-full p-8">
          <div className="flex">
            <p className="p-4 text-xl leading-tight">
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
              <Button
                onClick={() => setScreen(1)}
                className={
                  "m-auto w-40" + (selectedIndex == 0 ? "animate-pulse" : "")
                }
                variant={selectedIndex == 0 ? "default" : "ghost"}
              >
                <p className="text-base whitespace-nowrap">LAUNCH ON DEVNET</p>
              </Button>
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
          )}
        </div>
      ) : (
        <WalletSelect screen={screen} />
      )}
    </>
  );
};

export default Intro;
