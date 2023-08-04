import useUIStore from "@/app/hooks/useUIStore";
import { Button } from "./buttons/Button";
import { useBurner } from "../lib/burner";
import { useAccount, useConnectors } from "@starknet-react/core";
import { useEffect } from "react";

export const ArcadeDialog = () => {
  const { account, address, connector } = useAccount();
  const showArcadeDialog = useUIStore((state) => state.showArcadeDialog);
  const arcadeDialog = useUIStore((state) => state.arcadeDialog);
  const { connect, connectors, refresh } = useConnectors();
  const { create, isDeploying } = useBurner()


  if (!connectors) return <div></div>;

  const arcadeConnectors = () => connectors.filter((connector) => connector.id.includes("0x"));

  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed text-center top-1/8 left-1/8 sm:left-1/4 w-3/4 sm:w-1/2 h-3/4 border  bg-terminal-black z-50 border-terminal-green">

        <Button onClick={() => showArcadeDialog(!arcadeDialog)}>close</Button>

        <h3 className="mt-8">Arcade Account</h3>

        <p className="text-2xl pb-8">Create an Arcade Account here to allow for signature free gameplay!</p>

        <div className="flex justify-center">
          {((connector?.options as any)?.id == "argentX" || (connector?.options as any)?.id == "braavos") && (
            <div>
              <Button onClick={() => create()}>
                create arcade account
              </Button>
              <p className="my-2 text-terminal-yellow p-2 border border-terminal-yellow">Note: This will initiate a 0.01 ETH transaction to the new account. Your page will reload after the Account has been created!</p>

            </div>
          )}
        </div>


        <hr className="my-4 border-terminal-green" />

        <h5>Existing</h5>

        <div className="flex gap-2 flex-col w-48 p-4 mx-auto">
          {arcadeConnectors().map((account, index) => {
            const connected = address == account.name;
            return <Button variant={connected ? 'default' : 'outline'} key={index} onClick={() => connect(account)}>
              {connected ? 'connected' : 'connect'}  {account.id}
            </Button>
          })}
        </div>
        {isDeploying && (<p>Deploying...</p>)}
      </div>
    </>
  );
};
