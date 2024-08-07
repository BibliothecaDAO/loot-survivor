import { formatCurrency, indexAddress } from "@/app/lib/utils";
import Lords from "public/icons/lords.svg";
import { CompleteIcon, InfoIcon } from "@/app/components/icons/Icons";
import { Button } from "@/app/components/buttons/Button";
import { Section } from "@/app/containers/Onboarding";
import { Network } from "@/app/hooks/useUIStore";
import { networkConfig } from "@/app/lib/networkConfig";

interface LordsSectionProps {
  step: number;
  lords: number;
  onMainnet: boolean;
  network: Network;
  setSection: (section: Section) => void;
  mintLords: (lordsAmount: number) => Promise<void>;
  setMintingLords: (value: boolean) => void;
  lordsGameCost: number;
}

const LordsSection = ({
  step,
  lords,
  onMainnet,
  network,
  setSection,
  mintLords,
  setMintingLords,
  lordsGameCost,
}: LordsSectionProps) => {
  // const checkEnoughLords = lords > lordsGameCost;
  return (
    <>
      {step !== 3 && (
        <>
          <div className="absolute top-0 left-0 right-0 bottom-0 h-full w-full bg-black opacity-50 z-10" />
          {step > 3 ? (
            <div className="absolute flex flex-col w-1/2 top-1/4 right-1/4 z-20 items-center">
              <span className="flex flex-row text-center text-xl">
                You have {formatCurrency(lords)} LORDS
              </span>
              <CompleteIcon />
            </div>
          ) : (
            <div className="absolute w-1/2 top-1/4 right-1/4 z-20 text-center text-2xl uppercase">
              Complete {step}
            </div>
          )}
        </>
      )}
      <div className="flex flex-col items-center justify-between sm:border sm:border-terminal-green p-5 text-center gap-5 h-[400px] sm:h-[425px] 2xl:h-[500px]">
        <h4 className="m-0 uppercase text-3xl">Get Lords</h4>
        <Lords className="sm:hidden 2xl:block fill-current h-16" />
        {onMainnet ? (
          <p className="text-xl">
            We are on <span className="uppercase">{network}</span> so you are
            required to purchase LORDS from an exchange.
          </p>
        ) : (
          <p className="text-xl sm:text-base">
            We are on <span className="uppercase">{network}</span> so you can
            mint LORDS by clicking below.
          </p>
        )}
        <span
          className="flex items-center justify-center border border-terminal-green w-1/2 p-2 cursor-pointer"
          onClick={() => setSection("lords")}
        >
          <span className="flex flex-row items-center gap-2">
            <p className="uppercase">More Info</p>
            <span className="w-8">
              <InfoIcon />
            </span>
          </span>
        </span>
        <span className="w-3/4 h-10">
          <Button
            size={"fill"}
            onClick={async () => {
              if (onMainnet) {
                const avnuLords = `https://app.avnu.fi/en?tokenFrom=${indexAddress(
                  networkConfig[network!].ethAddress ?? ""
                )}&tokenTo=${indexAddress(
                  networkConfig[network!].lordsAddress ?? ""
                )}&amount=0.001`;
                window.open(avnuLords, "_blank");
              } else {
                setMintingLords(true);
                await mintLords(50);
                setMintingLords(false);
              }
            }}
          >
            {onMainnet ? "Buy LORDS" : "Mint LORDS"}
          </Button>
        </span>
      </div>
    </>
  );
};

export default LordsSection;
