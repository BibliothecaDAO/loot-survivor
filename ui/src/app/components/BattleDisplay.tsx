import TwitterShareButton from "./TwitterShareButtons";
import useAdventurerStore from "../hooks/useAdventurerStore";

interface BattleDisplayProps {
  battleData: any;
  beastName: string;
}

export const BattleDisplay = ({
  battleData,
  beastName,
}: BattleDisplayProps) => {
  return (
    <div>
      {battleData.attacker == "Adventurer" ? (
        battleData.targetHealth > 0 ? (
          <p>
            You attacked the {beastName} with a mighty strike and dealt{" "}
            {battleData.damage} damage!
          </p>
        ) : battleData.fled ? (
          <p>You fled the {beastName}!</p>
        ) : (
          <p>
            You slayed the {beastName} after inflicting {battleData.damage}{" "}
            damage!
          </p>
        )
      ) : battleData.targetHealth > 0 ? (
        battleData.ambushed ? (
          <p>
            You were ambushed by the {beastName} taking {battleData.damage}{" "}
            damage!
          </p>
        ) : (
          <p>
            You were counter attacked by the {beastName} taking{" "}
            {battleData.damage} damage!
          </p>
        )
      ) : (
        <p>
          You were killed by the {beastName} taking {battleData.damage} damage!
        </p>
      )}
    </div>
  );
};

interface NotificationBattleDisplayProps {
  battleData: any;
  beastName: string;
}

export const NotificationBattleDisplay = ({
  battleData,
  beastName,
}: NotificationBattleDisplayProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const appUrl = "https://loot-survivor.vercel.app/";
  return (
    <div>
      {Array.isArray(battleData) &&
      battleData.some((data) => data.fled) &&
      battleData.some((data) => data.ambushed) ? (
        <p>
          You fled the {beastName ? beastName : ""}! But were ambushed before
          taking {battleData[0].damage} damage!
        </p>
      ) : Array.isArray(battleData) &&
        battleData.some((data) => data.ambushed) ? (
        <p>
          You couldn&apos;t flee and were ambushed by the{" "}
          {beastName ? beastName : ""} taking {battleData[0].damage} damage!
        </p>
      ) : Array.isArray(battleData) && battleData.some((data) => data.fled) ? (
        <p>You fled the {beastName ? beastName : ""}!</p>
      ) : (
        battleData[0]?.attacker == "Adventurer" &&
        (battleData[0]?.targetHealth > 0 && battleData[1]?.targetHealth > 0 ? (
          <p>
            You attacked the {beastName ? beastName : ""} with a mighty strike
            and dealt {battleData[0]?.damage} damage! They counterattacked for{" "}
            {battleData[1]?.damage} damage!
          </p>
        ) : battleData[0]?.targetHealth == 0 ? (
          <div className="flex flex-col gap-2 items-center justify-center">
            <p>
              You slayed the {beastName ? beastName : ""} after inflicting{" "}
              {battleData[0]?.damage} damage!
            </p>
            <TwitterShareButton
              text={`I have slain a ${beastName} with the adventurer ${adventurer?.name}.\n\nEnter here and try to survive: ${appUrl}\n\n@lootrealms #Starknet #Loot`}
            />
          </div>
        ) : (
          <p>
            You were killed by the {beastName ? beastName : ""} taking{" "}
            {battleData[1]?.damage} damage!
          </p>
        ))
      )}
    </div>
  );
};
