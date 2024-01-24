import { ChangeEvent, useState, useEffect } from "react";
import { AccountInterface, CallData, Contract, ec, hash } from "starknet";
import { Connector, useContract } from "@starknet-react/core";
import { padAddress, isChecksumAddress } from "@/app/lib/utils";
import { Button } from "@/app/components/buttons/Button";
import Storage from "@/app/lib/storage";
import ArcadeAccount from "@/app/abi/ArcadeAccount.json";

interface MigrateAAProps {
  setMigrateAA: (migrateAA: boolean) => void;
  walletAccount: AccountInterface;
  walletConnectors: Connector[];
  connector: Connector;
  gameContract: Contract;
  connect: any;
  disconnect: any;
  updateConnectors: () => void;
}

const MigrateAA = ({
  setMigrateAA,
  walletAccount,
  walletConnectors,
  connector,
  gameContract,
  connect,
  disconnect,
  updateConnectors,
}: MigrateAAProps) => {
  const [arcadePrivateKey, setArcadePrivateKey] = useState<
    string | undefined
  >();
  const [arcadeExists, setArcadeExists] = useState<boolean>(false);
  const [arcadeAddress, setArcadeAddress] = useState<string | undefined>();
  const [arcadePublicKey, setArcadePublicKey] = useState<string | undefined>();
  const [masterAccount, setMasterAccount] = useState<string | undefined>();

  const formattedArcadeAddress = padAddress(padAddress(arcadeAddress ?? ""));

  const storage = Storage.get("burners") || {};

  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { value } = e.target;
    setArcadePrivateKey(value);
  };

  const { contract: arcadeContract } = useContract({
    address: formattedArcadeAddress,
    abi: ArcadeAccount,
  });

  const getMasterAccount = async () => {
    try {
      const masterAccount = await arcadeContract?.call("get_master_account");
      if (masterAccount) {
        setArcadeExists(true);
        setMasterAccount("0x" + masterAccount?.toString(16));
      }
    } catch (e) {
      console.log(e);
    }
  };

  const handleGetArcade = () => {
    if (isChecksumAddress(arcadePrivateKey!)) {
      const publicKey = ec.starkCurve.getStarkKey(arcadePrivateKey!);

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

      setArcadeAddress(address);
      setArcadePublicKey(publicKey);
    }
  };

  const importBurner = () => {
    storage[formattedArcadeAddress!] = {
      privateKey: arcadePrivateKey,
      publicKey: arcadePublicKey,
      masterAccount: walletAccount.address,
      masterAccountProvider: connector.id,
      gameContract: gameContract?.address,
      active: true,
    };

    Storage.set("burners", storage);
  };

  const arcadeAccountExists = () => {
    if (storage) {
      return Object.keys(storage).includes(formattedArcadeAddress ?? "");
    } else {
      return false;
    }
  };

  const isMasterAccount =
    padAddress(walletAccount.address) === padAddress(masterAccount ?? "");

  useEffect(() => {
    if (arcadePrivateKey) {
      handleGetArcade();
    }
  }, [arcadePrivateKey]);

  useEffect(() => {
    if (arcadeAddress) {
      getMasterAccount();
    }
  }, [arcadeAddress]);

  return (
    <div className="flex flex-col items-center gap-5 h-3/4 w-full">
      <p className="text-2xl uppercase">Import Arcade Account</p>
      <p className="text-lg">
        Please enter the private key of the Arcade Account you would like to
        import to this client.
      </p>
      <input
        type="text"
        name="address"
        onChange={handleChange}
        className="p-1 m-2 bg-terminal-black border border-terminal-green animate-pulse transform w-1/2 2xl:h-16 2xl:text-4xl"
        maxLength={66}
      />
      {!isMasterAccount && arcadeAddress && (
        <>
          <p className="text-lg">Connect Master Account</p>
          {walletConnectors.map((connector, index) => (
            <Button
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
        disabled={
          !isChecksumAddress(arcadePrivateKey!) ||
          !arcadeExists ||
          arcadeAccountExists()
        }
        onClick={() => {
          importBurner();
          updateConnectors();
          setMigrateAA(false);
        }}
        className="w-1/4"
      >
        {!arcadeExists
          ? "Arcade Doesn't Exist"
          : arcadeAccountExists()
          ? "Arcade Already Stored"
          : "Import Arcade"}
      </Button>
      {/* <p className="text-2xl">Export</p>
      <p className="text-lg">
        Here you can export the private key of the Arcade Account. This can then
        be imported to other clients that intract with the LS contract.
      </p> */}
      {/* <Button
        onClick={async () => {
          await genNewKey(formattedRecoveryAddress, connector!);
          updateConnectors();
        }}
        disabled={!isMasterAccount || recoveryAccountExists()}
        className="w-1/4"
      >
        {recoveryAccountExists() ? "Account Already Stored" : "Recover Account"}
      </Button> */}
    </div>
  );
};

export default MigrateAA;
