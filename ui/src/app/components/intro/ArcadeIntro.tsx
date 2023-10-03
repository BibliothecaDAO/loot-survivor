import { useState } from "react";
import { useAccount, useConnectors } from "@starknet-react/core";
import { useBurner } from "@/app/lib/burner";
import { Button } from "../buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";
import PixelatedImage from "../animations/PixelatedImage";
import { getWalletConnectors } from "@/app/lib/connectors";

export const ArcadeIntro = () => {
  const { address } = useAccount();
  const { connect, available } = useConnectors();
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const { getMasterAccount, create, isDeploying, isSettingPermissions } =
    useBurner();
  const walletConnectors = getWalletConnectors(available);
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
            Fear not, for they're guarded by a labyrinth of security features,
            fit for even the wiliest of adventurers!
          </p>
          <p className=" text-sm xl:text-xl 2xl:text-2xl">
            Connect using a wallet provider.
          </p>
          <div className="flex flex-col w-1/4">
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
          <p className=" text-sm xl:text-xl 2xl:text-2xl">
            Create Arcade Account (Fund, deploy & initiate security permissions)
          </p>
          <Button
            onClick={() => create()}
            disabled={isWrongNetwork}
            className="w-1/4"
          >
            CREATE
          </Button>
          {isDeploying && (
            <div className="fixed inset-0 opacity-80 bg-terminal-black z-50 m-2 w-full h-full">
              <PixelatedImage
                src={"/scenes/intro/arcade-account.png"}
                pixelSize={5}
              />
              <h3 className="loading-ellipsis absolute top-1/2 right-1/3">
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
