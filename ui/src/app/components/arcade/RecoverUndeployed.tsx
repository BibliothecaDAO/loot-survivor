import { ChangeEvent, useEffect, useState } from "react";
import { AccountInterface, CallData, hash } from "starknet";
import { Connector, useContract } from "@starknet-react/core";
import { Button } from "@/app/components/buttons/Button";
import { indexAddress, padAddress, isChecksumAddress } from "@/app/lib/utils";
import ArcadeAccount from "@/app/abi/ArcadeAccount.json";
import Storage from "@/app/lib/storage";
import { KeyStorage } from "@/app/types";

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
  const [accountExists, setAccountExists] = useState(false);
  const [correctKeys, setCorrectKeys] = useState(false);
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

  const { contract: arcadeContract } = useContract({
    address: formattedRecoveryUndeployedAddress,
    abi: ArcadeAccount,
  });

  const handleGetMaster = async () => {
    try {
      await arcadeContract?.call("get_master_account");
      setAccountExists(true);
    } catch (error) {
      setAccountExists(false);
    }
  };

  const handleCheckKeys = async () => {
    let storageKeys: KeyStorage = Storage.get("keys") || {};

    const publicKey = storageKeys[formattedRecoveryUndeployedAddress].publicKey;

    if (!walletAccount) {
      throw new Error("wallet account not found");
    }

    const constructorAACalldata = CallData.compile({
      _public_key: publicKey,
      _master_account: walletAccount.address,
    });

    const address = hash.calculateContractAddressFromHash(
      publicKey,
      process.env.NEXT_PUBLIC_ARCADE_ACCOUNT_CLASS_HASH!,
      constructorAACalldata,
      0
    );

    setCorrectKeys(padAddress(address) == formattedRecoveryUndeployedAddress);
  };

  useEffect(() => {
    if (isChecksumAddress(formattedRecoveryUndeployedAddress)) {
      handleGetMaster();
      handleCheckKeys();
    }
  }, [recoveryUndeployedAddress]);

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
        disabled={accountExists || !correctKeys}
      >
        {accountExists
          ? "Account Already Deployed"
          : !correctKeys
          ? "Keys don't match address"
          : "Recover Account"}
      </Button>
    </div>
  );
};

export default RecoverUndeployed;
