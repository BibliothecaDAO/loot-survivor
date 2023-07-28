import TwitterShareButton from "../buttons/TwitterShareButtons";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import { useQueriesStore } from "../../hooks/useQueryStore";
import { getRankFromList, getOrdinalSuffix } from "../../lib/utils";
import { processBeastName, getBeastData } from "../../lib/utils";
import { Adventurer, Battle, Discovery } from "@/app/types";
import Head from "../../../../public/icons/loot/head.svg";
import Hand from "../../../../public/icons/loot/hand.svg";
import Chest from "../../../../public/icons/loot/chest.svg";
import Waist from "../../../../public/icons/loot/waist.svg";
import Foot from "../../../../public/icons/loot/foot.svg";
import { appUrl, battle } from "@/app/lib/constants";

interface BattleDisplayProps {
  battleData: Battle;
  beastName: string;
}

const getAttackLocationIcon = (attackLocation: string) => {
  if (!attackLocation) return null;

  if (attackLocation == "Hand")
    return <Hand className="self-center w-6 h-6 fill-current" />;
  if (attackLocation == "Chest")
    return <Chest className="self-center w-6 h-6 fill-current" />;
  if (attackLocation == "Waist")
    return <Waist className="self-center w-6 h-6 fill-current" />;
  if (attackLocation == "Foot")
    return <Foot className="self-center w-6 h-6 fill-current" />;
  if (attackLocation == "Head")
    return <Head className="self-center w-6 h-6 fill-current" />;
};

/**
 * @component
 * @description Displays the battle results.
 */
export const BattleDisplay = ({
  battleData,
  beastName,
}: BattleDisplayProps) => {
  const damageLocation = battleData?.damageLocation ?? "";
  const damageIcon = getAttackLocationIcon(damageLocation);
  const BeastFled = battleData.fled;
  const AdventurerAttack = battleData.attacker === "Adventurer";
  const BeastAttack = battleData.attacker === "Beast";
  const BeastHealthExists = (battleData.beastHealth ?? 0) > 0;
  const AdventurerHealthExists = (battleData.adventurerHealth ?? 0) > 0;
  const NoDamageDealt = battleData.damageDealt === 0;
  const NoDamageTaken = battleData.damageTaken === 0;
  const IdleDamagePenalty = !battleData.beast;
  const CriticalHit = battleData.criticalHit;

  const renderDiscoveryMessage = () => {
    if (BeastFled) {
      return <p>PHEW! You fled the {beastName}!</p>;
    }

    if (AdventurerAttack && NoDamageDealt && NoDamageTaken && !BeastFled) {
      return <p>OH NO! You could not flee the {beastName}!</p>;
    }

    if (AdventurerAttack && BeastHealthExists && !NoDamageDealt) {
      return (
        <p className="w-full justify-between text-terminal-yellow">
          NICE! You attacked the {beastName} for {battleData?.damageDealt}{" "}
          damage{CriticalHit && ", a critical hit"}!
        </p>
      );
    }

    if (AdventurerAttack && !BeastHealthExists && !BeastFled) {
      return (
        <p className="w-full justify-between">
          GREAT! You defeated the {beastName} with a final blow of{" "}
          {battleData?.damageDealt} damage{CriticalHit && ", a critical hit"}!
        </p>
      );
    }

    if (BeastAttack && AdventurerHealthExists) {
      return (
        <p>
          OUCH! The {beastName} attacked your {damageLocation}, dealing{" "}
          {battleData?.damageTaken} damage{CriticalHit && ", a critical hit"}!
        </p>
      );
    }

    if (BeastAttack && !AdventurerHealthExists) {
      return (
        <p>
          YIKES! You were killed by the {beastName} as it dealt{" "}
          {battleData?.damageTaken} damage to your {damageLocation}
          {CriticalHit && ", a critical hit"}!
        </p>
      );
    }

    if (BeastAttack && AdventurerHealthExists && NoDamageTaken) {
      return <p>PHEW! The {beastName} attacked but you defended it well!</p>;
    }

    if (IdleDamagePenalty) {
      return <p>OOPS! You were hit for 80 damage from idle penalty!</p>;
    }
  };

  return (
    <div className="w-full text-sm sm:text-xl">{renderDiscoveryMessage()}</div>
  );
};

interface NotificationBattleDisplayProps {
  battleData: Battle[] | Battle;
  type: string;
}

