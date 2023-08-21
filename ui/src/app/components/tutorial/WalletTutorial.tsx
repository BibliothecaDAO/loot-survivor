import { useState } from "react";
import { Button } from "../buttons/Button";

export const WalletTutorial = () => {
  const openInNewTab = (url: string) => {
    const newWindow = window.open(url, "_blank", "noopener,noreferrer");
    if (newWindow) newWindow.opener = null;
  };

  return (
    <div className="flex flex-col h-[550px] sm:h-full items-center text-center p-10 overflow-y-auto">
      <h2 className="mt-0">Welcome to Loot Survivor!</h2>

      <p className="text-sm sm:text-lg">
        To get started and immerse yourself in this on-chain gaming adventure,
        you will need to create a Starknet wallet first. Don&apos;t worry, it is
        a simple process!
        <br /> Your wallet will serve as your key to the world of Loot Survivor,
        allowing you to interact with the game fully on the blockchain.
        It&apos;s like your digital pocket for storing the in-game assets,
        rewards, and more!
      </p>
      <h3>Choose a Wallet Provider</h3>
      <p className="text-sm sm:text-lg">
        The following wallets are available for use with the Loot Survivor.
      </p>
      <div className="flex flex-row my-2">
        <Button
          onClick={() => openInNewTab("https://braavos.app/")}
          className="m-2"
        >
          Get Braavos
        </Button>
        <Button
          onClick={() => openInNewTab("https://www.argent.xyz/argent-x/")}
          className="m-2"
        >
          Get ArgentX
        </Button>
      </div>
      <p className="text-sm sm:text-lg">
        After you have created your wallet you will need testnet ETH to play.
        Request testnet ETH from the faucet. Your address can be found in your
        wallet.
      </p>
      <Button
        onClick={() => openInNewTab("https://faucet.goerli.starknet.io/")}
        className="m-2"
      >
        Get testnet ETH
      </Button>

      <h3>Switch to the Goerli Network</h3>
      <p className="text-sm sm:text-lg">
        In your wallet switch the network to Goerli. Goerli is a testnet that is
        currently under development. It is a version of the mainnet that is used
        for testing purposes.
      </p>
      <p className="text-sm sm:text-lg">
        Now, you are ready to spawn your adventurer! Connect your wallet to
        start!
      </p>
    </div>
  );
};
