interface BattleDisplayProps {
  battleData: any;
  beastName: string;
}

export const BattleDisplay = ({
  battleData,
  beastName,
}: BattleDisplayProps) => {
  console.log(beastName);
  return (
    <>
      {battleData.attacker == "Adventurer" ? (
        battleData.targetHealth > 0 ? (
          <p>
            You attacked the {beastName} for {battleData.damage} damage
          </p>
        ) : battleData.fled ? (
          <p>You fled the {beastName}</p>
        ) : (
          <p>
            You killed the {beastName} after inflicting {battleData.damage}
          </p>
        )
      ) : battleData.targetHealth > 0 ? (
        battleData.ambushed ? (
          <p>
            You were ambushed by the {beastName} taking {battleData.damage}{" "}
            damage
          </p>
        ) : (
          <p>
            Counter attacked by the {beastName} taking {battleData.damage}{" "}
            damage
          </p>
        )
      ) : (
        <p>
          You were killed by the {beastName} taking {battleData.damage} damage!
        </p>
      )}
    </>
  );
};
