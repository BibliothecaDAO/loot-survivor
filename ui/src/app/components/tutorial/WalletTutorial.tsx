import { useState } from "react";
import { Button } from "../buttons/Button";

export const WalletTutorial = () => {
  const openInNewTab = (url: string) => {
    const newWindow = window.open(url, "_blank", "noopener,noreferrer");
    if (newWindow) newWindow.opener = null;
  };

  return (
    <div className="flex flex-col items-center">
      <h3 className="mt-0">Welcome to Loot Survivor!</h3>

      {/* <h3 className="text-xl sm:text-2xl">Create an Adventurer</h3> */}
      <p className="text-sm sm:text-lg text-center">
        To play you will need a Starknet wallet. You can create one by choosing
        a provider below and switching the network to Goerli. <br /> To spawn
        your adventurer, you will first need to connect your wallet.
      </p>
      <Button
        onClick={() => openInNewTab("https://braavos.app/")}
        className="mb-1"
      >
        Get Braavos
      </Button>
      <Button onClick={() => openInNewTab("https://www.argent.xyz/argent-x/")}>
        Get ArgentX
      </Button>
    </div>
  );
};
