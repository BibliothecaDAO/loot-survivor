import { useState } from "react";
import { MdClose } from "react-icons/md";
import useUIStore from "@/app/hooks/useUIStore";
import { Button } from "@/app/components/buttons/Button";
import { useDisconnect, useConnect } from "@starknet-react/core";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { NullAdventurer } from "@/app/types";
import useNetworkAccount from "@/app/hooks/useNetworkAccount";
import { displayAddress, padAddress, copyToClipboard } from "@/app/lib/utils";
import { AccountInterface } from "starknet";
import Eth from "public/icons/eth.svg";
import Lords from "public/icons/lords.svg";
import { CartridgeIcon } from "@/app/components/icons/Icons";
import { checkCartridgeConnector } from "@/app/lib/connectors";

interface ProfileDialogprops {
  withdraw: (
    adminAccountAddress: string,
    account: AccountInterface,
    ethBalance: bigint,
    lordsBalance: bigint
  ) => Promise<void>;
  ethBalance: bigint;
  lordsBalance: bigint;
  ethContractAddress: string;
  lordsContractAddress: string;
}

export const ProfileDialog = ({
  withdraw,
  ethBalance,
  lordsBalance,
  ethContractAddress,
  lordsContractAddress,
}: ProfileDialogprops) => {
  const { setShowProfile, setNetwork } = useUIStore();
  const { disconnect } = useDisconnect();
  const { setAdventurer } = useAdventurerStore();
  const resetData = useQueriesStore((state) => state.resetData);
  const { account, address } = useNetworkAccount();
  const [copied, setCopied] = useState(false);
  const [copiedEth, setCopiedEth] = useState(false);
  const [copiedLords, setCopiedLords] = useState(false);
  const username = useUIStore((state) => state.username);
  const controllerAdmin = useUIStore((state) => state.controllerAdmin);
  const handleOffboarded = useUIStore((state) => state.handleOffboarded);
  const { connector } = useConnect();

  const handleCopy = () => {
    copyToClipboard(padAddress(address!));
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleCopyLords = () => {
    copyToClipboard(lordsContractAddress);
    setCopiedLords(true);
    setTimeout(() => setCopiedLords(false), 2000);
  };

  const handleCopyEth = () => {
    copyToClipboard(ethContractAddress);
    setCopiedEth(true);
    setTimeout(() => setCopiedEth(false), 2000);
  };

  return (
    <div className="fixed w-full h-full sm:w-3/4 sm:h-3/4 top-0 sm:top-1/8 bg-terminal-black border border-terminal-green flex flex-col items-center p-10 z-30">
      <button
        className="absolute top-2 right-2 cursor-pointer text-terminal-green"
        onClick={() => {
          setShowProfile(false);
        }}
      >
        <MdClose size={50} />
      </button>
      <div className="flex flex-col items-center h-full gap-5">
        <div className="flex flex-col items-center">
          {checkCartridgeConnector(connector) && (
            <CartridgeIcon className="w-10 h-10 fill-current" />
          )}
          <h1 className="text-terminal-green text-4xl uppercase m-0">
            {checkCartridgeConnector(connector)
              ? username
              : displayAddress(address!)}
          </h1>
          {checkCartridgeConnector(connector) && (
            <h3 className="text-terminal-green text-2xl uppercase m-0">
              {displayAddress(address!)}
            </h3>
          )}
        </div>
        <div className="flex flex-col sm:flex-row items- justify-center gap-2">
          {checkCartridgeConnector(connector) && (
            <div className="flex flex-col items-center border border-terminal-green p-5 text-center sm:gap-10 z-1 h-[200px] sm:h-[400px] sm:w-1/3">
              <h2 className="text-terminal-green text-2xl sm:text-4xl uppercase m-0">
                Withdraw
              </h2>
              <p className="sm:text-lg">
                Withdraw to the Cartridge Controller admin account.
              </p>
              <p className="text-2xl uppercase">
                {displayAddress(controllerAdmin)}
              </p>
              <Button
                size={"lg"}
                onClick={() =>
                  withdraw(controllerAdmin, account!, ethBalance, lordsBalance)
                }
                disabled={controllerAdmin === "0x0"}
              >
                Withdraw
              </Button>
            </div>
          )}
          {checkCartridgeConnector(connector) && (
            <div className="flex flex-col items-center border border-terminal-green p-5 text-center sm:gap-5 z-1 sm:h-[400px] sm:w-1/3">
              <h2 className="text-terminal-green text-2xl sm:text-4xl uppercase m-0">
                Topup
              </h2>
              <div className="flex gap-2">
                <span className="text-2xl uppercase">
                  {displayAddress(address!)}
                </span>
                <div className="relative">
                  {copied && (
                    <span className="absolute top-[-20px] uppercase">
                      Copied!
                    </span>
                  )}
                  <Button onClick={handleCopy}>Copy</Button>
                </div>
              </div>
              <p className="hidden sm:block sm:text-lg">
                Low on tokens? Copy the address and above and transfer tokens
                from the wallet of your choice.
              </p>
              <div className="flex flex-col gap-2">
                <span className="flex flex-row items-center gap-2 relative">
                  <Lords className="self-center sm:w-8 sm:h-8  h-3 w-3 fill-current mr-1" />
                  <span className="uppercase">
                    {displayAddress(lordsContractAddress)}
                  </span>
                  <Button size={"xs"} onClick={handleCopyLords}>
                    Copy
                  </Button>
                  {copiedLords && (
                    <span className="absolute right-[-50px] uppercase">
                      Copied!
                    </span>
                  )}
                </span>
                <span className="flex flex-col relative">
                  <span className="flex flex-row items-center gap-2 relative">
                    <Eth className="self-center sm:w-8 sm:h-8  h-3 w-3 fill-current mr-1" />
                    <span className="uppercase">
                      {displayAddress(ethContractAddress)}
                    </span>
                    <Button size={"xs"} onClick={handleCopyEth}>
                      Copy
                    </Button>
                    {copiedEth && (
                      <span className="absolute right-[-50px] uppercase">
                        Copied!
                      </span>
                    )}
                  </span>
                </span>
              </div>
            </div>
          )}
          <div className="flex flex-col items-center sm:border sm:border-terminal-green p-5 text-center sm:gap-10 z-1 sm:h-[400px] sm:w-1/3">
            <h2 className="hidden sm:block text-terminal-green text-2xl sm:text-4xl uppercase m-0">
              Logout
            </h2>
            <p className="hidden sm:block sm:text-lg">
              Logout to go back to the login page and select a different wallet
              or switch to testnet.
            </p>
            <Button
              size={"lg"}
              onClick={() => {
                disconnect();
                resetData();
                setAdventurer(NullAdventurer);
                setNetwork(undefined);
                handleOffboarded();
                setShowProfile(false);
              }}
            >
              Logout
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};
