import { Button } from "@/app/components/buttons/Button";
import { CompleteIcon } from "@/app/components/icons/Icons";
import { displayAddress, padAddress } from "@/app/lib/utils";
import { getWalletConnectors } from "@/app/lib/connectors";
import { useConnect, useDisconnect } from "@starknet-react/core";
import useNetworkAccount from "@/app/hooks/useNetworkAccount";

interface WalletSectionProps {
  step: number;
}

const WalletSection = ({ step }: WalletSectionProps) => {
  const { address } = useNetworkAccount();
  const { connectors, connect } = useConnect();
  const { disconnect } = useDisconnect();
  const walletConnectors = getWalletConnectors(connectors);

  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
    } catch (err) {
      console.error("Failed to copy text: ", err);
    }
  };

  return (
    <>
      {step !== 1 && (
        <>
          <div className="absolute top-0 left-0 right-0 bottom-0 h-full w-full bg-black opacity-50 z-10" />
          {step > 1 && (
            <div className="absolute flex flex-col w-1/2 top-1/4 right-1/4 z-20 items-center text-xl text-center">
              <span className="flex gap-5 items-center">
                <p>{displayAddress(address!)}</p>
                <Button onClick={() => copyToClipboard(padAddress(address!))}>
                  Copy
                </Button>
              </span>
              <CompleteIcon />
            </div>
          )}
        </>
      )}
      <div className="flex flex-col items-center justify-between border border-terminal-green p-5 text-center gap-10 z-1 h-[400px] sm:h-[425px] 2xl:h-[500px]">
        <h4 className="m-0 uppercase text-3xl">Connect Starknet Wallet</h4>
        <p className="sm:hidden 2xl:block text-xl">
          In order to play LOOT SURVIVOR you are required to connect a Starknet
          wallet.
        </p>
        <div className="hidden sm:flex flex-col">
          {walletConnectors.map((connector, index) => (
            <Button
              disabled={address !== undefined}
              onClick={() => {
                disconnect();
                connect({ connector });
              }}
              key={index}
            >
              {connector.id === "braavos" || connector.id === "argentX"
                ? `Connect ${connector.id}`
                : connector.id === "argentWebWallet"
                ? "Login With Email"
                : "Login with Cartridge Controller"}
            </Button>
          ))}
        </div>
        <div className="sm:hidden flex flex-col gap-2">
          {walletConnectors.map((connector, index) => (
            <Button
              size={"lg"}
              disabled={address !== undefined}
              onClick={() => {
                disconnect();
                connect({ connector });
              }}
              key={index}
            >
              {connector.id === "braavos" || connector.id === "argentX"
                ? `Connect ${connector.id}`
                : connector.id === "argentWebWallet"
                ? "Login With Email"
                : "Login with Cartridge Controller"}
            </Button>
          ))}
        </div>
      </div>
    </>
  );
};

export default WalletSection;
