import { useState, FormEvent, useEffect } from "react";
import { useAccount, useConnect } from "@starknet-react/core";
import { TypeAnimation } from "react-type-animation";
import { MdClose } from "react-icons/md";
import { WalletTutorial } from "@/app/components/intro/WalletTutorial";
import { TxActivity } from "@/app/components/navigation/TxActivity";
import useUIStore from "@/app/hooks/useUIStore";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import { battle } from "@/app/lib/constants";
import { FormData } from "@/app/types";
import { Button } from "@/app/components/buttons/Button";
import Image from "next/image";
import Lords from "../../../../public/icons/lords.svg";
import { getArcadeConnectors, getWalletConnectors } from "@/app/lib/connectors";

export interface SpawnProps {
  formData: FormData;
  spawn: (...args: any[]) => any;
  handleBack: () => void;
  lordsBalance?: bigint;
  mintLords: (...args: any[]) => any;
}

export const Spawn = ({
  formData,
  spawn,
  handleBack,
  lordsBalance,
  mintLords,
}: SpawnProps) => {
  const [showWalletTutorial, setShowWalletTutorial] = useState(false);
  const [formFilled, setFormFilled] = useState(false);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const loading = useLoadingStore((state) => state.loading);
  const estimatingFee = useUIStore((state) => state.estimatingFee);
  const resetNotification = useLoadingStore((state) => state.resetNotification);

  useEffect(() => {
    if (formData.name && formData.startingWeapon) {
      setFormFilled(true);
    } else {
      setFormFilled(false);
    }
  }, [formData]);

  const { account } = useAccount();
  const { connectors, connect } = useConnect();

  const walletConnectors = getWalletConnectors(connectors);
  const arcadeConnectors = getArcadeConnectors(connectors);

  const handleButtonClick = () => {
    setShowWalletTutorial(true);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    resetNotification();
    await spawn(formData);
  };

  const checkEnoughLords = lordsBalance! >= BigInt(25000000000000000000);

  const goldenTokenExists = true;

  return (
    <div className="flex flex-col w-full h-full justify-center">
      {showWalletTutorial && (
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-1/2 h-4/5 z-20 bg-terminal-black overflow-y-auto flex flex-col items-center gap-4">
          <Button
            onClick={() => setShowWalletTutorial(false)}
            className="text-red-500 hover:text-red-700"
            variant={"ghost"}
          >
            <MdClose size={20} />
          </Button>
          <WalletTutorial />
        </div>
      )}
      <div className="flex flex-col h-full p-2">
        <Image
          className="mx-auto absolute object-cover sm:py-4 sm:px-8"
          src={"/scenes/intro/beast.png"}
          alt="adventurer facing beast"
          fill
        />

        <div className="absolute top-1/3 left-0 right-0 flex flex-col items-center text-center gap-4 z-10">
          <TypeAnimation
            sequence={[battle]}
            wrapper="span"
            cursor={true}
            speed={40}
            style={{ fontSize: "2em" }}
          />
          <span className="hidden sm:block">
            <TxActivity />
          </span>
          {!account ? (
            <>
              <div className="flex flex-col gap-5 items-center justify-center">
                <div className="flex flex-col gap-2">
                  {walletConnectors.map((connector, index) => (
                    <Button
                      onClick={() => connect({ connector })}
                      disabled={!formFilled}
                      key={index}
                      className="w-full"
                    >
                      {connector.id === "braavos" || connector.id === "argentX"
                        ? `Connect ${connector.id}`
                        : "Login With Email"}
                    </Button>
                  ))}
                  <Button onClick={handleButtonClick}>
                    I don&apos;t have a wallet
                  </Button>
                </div>
                <p className="text-xl">Arcade Accounts</p>
                <div className="flex flex-col items-center justify-center sm:flex-row gap-2 overflow-auto h-[300px] sm:h-full w-full sm:w-[400px]">
                  {arcadeConnectors.map((connector, index) => (
                    <Button
                      onClick={() => connect({ connector })}
                      disabled={!formFilled}
                      key={index}
                      className="w-1/3"
                    >
                      Connect {connector.id}
                    </Button>
                  ))}
                </div>
              </div>
            </>
          ) : (
            <>
              <form
                onSubmit={async (e) => {
                  if (formData) {
                    await handleSubmit(e);
                  }
                }}
              >
                <div className="flex flex-col gap-2">
                  <Button
                    type="submit"
                    size={"xl"}
                    disabled={
                      !formFilled ||
                      !account ||
                      isWrongNetwork ||
                      loading ||
                      estimatingFee ||
                      !checkEnoughLords
                    }
                    className="relative"
                  >
                    <div className="flex flex-row items-center gap-1 w-full h-full">
                      <p className="whitespace-nowrap w-3/4 mr-5">
                        {checkEnoughLords
                          ? formFilled
                            ? "Insert Lords"
                            : "Fill details"
                          : "Not enough Lords"}
                      </p>
                      <Lords className="absolute self-center sm:w-5 sm:h-5  h-3 w-3 fill-current right-5" />
                    </div>
                  </Button>

                  <Button
                    type="submit"
                    size={"xl"}
                    disabled={
                      !formFilled ||
                      !account ||
                      isWrongNetwork ||
                      loading ||
                      estimatingFee ||
                      !goldenTokenExists ||
                      true //TODO: UNCOMMENT
                    }
                    className="relative"
                  >
                    <div className="flex flex-row items-center gap-1 w-full h-full">
                      <p className="whitespace-nowrap w-3/4">
                        {goldenTokenExists
                          ? formFilled
                            ? "Insert Golden Token"
                            : "Fill details"
                          : "No tokens"}
                      </p>
                      <div className="absolute right-3 w-6 h-6 sm:w-8 sm:h-8">
                        <Image
                          src={"/golden-token.png"}
                          alt="Golden Token"
                          fill={true}
                        />
                      </div>
                    </div>
                  </Button>
                </div>
              </form>
              {!checkEnoughLords && (
                <Button onClick={mintLords}>Mint Lords</Button>
              )}
            </>
          )}
        </div>
        <div className="absolute bottom-10 left-0 right-0 flex flex-col items-center gap-4 z-10 pb-8">
          <Button size={"sm"} variant={"default"} onClick={handleBack}>
            Back
          </Button>
        </div>
      </div>
    </div>
  );
};
