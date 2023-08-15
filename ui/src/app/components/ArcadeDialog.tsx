import useUIStore from "@/app/hooks/useUIStore";
import { Button } from "./buttons/Button";
import { PREFUND_AMOUNT, useBurner } from "../lib/burner";
import { Connector, useAccount, useBalance, useConnectors } from "@starknet-react/core";
import { AccountInterface, CallData, TransactionStatus } from "starknet";
import { useCallback } from "react";

export const ArcadeDialog = () => {
  const { account: MasterAccount, address, connector } = useAccount();
  const showArcadeDialog = useUIStore((state) => state.showArcadeDialog);
  const arcadeDialog = useUIStore((state) => state.arcadeDialog);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const { connect, connectors, available } = useConnectors();
  const { create, isDeploying } = useBurner();
  
  const arcadeConnectors = useCallback(() => {
    return available.filter(
      (connector) =>
        typeof connector.id === "string" && connector.id.includes("0x")
    );
  }, [available]);

  if (!connectors) return <div></div>;

  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed text-center top-1/8 left-1/8 sm:left-1/4 w-3/4 sm:w-1/2 h-3/4 border  bg-terminal-black z-50 border-terminal-green p-3">
        <Button onClick={() => showArcadeDialog(!arcadeDialog)}>close</Button>

        <h3 className="mt-8">Arcade Account</h3>

        <p className="text-2xl pb-8">
          Create an Arcade Account here <br /> to allow for signature free gameplay!
        </p>

        <div className="flex justify-center">
          {((connector?.options as any)?.id == "argentX" ||
            (connector?.options as any)?.id == "braavos") && (
              <div>
                <Button onClick={() => create()} disabled={isWrongNetwork}>
                  create arcade account
                </Button>
                <p className="my-2 text-terminal-yellow p-2 border border-terminal-yellow">
                  Note: This will initiate a 0.01 ETH transaction to the new <br />
                  account. Your page will reload after the Account has been
                  created!
                </p>
              </div>
            )}
        </div>

        <h5>Existing</h5>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-2 ">
          {arcadeConnectors().map((account, index) => {
            return (
              <ArcadeAccountCard key={index} account={account} onClick={connect} address={address!} masterAccount={MasterAccount!} />
            );
          })}
          {isDeploying && <div className="flex justify-center border-terminal-green border h-32">
            <p className="self-center">Deploying Account...</p>
          </div>}
        </div>

      </div>
    </>
  );
};

interface ArcadeAccountCardProps {
  account: Connector;
  onClick: (conn: Connector<any>) => void;
  address: string;
  masterAccount: AccountInterface
}


export const ArcadeAccountCard = ({ account, onClick, address, masterAccount }: ArcadeAccountCardProps) => {

  const { data } = useBalance({
    address: account.name,
  })

  const connected = address == account.name;

  const balance = parseFloat(data?.formatted!).toFixed(4)

  const transfer = async (address: string, account: AccountInterface) => {
    try {
      const { transaction_hash } = await account.execute({
        contractAddress: process.env.NEXT_PUBLIC_ETH_CONTRACT_ADDRESS!,
        entrypoint: "transfer",
        calldata: CallData.compile([address, PREFUND_AMOUNT, "0x0"]),
      });

      console.log(transaction_hash);

      const result = await account.waitForTransaction(transaction_hash, {
        retryInterval: 1000,
        successStates: [TransactionStatus.ACCEPTED_ON_L2],
      });

      if (!result) {
        throw new Error("Transaction did not complete successfully.");
      }

      return result;
    } catch (error) {
      console.error(error);
      throw error;
    }
  };

  return (
    <div className="border border-terminal-green p-3 hover:bg-terminal-green hover:text-terminal-black ">
      <div className="text-left flex justify-between text-xl mb-4">{account.id} <span>{balance}</span> </div>
      <div className=" flex justify-between">
        <Button
          variant={connected ? "default" : "outline"}
          onClick={() => onClick(account)}
        >
          {connected ? "connected" : "connect"}
        </Button>
      </div>

    </div>
  )
}
