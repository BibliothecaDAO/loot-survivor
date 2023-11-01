import { ChangeEvent, useState } from "react";
import { AccountInterface } from "starknet";
import { Connector } from "@starknet-react/core";
import { Button } from "@/app/components/buttons/Button";
import { indexAddress, padAddress } from "@/app/lib/utils";

interface RecoverUndeployedProps {
  setRecoverUndeployed: (recoverUndeployed: boolean) => void;
  connector: Connector;
  deployAccountFromHash: (
    connector: Connector,
    address: string,
    walletAccount: AccountInterface
  ) => Promise<void>;
  walletAccount: AccountInterface;
  updateConnectors: () => void;
}

const RecoverUndeployed = ({
  setRecoverUndeployed,
  connector,
  deployAccountFromHash,
  walletAccount,
  updateConnectors,
}: RecoverUndeployedProps) => {
  const [recoveryUndeployedAddress, setRecoveryUndeployedAddress] = useState<
    string | undefined
  >();
  const handleUndeployedChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { value } = e.target;
    setRecoveryUndeployedAddress(indexAddress(value));
  };

  const formattedRecoveryUndeployedAddress = padAddress(
    padAddress(recoveryUndeployedAddress ?? "")
  );

  return (
    <div className="flex flex-col items-center gap-5 h-3/4 w-full">
      <p className="text-3xl uppercase">Recover Undeployed</p>
      <p className="text-lg">Enter address of the undeployed Arcade Account.</p>
      <input
        type="text"
        name="address"
        onChange={handleUndeployedChange}
        className="p-1 m-2 bg-terminal-black border border-terminal-green animate-pulse transform w-1/2 2xl:h-16 2xl:text-4xl"
        maxLength={66}
      />
      <Button
        onClick={async () => {
          await deployAccountFromHash(
            connector!,
            formattedRecoveryUndeployedAddress,
            walletAccount!
          );
          updateConnectors();
          setRecoverUndeployed(false);
        }}
        className="w-1/4"
      >
        {"Recover Account"}
      </Button>
    </div>
  );
};

export default RecoverUndeployed;
