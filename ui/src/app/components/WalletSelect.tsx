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

  useEffect(() => {
    if (screen == 1) {
      if (
        (account as any)?.provider?.baseUrl == "http://3.215.42.99:5050" ||
        (account as any)?.baseUrl == "http://3.215.42.99:5050"
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
          {connectors.map((connector) => (
            <Button
              onClick={() => connect(connector)}
              key={connector.id()}
              className="w-full"
            >
              Connect {connector.id()}
            </Button>
          ))}
        </div>
      ) : (
        <div className="flex flex-col gap-5 m-auto w-1/2">
          {connectors.map((connector) => (
            <>
              {connector.id() == "argentX" ? (
                <Button
                  onClick={() => connect(connector)}
                  key={connector.id()}
                  className="w-full"
                >
                  Connect {connector.id()}
                </Button>
              ) : null}
              {/* {connector.id() == "braavos" ? (
                <Button
                  onClick={() => connect(connector)}
                  key={connector.id()}
                  className="w-full"
                >
                  Connect {connector.id()}
                </Button>
              ) : null} */}
            </>
          ))}
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
