import { useState } from "react";
import { Button } from "./Button";
import WalletSelect from "./WalletSelect";

const Intro = () => {
  const [screen, setScreen] = useState(0);
  return (
    <>
      {screen == 0 ? (
        <div className="flex flex-col w-full p-8 h-screen max-h-screen">
          <div className="w-full h-6 my-2 bg-terminal-green" />
          <h1 className="m-auto text-[100px]">LOOT SURVIVOR</h1>
          <div className="flex flex-row gap-10 m-auto">
            <Button
              onClick={() => setScreen(1)}
              className=" m-auto w-40 animate-pulse"
            >
              <p className="text-base whitespace-nowrap">LAUNCH ON DEVNET</p>
            </Button>
            <Button
              onClick={() => setScreen(2)}
              className=" m-auto w-40 animate-pulse"
            >
              <p className="text-base whitespace-nowrap">LAUNCH ON GOERLI</p>
            </Button>
          </div>
          <div className="w-full h-6 my-2 bg-terminal-green" />
        </div>
      ) : (
        <WalletSelect screen={screen} />
      )}
    </>
  );
};

export default Intro;
