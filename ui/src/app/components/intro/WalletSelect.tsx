import { useEffect } from "react";
import { Button } from "../buttons/Button";
import { useConnectors, useAccount } from "@starknet-react/core";
import useUIStore from "../../hooks/useUIStore";
import Image from "next/image";

interface WalletSelectProps {
  screen: number;
}

const WalletSelect = ({ screen }: WalletSelectProps) => {
  const { connectors, connect } = useConnectors();
  const { account } = useAccount();
  const setConnected = useUIStore((state) => state.setConnected);

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

    if (screen == 4 && account) {
      setConnected(true);
    }
  }, [account, screen, setConnected]);

  console.log(connectors);

  const arcadeConnectors = () =>
    connectors.filter((connector) => connector.id.includes("0x"));
  const walletConnectors = () =>
    connectors.filter((connector) => !connector.id.includes("0x"));

  return (
    <div className="flex flex-col p-8">
      <div className="flex flex-col self-center my-auto">
        <div className="w-full">
          <Image
            className=" mx-auto p-10 animate-pulse"
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
          {walletConnectors().map((connector, index) => (
            <Button
              onClick={() => connect(connector)}
              key={index}
              className="w-full"
            >
              Connect {connector.id}
            </Button>
          ))}
          <h5 className="text-center">Arcade Accounts</h5>
          {arcadeConnectors().map((connector, index) => (
            <Button
              onClick={() => connect(connector)}
              key={index}
              className="w-full"
            >
              Connect {connector.id}
            </Button>
          ))}
        </div>
      </div>
    </div>
  );
};

export default WalletSelect;
