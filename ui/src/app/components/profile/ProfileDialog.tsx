import { useState } from "react";
import { MdClose } from "react-icons/md";
import useUIStore from "@/app/hooks/useUIStore";
import { Button } from "@/app/components/buttons/Button";
import { useDisconnect } from "@starknet-react/core";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { NullAdventurer } from "@/app/types";
import useNetworkAccount from "@/app/hooks/useNetworkAccount";
import { displayAddress, padAddress, copyToClipboard } from "@/app/lib/utils";
import { AccountInterface } from "starknet";

interface ProfileDialogprops {
  withdraw: (
    adminAccountAddress: string,
    account: AccountInterface,
    ethBalance: bigint,
    lordsBalance: bigint
  ) => Promise<void>;
  ethBalance: bigint;
  lordsBalance: bigint;
}

export const ProfileDialog = ({
  withdraw,
  ethBalance,
  lordsBalance,
}: ProfileDialogprops) => {
  const { setShowProfile, setNetwork } = useUIStore();
  const { disconnect } = useDisconnect();
  const { setAdventurer } = useAdventurerStore();
  const resetData = useQueriesStore((state) => state.resetData);
  const { account, address } = useNetworkAccount();
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    copyToClipboard(padAddress(address!));
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const adminAccountAddress = "0x0";

  return (
    <div className="fixed w-full sm:w-3/4 sm:h-3/4 h-1/2 top-1/8 bg-terminal-black border border-terminal-green flex flex-col items-center p-10 z-30">
      <button
        className="absolute top-2 right-2 cursor-pointer text-terminal-green"
        onClick={() => {
          setShowProfile(false);
        }}
      >
        <MdClose size={50} />
      </button>
      <div className="flex flex-col items-center h-full gap-5">
        <h1 className="text-terminal-green text-6xl uppercase">Profile</h1>
        <div className="flex flex-row gap-2">
          <div className="flex flex-col items-center border border-terminal-green p-5 text-center gap-10 z-1 h-[400px] w-1/3">
            <h2 className="text-terminal-green text-4xl uppercase m-0">
              Withdraw
            </h2>
            <p className="text-lg">
              Withdraw to the Cartridge Controller admin account.
            </p>
            <p className="text-4xl">{displayAddress(address!)}</p>
            <Button
              onClick={() =>
                withdraw(
                  adminAccountAddress,
                  account!,
                  ethBalance,
                  lordsBalance
                )
              }
            >
              Withdraw
            </Button>
          </div>
          <div className="flex flex-col items-center border border-terminal-green p-5 text-center gap-10 z-1 h-[400px] w-1/3">
            <h2 className="text-terminal-green text-4xl uppercase m-0">
              Topup
            </h2>
            <div className="flex gap-2">
              <span className="text-4xl">{displayAddress(address!)}</span>
              <div className="relative">
                {copied && (
                  <span className="absolute top-[-20px] uppercase">
                    Copied!
                  </span>
                )}
                <Button onClick={handleCopy}>Copy</Button>
              </div>
            </div>
            <p className="text-lg">
              Low on tokens? Copy the address and above and transfer tokens from
              the wallet of your choice.
            </p>
          </div>
          <div className="flex flex-col items-center border border-terminal-green p-5 text-center gap-10 z-1 h-[400px] w-1/3">
            <h2 className="text-terminal-green text-4xl uppercase m-0">
              Logout
            </h2>
            <p className="text-lg">
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
