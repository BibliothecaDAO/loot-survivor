import { useState, ChangeEvent } from "react";
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
import { ETH_INCREMENT } from "../lib/constants";

interface TopUpDialogProps {
  ethContract: Contract;
  getEthBalance: () => Promise<void>;
  ethBalance: number;
}

export const TopUpDialog = ({
  ethContract,
  getEthBalance,
  ethBalance,
}: TopUpDialogProps) => {
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
  const [inputValue, setInputValue] = useState(0);

  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { value } = e.target;
    setInputValue(parseInt(value));
  };

  const handleIncrement = () => {
    const newInputValue = inputValue + ETH_INCREMENT;
    if (newInputValue >= 0) {
      setInputValue(newInputValue);
    }
  };

  const handleDecrement = () => {
    const newInputValue = inputValue - ETH_INCREMENT;
    if (newInputValue >= 0) {
      setInputValue(newInputValue);
    }
  };

  const arcadeConnectors = getArcadeConnectors(connectors);
  const walletConnectors = getWalletConnectors(connectors);

  let storage: BurnerStorage = Storage.get("burners") || {};
  const masterConnected = address === storage[topUpAccount]?.masterAccount;

  const arcadeConnector = arcadeConnectors.find(
    (connector) => connector.name === topUpAccount
  );

  const onMainnet = process.env.NEXT_PUBLIC_NETWORK === "mainnet";

  const notEnoughDefaultBalance = ethBalance < 0.01 * 10 ** 18;
  const notEnoughCustomBalance = ethBalance < inputValue * 10 ** 18;

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
            Top Up (0.01ETH)
          </p>
          <Button
            disabled={!masterConnected || isToppingUpEth}
            onClick={async () => {
              if (!notEnoughDefaultBalance) {
                await topUpEth(topUpAccount, walletAccount!);
                await getEthBalance();
                setTopUpAccount("");
                disconnect();
                connect({ connector: arcadeConnector! });
                showTopUpDialog(false);
              } else {
                onMainnet
                  ? window.open("https://starkgate.starknet.io//", "_blank")
                  : window.open("https://faucet.goerli.starknet.io/", "_blank");
              }
            }}
          >
            {masterConnected
              ? notEnoughDefaultBalance
                ? "Get ETH"
                : "Top Up"
              : "Connect Master"}
          </Button>
          <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
            Top Up Custom Amount
          </p>
          <div className="flex flex-row items-center justify-center gap-1">
            <input
              type="number"
              min={0}
              value={inputValue}
              onChange={handleChange}
              className="p-1 w-12 bg-terminal-black border border-terminal-green"
              onWheel={(e) => e.preventDefault()} // Disable mouse wheel for the input
              disabled={!masterConnected}
            />
            <div className="flex flex-col">
              <Button
                size="xxxs"
                className="text-black"
                onClick={handleIncrement}
                disabled={!masterConnected}
              >
                +
              </Button>
              <Button
                size="xxxs"
                className="text-black"
                onClick={handleDecrement}
                disabled={!masterConnected}
              >
                -
              </Button>
            </div>
          </div>
          <Button
            disabled={!masterConnected || isToppingUpEth}
            onClick={async () => {
              if (!notEnoughCustomBalance) {
                await topUpEth(topUpAccount, walletAccount!, inputValue);
                await getEthBalance();
                setTopUpAccount("");
                disconnect();
                connect({ connector: arcadeConnector! });
                showTopUpDialog(false);
              } else {
                onMainnet
                  ? window.open("https://starkgate.starknet.io//", "_blank")
                  : window.open("https://faucet.goerli.starknet.io/", "_blank");
              }
            }}
          >
            {masterConnected
              ? notEnoughCustomBalance
                ? "Get ETH"
                : "Top Up"
              : "Connect Master"}
          </Button>
          <Button onClick={() => showTopUpDialog(false)}>Close</Button>
        </div>
        {isToppingUpEth && <TokenLoader isToppingUpEth={isToppingUpEth} />}
      </div>
    </>
  );
};
