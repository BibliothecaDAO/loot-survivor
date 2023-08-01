import React, { FC } from "react";
import { useState, useEffect } from "react";
import { Button } from "../buttons/Button";
import { useConnectors, useAccount } from "@starknet-react/core";
import useUIStore from "../../hooks/useUIStore";
import Image from "next/image";
import { TutorialDialog } from "../tutorial/TutorialDialog";
import { WalletTutorial } from "../tutorial/WalletTutorial";
import { disconnect } from "process";

interface WalletSelectProps {
  onClose: () => void;
}

const WalletSelect: FC<WalletSelectProps> = ({ onClose }) => {
  const { connectors, connect } = useConnectors();
  const { account } = useAccount();
  const [screen, setScreen] = useState("wallet");

  console.log(account);
  const setConnected = useUIStore((state) => state.setConnected);

  useEffect(() => {
    if (
      (account as any)?.baseUrl ==
        "https://survivor-indexer.bibliothecadao.xyz" ||
      (account as any)?.provider?.baseUrl ==
        "https://survivor-indexer.bibliothecadao.xyz"
    ) {
      setConnected(true);
    }
  }, [account, setConnected]);

  return (
    <div className="flex flex-col p-8">
      <div className="flex flex-col self-center my-auto">
        {account && <button onClick={onClose}>BACK</button>}
        {screen === "wallet" ? (
          <>
            <div className="w-full">
              <Image
                className="mx-auto p-10 animate-pulse"
                src={"/monsters/balrog.png"}
                alt="start"
                width={500}
                height={500}
              />
            </div>

            <div className="w-full text-center">
              <h1 className="mb-10">The Hour for Survival Has Arrived</h1>
            </div>
            <div className="flex flex-col w-1/2 gap-5 m-auto">
              <Button onClick={() => setScreen("tutorial")}>
                I don&apos;t have a wallet
              </Button>
              {connectors.length > 0 &&
                connectors.map((connector, index) => (
                  <Button
                    onClick={() => connect(connector)}
                    key={index}
                    className="w-full"
                  >
                    Connect {connector.id}
                  </Button>
                ))}
            </div>
          </>
        ) : (
          <>
            <div>
              <WalletTutorial />
              <Button onClick={() => setScreen("wallet")}>Back</Button>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default WalletSelect;
