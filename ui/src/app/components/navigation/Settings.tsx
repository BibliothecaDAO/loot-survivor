import Menu from "@/app/components/menu/ButtonMenu";
import {
  SoundOnIcon,
  SoundOffIcon,
  LedgerIcon,
} from "@/app/components/icons/Icons";
import { DiscordIcon } from "@/app/components/icons/Icons";
import useUIStore from "@/app/hooks/useUIStore";
import { displayAddress } from "@/app/lib/utils";
import { useDisconnect } from "@starknet-react/core";
import { useAccount } from "@starknet-react/core";
import { ButtonData, NullAdventurer } from "@/app/types";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";

export default function Settings() {
  const isMuted = useUIStore((state) => state.isMuted);
  const setIsMuted = useUIStore((state) => state.setIsMuted);
  const displayHistory = useUIStore((state) => state.displayHistory);
  const setDisplayHistory = useUIStore((state) => state.setDisplayHistory);
  const setDisconnected = useUIStore((state) => state.setDisconnected);
  const { disconnect } = useDisconnect();
  const { account, isConnected } = useAccount();
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const { resetData } = useQueriesStore();

  const buttonsData: ButtonData[] = [
    {
      id: 1,
      label: "Play For Real",
      action: () => setDisconnected(false),
      disabled: true,
    },
    {
      id: 2,
      label: "Ledger",
      icon: <LedgerIcon />,
      action: () => setDisplayHistory(!displayHistory),
    },
    {
      id: 3,
      label: isMuted ? "Unmute" : "Mute",
      icon: isMuted ? (
        <SoundOnIcon className="fill-current" />
      ) : (
        <SoundOffIcon className="fill-current" />
      ),
      action: () => setIsMuted(!isMuted),
    },
    {
      id: 4,
      label: "Discord",
      icon: <DiscordIcon className="fill-current" />,
      action: () => window.open("https://discord.gg/realmsworld", "_blank"),
    },
    {
      id: 5,
      label: isConnected ? displayAddress(account?.address ?? "") : "Connect",
      action: () => {
        disconnect();
        resetData();
        setAdventurer(NullAdventurer);
        setDisconnected(true);
      },
      variant: "default",
    },
  ];

  return (
    <div className="flex flex-row  flex-wrap">
      <div className="flex flex-col sm:w-1/3 m-auto my-4 w-full px-8">
        <Menu
          buttonsData={buttonsData}
          onSelected={(value) => null}
          onEnterAction={true}
          className="flex-col"
        />
      </div>
    </div>
  );
}
