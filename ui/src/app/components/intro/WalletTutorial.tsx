import { Button } from "@/app/components/buttons/Button";

export const WalletTutorial = () => {
  const openInNewTab = (url: string) => {
    const newWindow = window.open(url, "_blank", "noopener,noreferrer");
    if (newWindow) newWindow.opener = null;
  };

  return (
    <div className="flex flex-col h-[550px] sm:h-full items-center text-center p-10 overflow-y-auto">
      <h2 className="mt-0">Welcome to Loot Survivor!</h2>

      {/* <p className="text-sm sm:text-lg">
        To get started and immerse yourself in this on-chain gaming adventure,
        you will need to create a Starknet wallet first. Don&apos;t worry, it is
        a simple process!
        <br /> Your wallet will serve as your key to the world of Loot Survivor,
        allowing you to interact with the game fully on the blockchain.
        It&apos;s like your digital pocket for storing the in-game assets,
        rewards, and more!
      </p> */}
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
    </div>
  );
};
