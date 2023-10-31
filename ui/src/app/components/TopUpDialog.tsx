import { useAccount } from "@starknet-react/core";
import { Contract } from "starknet";
import useUIStore from "@/app/hooks/useUIStore";
import { Button } from "@/app/components/buttons/Button";
import { useConnect, useDisconnect } from "@starknet-react/core";
import Storage from "@/app/lib/storage";
import { BurnerStorage } from "@/app/types";
import { useBurner } from "@/app/lib/burner";
import { getArcadeConnectors, getWalletConnectors } from "@/app/lib/connectors";
import TokenLoader from "@/app/components/animations/TokenLoader";

interface TopUpDialogProps {
  ethContract: Contract;
  getBalances: () => void;
}

export const TopUpDialog = ({ ethContract, getBalances }: TopUpDialogProps) => {
  const { account: walletAccount, address } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const showTopUpDialog = useUIStore((state) => state.showTopUpDialog);
  const topUpAccount = useUIStore((state) => state.topUpAccount);
  const setTopUpAccount = useUIStore((state) => state.setTopUpAccount);
  const { topUpEth, isToppingUpEth } = useBurner({
    walletAccount,
    ethContract,
  });

  const arcadeConnectors = getArcadeConnectors(connectors);
  const walletConnectors = getWalletConnectors(connectors);

  let storage: BurnerStorage = Storage.get("burners") || {};
  const masterConnected = address === storage[topUpAccount]?.masterAccount;

  const arcadeConnector = arcadeConnectors.find(
    (connector) => connector.name === topUpAccount
  );

  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed text-center sm:top-1/8 sm:left-1/8 sm:left-1/4 sm:w-3/4 sm:w-1/2 h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4 overflow-y-auto">
        <h3 className="mt-4">Top Up Required</h3>
        <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
          You have run out of ETH to pay for gas in your Arcade Account, connect
          to the master account and top it up!
        </p>
        <div className="flex flex-col items-center gap-5">
          <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">Connect Master</p>
          {walletConnectors.map((connector, index) => (
            <Button
              disabled={masterConnected}
              onClick={() => {
                disconnect();
                connect({ connector });
              }}
              key={index}
            >
              {connector.id === "braavos" || connector.id === "argentX"
                ? `Connect ${connector.id}`
                : "Login With Email"}
            </Button>
          ))}
          <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
            Top Up (0.001ETH)
          </p>
          <Button
            disabled={!masterConnected || isToppingUpEth}
            onClick={async () => {
              await topUpEth(topUpAccount, walletAccount!);
              setTopUpAccount("");
              connect({ connector: arcadeConnector! });
              getBalances();
              showTopUpDialog(false);
            }}
          >
            {masterConnected ? "Top Up" : "Connect Master"}
          </Button>
          <Button onClick={() => showTopUpDialog(false)}>Close</Button>
        </div>
        {isToppingUpEth && <TokenLoader isToppingUpEth={isToppingUpEth} />}
      </div>
    </>
  );
};
