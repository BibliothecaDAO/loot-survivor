import { useState } from "react";
import { useAccount, useConnectors, useBalance } from "@starknet-react/core";
import {
  ETH_PREFUND_AMOUNT,
  LORDS_PREFUND_AMOUNT,
  useBurner,
} from "@/app/lib/burner";
import { Button } from "@/app/components/buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";
import PixelatedImage from "@/app/components/animations/PixelatedImage";
import { getWalletConnectors } from "@/app/lib/connectors";
import Lords from "public/icons/lords.svg";
import { useContracts } from "@/app/hooks/useContracts";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { Call } from "@/app/types";

export const ArcadeIntro = () => {
  const { account, address } = useAccount();
  const { connect, available } = useConnectors();
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const { create, isDeploying, isSettingPermissions } = useBurner();
  const walletConnectors = getWalletConnectors(available);
  const { lordsContract, ethContract } = useContracts();
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const { data: ethBalance } = useBalance({
    token: ethContract?.address,
    address,
  });
  const { data: lordsBalance, refetch: refetchLordsBalance } = useBalance({
    token: lordsContract?.address,
    address,
  });
  const lords = Number(lordsBalance?.value);
  const eth = Number(ethBalance?.value);
  const [isMintingLords, setIsMintingLords] = useState(false);

  const mintLords = async () => {
    try {
      setIsMintingLords(true);
      // Mint 250 LORDS
      const mintLords: Call = {
        contractAddress: lordsContract?.address ?? "",
        entrypoint: "mint",
        calldata: [address ?? "0x0", (250 * 10 ** 18).toString(), "0"],
      };
      addToCalls(mintLords);
      const tx = await handleSubmitCalls(account!, [...calls, mintLords]);
      const result = await account?.waitForTransaction(tx?.transaction_hash, {
        retryInterval: 2000,
      });

      if (!result) {
        throw new Error("Lords Mint did not complete successfully.");
      }

      setIsMintingLords(false);
      refetchLordsBalance();
    } catch (e) {
      setIsMintingLords(false);
      console.log(e);
    }
  };

  const checkNotEnoughPrefundEth = eth < parseInt(ETH_PREFUND_AMOUNT);
  const checkAnyETh = eth === 0;

  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed text-center sm:top-1/8 sm:left-1/8 sm:left-1/4 sm:w-3/4 sm:w-1/2 h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4 overflow-y-auto">
        <h3 className="mt-4">Create Arcade Account</h3>
        <div className="flex flex-col gap-5 items-center">
          <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
            Greetings! Behold, the revelation of Arcade Accounts, the key to
            supercharging onchain games! These promise swift transactions,
            unleashing a 10x surge in your gameplay speed.
          </p>
          <p className="text-sm xl:text-xl 2xl:text-2xl">
            Stored in the browser but fear not, for they&apos;re guarded by a
            labyrinth of security features, fit for even the wiliest of
            adventurers!
          </p>
          <p className="text-sm xl:text-xl 2xl:text-2xl">
            Connect using a wallet provider.
          </p>
          <div className="flex flex-col gap-2 w-1/4">
            {walletConnectors.map((connector, index) => (
              <Button
                disabled={address !== undefined}
                onClick={() => connect(connector)}
                key={index}
              >
                {connector.id === "braavos" || connector.id === "argentX"
                  ? `Connect ${connector.id}`
                  : "Login With Email"}
              </Button>
            ))}
          </div>
          <p className="text-sm xl:text-xl 2xl:text-2xl">Mint Some Lords</p>
          <Button
            onClick={() =>
              checkAnyETh
                ? window.open("https://faucet.goerli.starknet.io/", "_blank")
                : mintLords()
            }
            disabled={
              isWrongNetwork ||
              isMintingLords ||
              lords >= parseInt(LORDS_PREFUND_AMOUNT)
            }
            className="flex flex-row w-1/4"
          >
            <Lords className="sm:w-5 sm:h-5  h-3 w-3 fill-current mr-1" />{" "}
            {isMintingLords ? (
              <p className="loading-ellipsis">Minting Lords</p>
            ) : checkAnyETh ? (
              "GET GOERLI ETH"
            ) : (
              "Mint"
            )}
          </Button>
          <p className="text-sm xl:text-xl 2xl:text-2xl">
            Create Arcade Account (Fund ETH + LORDS, deploy, set permissions and
            approvals)
          </p>
          <Button
            onClick={() =>
              checkNotEnoughPrefundEth
                ? window.open("https://faucet.goerli.starknet.io/", "_blank")
                : create()
            }
            disabled={isWrongNetwork || lords < parseInt(LORDS_PREFUND_AMOUNT)}
            className="w-1/4"
          >
            {checkNotEnoughPrefundEth ? "GET GOERLI ETH" : "CREATE"}
          </Button>
          {isDeploying && (
            <div className="fixed inset-0 opacity-80 bg-terminal-black z-50 m-2 w-full h-full">
              <PixelatedImage
                src={"/scenes/intro/arcade-account.png"}
                pixelSize={5}
                pulsate={true}
              />
              <h3 className="text-lg sm:text-3xl loading-ellipsis absolute top-2/3 sm:top-1/2 flex items-center justify-center w-full">
                {isSettingPermissions
                  ? "Setting Permissions"
                  : "Deploying Arcade Account"}
              </h3>
            </div>
          )}
        </div>
      </div>
    </>
  );
};
