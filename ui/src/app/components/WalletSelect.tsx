import { useState, useEffect } from "react";
import { Button } from "./Button";
import { useConnectors, useAccount } from "@starknet-react/core";
import {
  AddDevnetButton,
  SwitchToDevnetButton,
} from "../components/DevnetConnectors";
import useUIStore from "../hooks/useUIStore";

interface WalletSelectProps {
  screen: number;
}

const WalletSelect = ({ screen }: WalletSelectProps) => {
  const { connectors, connect } = useConnectors();
  const { account } = useAccount();
  const [addedDevnet, setAddedDevnet] = useState<boolean>(false);
  const setConnected = useUIStore((state) => state.setConnected);
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
        (account as any)?.baseUrl ==
          "https://survivor-indexer.bibliothecadao.xyz" ||
        (account as any)?.provider?.baseUrl ==
          "https://survivor-indexer.bibliothecadao.xyz"
      ) {
        setConnected(true);
      }
    }

    if (screen == 2) {
      if (
        (account as any)?.baseUrl == "https://alpha4.starknet.io" ||
        (account as any)?.provider?.baseUrl == "https://alpha4.starknet.io"
      ) {
        setConnected(true);
      }
    }
  }, [account, screen]);

  return (
    <div className="flex flex-col p-8">
      <div className="flex flex-col self-center my-auto">
        <h1 className="mb-10">It&apos;s Time to Survive </h1>
        {screen == 2 ? (
          <div className="flex flex-col w-1/2 gap-5 m-auto">
            {connectors.length > 0 ? (
              connectors.map((connector, index) => (
                <Button
                  onClick={() => connect(connector)}
                  key={index}
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
          <div className="flex flex-col w-1/2 gap-5 m-auto">
            {connectors.some(
              (connector: any) => connector.id() == "argentX"
            ) ? (
              connectors.map((connector, index) => (
                <>
                  {connector.id() == "argentX" ? (
                    <Button
                      onClick={() => connect(connector)}
                      key={index}
                      className="w-full"
                      disabled={account ? true : false}
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
      </div>
    </div>
  );
};

export default WalletSelect;