export const NotificationBattleDisplay = ({
  battleData,
  type,
}: NotificationBattleDisplayProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);

  const isArray = Array.isArray(battleData);
  const handleBeastInfo = () => {
    if (isArray) {
      const beastName = processBeastName(
        battleData[0]?.beast ?? "",
        battleData[0]?.special2 ?? "",
        battleData[0]?.special3 ?? ""
      );
      const beastLevel = battleData[0]?.beastLevel;
      const { tier, attack, armor, image } = getBeastData(
        battleData[0]?.beast ?? ""
      );
      return { beastName, beastLevel, tier, attack, armor, image };
    } else {
      const beastName = processBeastName(
        battleData?.beast ?? "",
        battleData?.special2 ?? "",
        battleData?.special3 ?? ""
      );
      const beastLevel = battleData?.beastLevel;
      const { tier, attack, armor, image } = getBeastData(
        battleData?.beast ?? ""
      );
      return { beastName, beastLevel, tier, attack, armor, image };
    }
  };

  console.log(battleData);

  const { beastName, beastLevel, tier } = handleBeastInfo();
  const { data } = useQueriesStore();
  const rank = getRankFromList(
    adventurer?.id ?? 0,
    data.adventurersByXPQuery?.adventurers ?? []
  );
  const ordinalRank = getOrdinalSuffix(rank + 1 ?? 0);

  const BeastFled = isArray && battleData.some((data) => data.fled);
  const FailedToFlee =
    isArray &&
    battleData.some(
      (data) => data.attacker === "Adventurer" && data.damageDealt == 0
    ) &&
    (battleData[0]?.adventurerHealth ?? 0) > 0;
  const KilledTryingToFlee =
    isArray &&
    battleData.some(
      (data) => data.attacker === "Adventurer" && data.damageDealt == 0
    ) &&
    (battleData[0]?.adventurerHealth ?? 0) == 0;
  const Attacked =
    isArray &&
    battleData.some(
      (data) => data.attacker === "Beast" && (data.adventurerHealth ?? 0) > 0
    );
  const Slayed =
    isArray &&
    battleData.length == 1 &&
    battleData[0]?.attacker === "Adventurer" &&
    (battleData[0]?.beastHealth ?? 0) == 0;
  const KilledByBeast =
    isArray &&
    battleData.some((data) => data.attacker === "Beast") &&
    adventurer?.health === 0;
  const IdleDamagePenalty =
    isArray &&
    battleData.length == 1 &&
    !battleData[0].beast &&
    (battleData[0].adventurerHealth ?? 0) > 0;

  const KilledByIdlePenalty =
    isArray &&
    battleData.length == 1 &&
    !battleData[0].beast &&
    (battleData[0].adventurerHealth ?? 0) == 0;

  const renderBattleNotification = () => {
    if (BeastFled) {
      return <p>You fled the {beastName || ""}!</p>;
    } else if (FailedToFlee) {
      return (
        <p>
          You failed to flee the {beastName || ""} and were attacked taking{" "}
          {battleData[0]?.damageTaken} damage
          {battleData[0]?.criticalHit && ", a critical hit"}!
        </p>
      );
    } else if (KilledTryingToFlee) {
      return (
        <p>
          You were killed trying to flee the {beastName || ""} taking{" "}
          {battleData[0]?.damageTaken} damage
          {battleData[0]?.criticalHit && ", a critical hit"}!
        </p>
      );
    } else if (Attacked) {
      return (
        <p>
          You attacked the {beastName || ""} with{" "}
          {battleData[1]?.criticalHit && "a critical hit"} and dealt{" "}
          {battleData[1]?.damageDealt} damage! They counterattacked for{" "}
          {battleData[0]?.damageTaken} damage
          {battleData[0]?.criticalHit && ", a critical hit"}!
        </p>
      );
    } else if (KilledByBeast) {
      return (
        <p>
          With a last breath you strike the {beastName || ""} with{" "}
          {battleData[1]?.criticalHit && "a critical hit of "}
          {battleData[1]?.damageDealt} damage! However, they finish you with{" "}
          {battleData[0]?.damageTaken} damage
          {battleData[0]?.criticalHit && ", a critical hit"}!
        </p>
      );
    } else if (Slayed) {
      return (
        <div className="flex flex-col gap-2 items-center justify-center">
          <p>
            You slayed the {beastName || ""} after inflicting{" "}
            {battleData[0]?.criticalHit && "a critical hit of "}
            {battleData[0]?.damageDealt} damage!
          </p>
          <TwitterShareButton
            text={`My adventurer just slew a level ${beastLevel} ${beastName} (Tier ${tier}) on #LootSurvivor.\n\n${adventurer?.name} is currently ${ordinalRank} place on the leaderboard.\n\nThink you can out-survive me?\n\nEnter here and try to survive: ${appUrl}\n\n@lootrealms #Starknet #Play2Die #LootSurvivor`}
          />
        </div>
      );
    } else if (IdleDamagePenalty) {
      return <p>You were hit for 80 damage from idle penalty!</p>;
    } else if (KilledByIdlePenalty) {
      return <p>You were killed from 80 damage by the idle penalty!</p>;
    }
  };
  return <div>{renderBattleNotification()}</div>;
};
