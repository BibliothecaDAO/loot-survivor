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
          <Button
            onClick={() => setScreen(1)}
            className=" m-auto w-32 animate-pulse"
          >
            ENTER
          </Button>
          <div className="w-full h-6 my-2 bg-terminal-green" />
        </div>
      ) : (
        <WalletSelect />
      )}
    </>
  );
};

export default Intro;
