import VerticalKeyboardControl from "./VerticalMenu";
import { EncountersIcon, LedgerIcon } from "./Icons";
import { GuideIcon } from "./Icons";
import { ChatIcon } from "./Icons";
import useUIStore from "../hooks/useUIStore";
import { Button } from "./buttons/Button";

export default function Settings() {
  const setScreen = useUIStore((state) => state.setScreen);
  const displayHistory = useUIStore((state) => state.displayHistory);
  const setDisplayHistory = useUIStore((state) => state.setDisplayHistory);
  const buttonsData = [
    {
      id: 1,
      label: "Ledger",
      icon: <LedgerIcon />,
      action: () => setDisplayHistory(!displayHistory),
    },
    {
      id: 2,
      label: "Encounters",
      icon: <EncountersIcon />,
      action: () => setScreen("encounters"),
    },
    {
      id: 3,
      label: "Guide",
      icon: <GuideIcon />,
      action: () => setScreen("guide"),
    },
    {
      id: 4,
      label: "Discord",
      icon: <ChatIcon />,
      action: () => window.open("https://discord.gg/bibliothecadao", "_blank"),
    },
  ];
  return (
    <div className="flex flex-row overflow-hidden flex-wrap">
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
