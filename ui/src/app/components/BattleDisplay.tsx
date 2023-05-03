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
  battleData: any[];
  beastName: string;
}

export const NotificationBattleDisplay = ({
  battleData,
  beastName,
}: NotificationBattleDisplayProps) => {
  return (
    <div>
      {Array.isArray(battleData) &&
      battleData.some((data) => {
        data.fled;
      }) &&
      battleData.some((data) => {
        data.ambushed;
      }) ? (
        <p>
          You fled the {beastName}! But were ambushed before taking{" "}
          {battleData[0].damage} damage!
        </p>
      ) : Array.isArray(battleData) &&
        battleData.some((data) => {
          data.ambushed;
        }) ? (
        <p>
          You couldn't flee and were ambushed by the {beastName} taking{" "}
          {battleData[0].damage} damage!
        </p>
      ) : Array.isArray(battleData) &&
        battleData.some((data) => {
          data.fled;
        }) ? (
        <p>You fled the {beastName}!</p>
      ) : battleData[1].attacker == "Adventurer" ? (
        battleData[1].targetHealth > 0 && battleData[0].targetHealth > 0 ? (
          <p>
            You attacked the {beastName} with a mighty strike and dealt{" "}
            {battleData[1].damage} damage! They counterattacked for{" "}
            {battleData[0].damage} damage!
          </p>
        ) : (
          <p>
            You were killed by the {beastName} taking {battleData[0].damage}{" "}
            damage!
          </p>
        )
      ) : (
        <p>
          You slayed the {beastName} after inflicting {battleData[1].damage}{" "}
          damage!
        </p>
      )}
    </div>
  );
};
