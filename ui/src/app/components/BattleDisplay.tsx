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
