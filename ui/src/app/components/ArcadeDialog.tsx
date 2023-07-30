import useUIStore from "@/app/hooks/useUIStore";
import { Button } from "./buttons/Button";
import { useBurner } from "../lib/burner";
import { useAccount, useConnectors } from "@starknet-react/core";
import { ArcadeConnector } from "../lib/arcade";
import { useCallback } from "react";

export const ArcadeDialog = () => {
  const { address, account } = useAccount();
  const showArcadeDialog = useUIStore((state) => state.showArcadeDialog);
  const arcadeDialog = useUIStore((state) => state.arcadeDialog);
  const { connect } = useConnectors();
  const { create, get, list, isDeploying } = useBurner()

  const arcadeAccounts = useCallback(() => {
    const arcadeAccounts = [];
    const burners = list();

    for (const burner of burners) {
      const arcadeConnector = new ArcadeConnector({
        options: {
          id: burner.address,
        }
      }, get(burner.address));

      arcadeAccounts.push(arcadeConnector);
    }

    return arcadeAccounts;
  }, [account, isDeploying]);

  const onConnect = useCallback((account: ArcadeConnector) => {
    console.log(account)
    connect(account)
  }, [isDeploying]);

  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed text-center top-1/8 left-1/8 sm:left-1/4 w-3/4 sm:w-1/2 h-3/4 border  bg-terminal-black z-50 border-terminal-green">

        <Button onClick={() => showArcadeDialog(!arcadeDialog)}>close</Button>

        <h3 className="mt-8">Arcade Account</h3>

        <p className="text-2xl pb-8">Create an Arcade Account here to allow for signature free gameplay!</p>

        {((account?.signer as any)?.pk == '0x0') && (
          <div>
            <Button onClick={() => create()}>
              create arcade account
            </Button>
            <p className="my-2 text-terminal-yellow">Note: This will initiate a 0.01 ETH transaction to the new account.</p>
          </div>
        )}

        <hr className="my-4 border-terminal-green" />

        <h5>Existing</h5>

        <div className="flex gap-2 flex-col w-48 p-4 mx-auto">
          {arcadeAccounts().map((account, index) => {
            const connected = address == account.name;
            return <Button variant={connected ? 'default' : 'outline'} key={index} onClick={() => onConnect(account)}>
              {connected ? 'connected' : 'connect'}  {account.id}
            </Button>
          })}
        </div>
        {isDeploying && (<p>Deploying...</p>)}
      </div>
    </>
  );
};
