import { useState, useEffect } from "react";
import { Button } from "./Button";
import { useConnectors, useAccount } from "@starknet-react/core";
import {
  AddDevnetButton,
  SwitchToDevnetButton,
} from "../components/DevnetConnectors";
import { useUI } from "../context/UIProvider";

interface WalletSelectProps {
  screen: number;
}

const WalletSelect = ({ screen }: WalletSelectProps) => {
  const { connectors, connect } = useConnectors();
  const { account } = useAccount();
  const [addedDevnet, setAddedDevnet] = useState<boolean>(false);
  const { setOnboarded } = useUI();
  const [selectedIndex, setSelectedIndex] = useState<number>(0);

  // const handleKeyDown = (event: KeyboardEvent) => {
  //   switch (event.key) {
  //     case "ArrowDown":
  //       setSelectedIndex((prev) => {
  //         const newIndex = Math.min(prev + 1, 1);
  //         return newIndex;
  //       });
  //       break;
  //     case "ArrowUp":
  //       setSelectedIndex((prev) => {
  //         const newIndex = Math.max(prev - 1, 0);
  //         return newIndex;
  //       });
  //       break;
  //     case "Enter":
  //       if (screen == 1) {
  //         setScreen(selectedIndex + 1);
  //       }
  //       break;
  //   }
  // };
  // useEffect(() => {
  //   window.addEventListener("keydown", handleKeyDown);
  //   return () => {
  //     window.removeEventListener("keydown", handleKeyDown);
  //   };
  // }, [selectedIndex]);

  useEffect(() => {
    if (screen == 1) {
      if (
        (account as any)?.provider?.baseUrl == "https://3.215.42.99:5050" ||
        (account as any)?.baseUrl == "https://3.215.42.99:5050"
      ) {
        setOnboarded(true);
      }
    }

    if (screen == 2) {
      if ((account as any)?.baseUrl == "https://alpha4.starknet.io") {
        setOnboarded(true);
      }
    }
  }, [account]);

  console.log(account);

  return (
    <div className="flex flex-col p-8 h-screen max-h-screen">
      <div className="w-full h-6 my-2 bg-terminal-green" />
      <div className="flex flex-col">
        <h1>ABOUT</h1>
        <div className="flex text-xl">
          <p className="p-4">
            Welcome, brave traveler! Prepare to embark on an extraordinary
            journey through the mystic lands of Eldarath, a high fantasy realm
            where Dragons, Ogres, Skeletons, and Phoenixes roam free, vying for
            supremacy amidst the remnants of a fallen empire. As a lone
            survivor, you are destined to traverse this beguiling world,
            battling fearsome beasts, unearthing lost relics, and uncovering
            secrets hidden within the mists of time.
          </p>
        </div>
      </div>
      {screen == 2 ? (
        <div className="flex flex-col gap-5 m-auto w-1/2">
          {connectors.length > 0 ? (
            connectors.map((connector) => (
              <Button
                onClick={() => connect(connector)}
                key={connector.id()}
                className="w-full"
              >
                Connect {connector.id()}
              </Button>
            ))
          ) : (
            <h1>You must have Argent or Braavos installed!</h1>
          )}
        </div>
      ) : (
        <div className="flex flex-col gap-5 m-auto w-1/2">
          {connectors.some((connector: any) => connector.id() == "argentX") ? (
            connectors.map((connector) => (
              <>
                {connector.id() == "argentX" ? (
                  <Button
                    onClick={() => connect(connector)}
                    key={connector.id()}
                    className="w-full"
                    disabled={typeof account !== undefined}
                  >
                    Connect {connector.id()}
                  </Button>
                ) : null}
              </>
            ))
          ) : (
            <h1>To use devnet you must have an Argent wallet!</h1>
          )}
          <AddDevnetButton
            // isDisabled={!account?.address}
            isDisabled={addedDevnet}
            setAddDevnet={setAddedDevnet}
          />
          <SwitchToDevnetButton isDisabled={false} />
        </div>
      )}
      <div className="w-full h-6 my-2 bg-terminal-green" />
    </div>
  );
};

export default WalletSelect;
