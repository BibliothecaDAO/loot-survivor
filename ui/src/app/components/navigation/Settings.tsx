import VerticalKeyboardControl from "../menu//VerticalMenu";
import {
  CartIcon,
  MuteIcon,
  VolumeIcon,
  EncountersIcon,
  LedgerIcon,
} from "../icons/Icons";
import { GuideIcon } from "../icons/Icons";
import { ChatIcon } from "../icons/Icons";
import useUIStore from "../../hooks/useUIStore";
import { displayAddress } from "@/app/lib/utils";
import { useConnectors } from "@starknet-react/core";
import { useAccount } from "@starknet-react/core";
import { ButtonData } from "@/app/types";

export default function Settings() {
  const isMuted = useUIStore((state) => state.isMuted);
  const setIsMuted = useUIStore((state) => state.setIsMuted);
  const setScreen = useUIStore((state) => state.setScreen);
  const displayHistory = useUIStore((state) => state.displayHistory);
  const setDisplayHistory = useUIStore((state) => state.setDisplayHistory);
  const displayCart = useUIStore((state) => state.displayCart);
  const setDisplayCart = useUIStore((state) => state.setDisplayCart);
  const { disconnect } = useConnectors();
  const { account } = useAccount();

  const buttonsData: ButtonData[] = [
    {
      id: 1,
      label: "Ledger",
      icon: <LedgerIcon />,
      action: () => setDisplayHistory(!displayHistory),
    },
    // {
    //   id: 2,
    //   label: "Encounters",
    //   icon: <EncountersIcon />,
    //   action: () => setScreen("encounters"),
    // },
    // {
    //   id: 3,
    //   label: "Guide",
    //   icon: <GuideIcon />,
    //   action: () => setScreen("guide"),
    // },
    //   <Button
    //   onClick={() => {
    //     setIsMuted(!isMuted);
    //     clickPlay();
    //   }}
    //   className="hidden sm:block"
    // >
    //   <div className="flex items-center justify-center">
    //     {isMuted ? (
    //       <MuteIcon className="w-4 h-4 sm:w-6 sm:h-6" />
    //     ) : (
    //       <VolumeIcon className="w-4 h-4 sm:w-6 sm:h-6" />
    //     )}
    //   </div>
    // </Button>
    {
      id: 3,
      label: isMuted ? "Unmute" : "Mute",
      icon: isMuted ? (
        <VolumeIcon className="w-6 h-6" />
      ) : (
        <MuteIcon className="w-6 h-6" />
      ),
      action: () => setIsMuted(!isMuted),
    },
    {
      id: 4,
      label: "Discord",
      icon: <ChatIcon />,
      action: () => window.open("https://discord.gg/bibliothecadao", "_blank"),
    },
    {
      id: 5,
      label: displayAddress(account?.address ?? ""),
      action: () => disconnect(),
      variant: "default",
    },
  ];

  return (
    <div className="flex flex-row  flex-wrap">
      <div className="flex flex-col sm:w-1/3 m-auto my-4 w-full px-8">
        <VerticalKeyboardControl
          buttonsData={buttonsData}
          onSelected={(value) => null}
          onEnterAction={true}
        />
        {/* <a
          href="https://discord.gg/bibliothecadao"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Button>Discord</Button>
        </a> */}
      </div>
    </div>
  );
}
