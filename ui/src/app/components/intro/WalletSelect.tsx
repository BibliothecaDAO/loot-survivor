import { useState } from "react";
import Image from "next/image";
import { Button } from "@/app/components/buttons/Button";
import { useConnect } from "@starknet-react/core";
import { WalletTutorial } from "@/app/components/intro/WalletTutorial";
import Storage from "@/app/lib/storage";
import { BurnerStorage } from "@/app/types";
import { getArcadeConnectors, getWalletConnectors } from "@/app/lib/connectors";
import useUIStore from "@/app/hooks/useUIStore";
import { networkConfig } from "@/app/lib/networkConfig";

interface WalletSelectProps {}

const WalletSelect = ({}: WalletSelectProps) => {
  const { connectors, connect } = useConnect();
  const network = useUIStore((state) => state.network);
  const [screen, setScreen] = useState("wallet");

  if (!connectors) return <div></div>;

  const arcadeConnectors = getArcadeConnectors(connectors);
  const walletConnectors = getWalletConnectors(connectors);

  const storage: BurnerStorage = Storage.get("burners");

  return (
    <div className="min-h-screen container flex justify-center items-center m-auto p-4 pt-8 sm:w-1/2 sm:p-8 lg:p-10 2xl:p-20">
      <div className="flex flex-col justify-center h-full">
        {screen === "wallet" ? (
          <>
            <div className="fixed inset-y-0 left-0 z-[-1]">
              <Image
                className="mx-auto p-10 animate-pulse object-cover "
                src={"/monsters/balrog.png"}
                alt="start"
                width={500}
                height={500}
              />
            </div>
            <div className="w-full text-center">
              <h3 className="mb-10">Time to Survive</h3>
            </div>

            <div className="flex flex-col gap-2 m-auto items-center justify-center overflow-y-auto">
              <div className="flex flex-col gap-2 w-full">
                {walletConnectors.map((connector, index) => (
                  <Button
                    onClick={() => connect({ connector })}
                    key={index}
                    className="w-full"
                  >
                    {connector.id === "braavos" || connector.id === "argentX"
                      ? `Connect ${connector.id}`
                      : connector.id === "argentWebWallet"
                      ? "Login With Email"
                      : "Login with Cartridge Controller"}
                  </Button>
                ))}
              </div>
              {arcadeConnectors.length ? (
                <>
                  <h5 className="text-center">Arcade Accounts</h5>
                  <div className="flex flex-col sm:flex-row gap-2 overflow-auto h-[300px] sm:h-full w-full sm:w-[400px]">
                    {arcadeConnectors.map((connector, index) => {
                      const currentGamePermissions =
                        storage[connector.name].gameContract ==
                        networkConfig[network!].gameAddress;
                      return (
                        <Button
                          onClick={() => connect({ connector })}
                          key={index}
                          className="w-full"
                          disabled={!currentGamePermissions}
                        >
                          Connect {connector.id}
                        </Button>
                      );
                    })}
                  </div>
                </>
              ) : (
                ""
              )}
              <div className="hidden sm:block fixed inset-y-0 right-0 z-[-1]">
                <Image
                  className="mx-auto p-10 animate-pulse object-cover "
                  src={"/monsters/dragon.png"}
                  alt="start"
                  width={500}
                  height={500}
                />
              </div>
            </div>
          </>
        ) : (
          <div className="flex flex-col gap-5">
            <WalletTutorial />
            <div className="flex flex-row gap-5 justify-center">
              <Button size={"sm"} onClick={() => setScreen("wallet")}>
                Back
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default WalletSelect;
