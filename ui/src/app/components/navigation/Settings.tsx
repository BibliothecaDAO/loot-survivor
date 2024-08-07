import Menu from "@/app/components/menu/ButtonMenu";
import {
  SoundOnIcon,
  SoundOffIcon,
  LedgerIcon,
} from "@/app/components/icons/Icons";
import { DiscordIcon } from "@/app/components/icons/Icons";
import useUIStore from "@/app/hooks/useUIStore";
import { ButtonData } from "@/app/types";

export default function Settings() {
  const isMuted = useUIStore((state) => state.isMuted);
  const setIsMuted = useUIStore((state) => state.setIsMuted);
  const displayHistory = useUIStore((state) => state.displayHistory);
  const setDisplayHistory = useUIStore((state) => state.setDisplayHistory);
  const setDisconnected = useUIStore((state) => state.setDisconnected);

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
        <SoundOffIcon className="fill-current" />
      ) : (
        <SoundOnIcon className="fill-current" />
      ),
      action: () => setIsMuted(!isMuted),
    },
    {
      id: 4,
      label: "Discord",
      icon: <DiscordIcon className="fill-current" />,
      action: () => window.open("https://discord.gg/realmsworld", "_blank"),
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
