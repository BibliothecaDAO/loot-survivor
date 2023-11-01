import { ChangeEvent, useState, useEffect } from "react";
import { Connector, useContract } from "@starknet-react/core";
import { padAddress, isChecksumAddress } from "@/app/lib/utils";
import { BurnerStorage } from "@/app/types";
import { Button } from "@/app/components/buttons/Button";
import Storage from "@/app/lib/storage";
import ArcadeAccount from "@/app/abi/ArcadeAccount.json";

interface RecoverArcadeProps {
  setRecoverArcade: (recoverArcade: boolean) => void;
  walletAddress: string;
  walletConnectors: Connector[];
  connect: any;
  disconnect: any;
  genNewKey: (burnerAddress: string, connector: Connector) => Promise<void>;
  connector: Connector;
  updateConnectors: () => void;
}

const RecoverArcade = ({
  setRecoverArcade,
  walletAddress,
  walletConnectors,
  connect,
  disconnect,
  genNewKey,
  connector,
  updateConnectors,
}: RecoverArcadeProps) => {
  const [recoveryAddress, setRecoveryAddress] = useState<string | undefined>();
  const [recoveryMasterAddress, setRecoveryMasterAddress] = useState<
    string | undefined
  >();

  const formattedRecoveryAddress = padAddress(
    padAddress(recoveryAddress ?? "")
  );

  const { contract: arcadeContract } = useContract({
    address: formattedRecoveryAddress,
    abi: ArcadeAccount,
  });

  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { value } = e.target;
    setRecoveryAddress(value);
  };

  const handleGetMaster = async () => {
    const masterAccount = await arcadeContract?.call("get_master_account");
    setRecoveryMasterAddress("0x" + masterAccount?.toString(16));
  };

  const isMasterAccount =
    padAddress(walletAddress) === padAddress(recoveryMasterAddress ?? "");
  const recoveryAccountExists = () => {
    const storage: BurnerStorage = Storage.get("burners");
    if (storage) {
      return Object.keys(storage).includes(formattedRecoveryAddress ?? "");
    } else {
      return false;
    }
  };

  useEffect(() => {
    if (isChecksumAddress(formattedRecoveryAddress)) {
      handleGetMaster();
    }
  }, [recoveryAddress]);

  return (
    <div className="flex flex-col items-center gap-5 h-3/4 w-full">
      <p className="text-3xl uppercase">Recover Arcade</p>
      <p className="text-lg">Enter address of the Arcade Account.</p>
      <input
        type="text"
        name="address"
        onChange={handleChange}
        className="p-1 m-2 bg-terminal-black border border-terminal-green animate-pulse transform w-1/2 2xl:h-16 2xl:text-4xl"
        maxLength={66}
      />
      {recoveryAddress && !isMasterAccount && (
        <>
          <p className="text-lg">Connect Master Account</p>
          {walletConnectors.map((connector, index) => (
            <Button
              disabled={
                !isChecksumAddress(formattedRecoveryAddress) || isMasterAccount
              }
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
        </>
      )}
      <Button
        onClick={async () => {
          await genNewKey(formattedRecoveryAddress, connector!);
          updateConnectors();
          setRecoverArcade(false);
        }}
        disabled={!isMasterAccount || recoveryAccountExists()}
        className="w-1/4"
      >
        {recoveryAccountExists() ? "Account Already Stored" : "Recover Account"}
      </Button>
    </div>
  );
};

export default RecoverArcade;
