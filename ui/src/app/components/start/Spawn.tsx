import { useState, FormEvent, useEffect } from "react";
import Image from "next/image";
import { Button } from "../buttons/Button";
import { MdClose } from "react-icons/md";
import { WalletTutorial } from "../tutorial/WalletTutorial";
import { TxActivity } from "../navigation/TxActivity";
import useUIStore from "@/app/hooks/useUIStore";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import { useAccount, useConnectors } from "@starknet-react/core";
import { TypeAnimation } from "react-type-animation";
import { battle } from "@/app/lib/constants";
import { FormData } from "@/app/types";

export interface SpawnProps {
  formData: FormData;
  spawn: (...args: any[]) => any;
  handleBack: () => void;
}

export const Spawn = ({ formData, spawn, handleBack }: SpawnProps) => {
  const [showWalletTutorial, setShowWalletTutorial] = useState(false);
  const [formFilled, setFormFilled] = useState(false);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const loading = useLoadingStore((state) => state.loading);
  const resetNotification = useLoadingStore((state) => state.resetNotification);

  useEffect(() => {
    if (formData.startingStrength && formData.name && formData.startingWeapon) {
      setFormFilled(true);
    } else {
      setFormFilled(false);
    }
  }, [formData]);

  const { account } = useAccount();
  const { connectors, connect } = useConnectors();

  const walletConnectors = () =>
    connectors.filter((connector) => !connector.id.includes("0x"));

  const handleButtonClick = () => {
    setShowWalletTutorial(true);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    resetNotification();
    await spawn(formData);
  };

  return (
    <div className="flex flex-col w-full h-full justify-center">
      {showWalletTutorial && (
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-1/2 h-4/5 z-20 bg-terminal-black overflow-y-auto flex flex-col items-center gap-4">
          {" "}
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
      <div className="flex flex-col h-full">
        <Image
          className="mx-auto border border-terminal-green absolute  object-cover sm:py-4 sm:px-8"
          src={"/scenes/intro/beast.png"}
          alt="adventurer facing beast"
          fill
        />

        <span className="absolute sm:hidden top-0">
          <TxActivity />
        </span>

        {!isWrongNetwork && (
          <div className="absolute text-xs sm:text-xl leading-normal sm:leading-loose z-10 top-1/4">
            <TypeAnimation
              sequence={[battle]}
              wrapper="span"
              cursor={true}
              speed={40}
              style={{ fontSize: "2em" }}
            />
          </div>
        )}

        <div className="absolute top-1/2 left-0 right-0 flex flex-col items-center gap-4 z-10">
          <span className="hidden sm:block">
            <TxActivity />
          </span>
          {!account ? (
            <>
              <div className="flex flex-col justify-between">
                <div className="flex flex-col gap-2">
                  {walletConnectors().map((connector, index) => (
                    <Button
                      onClick={() => connect(connector)}
                      disabled={!formFilled}
                      key={index}
                      className="w-full"
                    >
                      Connect {connector.id}
                    </Button>
                  ))}
                  <Button onClick={handleButtonClick}>
                    I don&apos;t have a wallet
                  </Button>
                </div>
              </div>
            </>
          ) : (
            <form
              onSubmit={async (e) => {
                if (formData) {
                  await handleSubmit(e);
                }
              }}
            >
              <Button
                type="submit"
                size={"xl"}
                disabled={!formFilled || !account || isWrongNetwork || loading}
              >
                {formFilled ? "Start Game!!" : "Fill details"}
              </Button>
            </form>
          )}
        </div>
        <div className="absolute bottom-10 left-0 right-0 flex flex-col items-center gap-4 z-10 pb-8">
          <Button size={"xs"} variant={"default"} onClick={handleBack}>
            Back
          </Button>
        </div>
      </div>
    </div>
  );
};
