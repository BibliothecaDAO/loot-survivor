import { Button } from "@/app/components/buttons/Button";
import { MdClose } from "react-icons/md";
import { InfoIcon } from "@/app/components/icons/Icons";
import { Section } from "@/app/containers/Onboarding";

interface InfoBoxProps {
  section: Section | undefined;
  setSection: (section: Section | undefined) => void;
  lordsGameCost: number;
}

const InfoBox = ({ section, setSection, lordsGameCost }: InfoBoxProps) => {
  return (
    <div className="fixed w-full sm:w-1/2 h-1/2 top-1/4 bg-terminal-black border border-terminal-green flex flex-col items-center p-10 z-30">
      <button
        className="absolute top-2 right-2 cursor-pointer text-terminal-green"
        onClick={() => {
          setSection(undefined);
        }}
      >
        <MdClose size={50} />
      </button>
      <span className="w-10">
        <InfoIcon />
      </span>
      {sectionInfo(section!)}
    </div>
  );
};

export default InfoBox;

const openInNewTab = (url: string) => {
  const newWindow = window.open(url, "_blank", "noopener,noreferrer");
  if (newWindow) newWindow.opener = null;
};

const sectionInfo = (section: Section) => {
  switch (section) {
    case "connect":
      return (
        <div className="flex flex-col gap-10 items-center text-center text-xl">
          <p>
            Starknet is an non-EVM Ethereum L2 that supports seperate wallets.
          </p>
          <p>Please install a wallet from the list below:</p>
          <div className="flex flex-row my-2">
            <Button
              size={"lg"}
              onClick={() => openInNewTab("https://braavos.app/")}
              className="m-2"
            >
              Get Braavos
            </Button>
            <Button
              size={"lg"}
              onClick={() => openInNewTab("https://www.argent.xyz/argent-x/")}
              className="m-2"
            >
              Get ArgentX
            </Button>
          </div>
        </div>
      );
    case "eth":
      return (
        <div className="flex flex-col gap-10 items-center text-center text-lg">
          <p>
            ETH is required to pay gas for transactions on the Starknet network.
          </p>
          <p>This step will complete once you have at least 0.001 ETH.</p>
        </div>
      );
    case "lords":
      return (
        <div className="flex flex-col items-center gap-5 justify-between text-center text-lg">
          <p>LORDS is the native token of LOOT SURVIVOR & Realms.World.</p>
          <p>
            You will be required to enter LORDS to play at the price calculated
            from the games demand.
          </p>
        </div>
      );
    default:
      return "Default content for unknown section";
  }
};
