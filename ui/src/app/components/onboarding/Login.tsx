import { useEffect, useState } from "react";
import { Section } from "@/app/containers/Onboarding";
import { CompleteIcon } from "@/app/components/icons/Icons";
import WalletSection from "@/app/components/onboarding/Sections/WalletSection";
import EthSection from "@/app/components/onboarding/Sections/EthSection";
import LordsSection from "@/app/components/onboarding/Sections/LordsSection";
import { ScreenPage } from "@/app/hooks/useUIStore";
import useUIStore from "@/app/hooks/useUIStore";
import { ETH_PREFUND_AMOUNT } from "@/app/lib/constants";
import useNetworkAccount from "@/app/hooks/useNetworkAccount";
import { checkCartridgeConnector } from "@/app/lib/connectors";
import { useConnect } from "@starknet-react/core";

interface LoginProps {
  eth: number;
  lords: number;
  lordsGameCost: number;
  setMintingLords: (value: boolean) => void;
  mintLords: (lordsAmount: number) => Promise<void>;
  setScreen: (value: ScreenPage) => void;
  setSection: (value: Section) => void;
  getBalances: () => Promise<void>;
}

const Login = ({
  eth,
  lords,
  lordsGameCost,
  setMintingLords,
  mintLords,
  setScreen,
  setSection,
  getBalances,
}: LoginProps) => {
  const { account } = useNetworkAccount();
  const [step, setStep] = useState(1);
  const { connector } = useConnect();

  const { handleOnboarded, network, onMainnet } = useUIStore();

  const checkEnoughEth = eth >= parseInt(ETH_PREFUND_AMOUNT(network!)) - 1;
  const checkEnoughLords = lords > lordsGameCost;

  useEffect(() => {
    if (
      account &&
      (checkEnoughEth || checkCartridgeConnector(connector)) &&
      checkEnoughLords
    ) {
      setScreen("start");
      handleOnboarded();
    } else if (
      account &&
      (checkEnoughEth || checkCartridgeConnector(connector))
    ) {
      setStep(3);
    } else if (account) {
      setStep(2);
    } else {
      setStep(1);
    }
  }, [account, checkEnoughEth, checkEnoughLords]);

  useEffect(() => {
    if (account) {
      getBalances();
    }
  }, [account]);

  return (
    <>
      <div className="hidden sm:flex flex-row h-5/6 gap-5">
        <div className="flex flex-col items-center w-1/3">
          <h2 className="m-0">1</h2>
          <div className="relative z-1 px-2 sm:px-0">
            <WalletSection step={step} />
          </div>
        </div>
        <div className="flex flex-col items-center w-1/3">
          <h2 className="m-0">2</h2>
          <div className="relative z-1 px-2 sm:px-0">
            <EthSection
              step={step}
              eth={eth}
              onMainnet={onMainnet}
              network={network!}
              setSection={setSection}
            />
          </div>
        </div>
        <div className="flex flex-col items-center w-1/3">
          <h2 className="m-0">3</h2>
          <div className="relative z-1 px-2 sm:px-0">
            <LordsSection
              step={step}
              lords={lords}
              onMainnet={onMainnet}
              network={network!}
              setSection={setSection}
              setMintingLords={setMintingLords}
              mintLords={mintLords}
              lordsGameCost={lordsGameCost}
            />
          </div>
        </div>
      </div>
      <div className="sm:hidden">
        {step == 1 && <WalletSection step={step} />}
        {step == 2 && (
          <EthSection
            step={step}
            eth={eth}
            onMainnet={onMainnet}
            network={network!}
            setSection={setSection}
          />
        )}
        {step == 3 && (
          <LordsSection
            step={step}
            lords={lords}
            onMainnet={onMainnet}
            network={network!}
            setSection={setSection}
            setMintingLords={setMintingLords}
            mintLords={mintLords}
            lordsGameCost={lordsGameCost}
          />
        )}
      </div>
      <div className="sm:hidden flex items-center justify-center w-full h-1/5">
        <div className="flex flex-row justify-between items-center w-1/2 h-full">
          <div
            className={`flex justify-center items-center w-8 h-8 sm:w-12 sm:h-12 ${
              step >= 1
                ? "bg-terminal-green text-terminal-black"
                : "border border-terminal-green"
            }`}
          >
            {step > 1 ? <CompleteIcon /> : 1}
          </div>
          <div
            className={`flex justify-center items-center w-8 h-8 sm:w-12 sm:h-12  ${
              step >= 2
                ? "bg-terminal-green text-terminal-black"
                : "border border-terminal-green"
            }`}
          >
            {step > 2 ? <CompleteIcon /> : 2}
          </div>
          <div
            className={`flex justify-center items-center w-8 h-8 sm:w-12 sm:h-12  ${
              step >= 3
                ? "bg-terminal-green text-terminal-black"
                : "border border-terminal-green"
            }`}
          >
            {step > 3 ? <CompleteIcon /> : 3}
          </div>
        </div>
      </div>
    </>
  );
};

export default Login;
