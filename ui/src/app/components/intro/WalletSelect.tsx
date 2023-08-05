import { useState, useEffect } from "react";
import { Button } from "../buttons/Button";
import { useConnectors, useAccount } from "@starknet-react/core";
import useUIStore from "../../hooks/useUIStore";
import Image from "next/image";
import { WalletTutorial } from "../tutorial/WalletTutorial";

interface WalletSelectProps {}

const WalletSelect = ({}: WalletSelectProps) => {
  const { connectors, connect } = useConnectors();
  const { account } = useAccount();
  const [screen, setScreen] = useState("wallet");
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

    if (account) {
      setConnected(true);
    }
  }, [account, setConnected]);

  if (!connectors) return <div></div>;

  const arcadeConnectors = () =>
    connectors.filter(
      (connector) =>
        typeof connector.id === "string" && connector.id.includes("0x")
    );
  const walletConnectors = () =>
    connectors.filter(
      (connector) =>
        typeof connector.id !== "string" || !connector.id.includes("0x")
    );

  return (
    <div className="flex flex-col p-8">
      <div className="flex flex-col self-center my-auto">
        {screen === "wallet" ? (
          <>
            <div className="w-full">
              <Image
                className=" mx-auto p-10 animate-pulse"
                src={"/monsters/balrog.png"}
                alt="start"
                width={200}
                height={200}
              />
            </div>
            <div className="w-full text-center">
              <h3 className="mb-10">Time to Survive</h3>
            </div>

            <div className="flex flex-col gap-5 m-auto">
              <Button onClick={() => setScreen("tutorial")}>
                I don&apos;t have a wallet
              </Button>
              {walletConnectors().map((connector, index) => (
                <Button
                  onClick={() => connect(connector)}
                  key={index}
                  className="w-full"
                >
                  {connector.id === "braavos" || connector.id === "argentX"
                    ? `Connect ${connector.id}`
                    : "Login With Email"}
                </Button>
              ))}
              {arcadeConnectors().length ? (
                <>
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
                </>
              ) : (
                ""
              )}
            </div>
          </>
        ) : (
          <>
            <WalletTutorial />
            <div className="flex justify-center">
              <Button size={"sm"} onClick={() => setScreen("wallet")}>
                Back
              </Button>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default WalletSelect;
