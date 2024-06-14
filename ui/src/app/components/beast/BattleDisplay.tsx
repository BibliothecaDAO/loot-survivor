import TwitterShareButton from "@/app/components/buttons/TwitterShareButtons";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { processBeastName, getBeastData } from "@/app/lib/utils";
import { Battle } from "@/app/types";
import {
  GiWalkingBootIcon,
  GiFootTripIcon,
  GiBattleGearIcon,
  SkullCrossedBonesIcon,
} from "@/app/components/icons/Icons";
import useUIStore from "@/app/hooks/useUIStore";
import { networkConfig } from "@/app/lib/networkConfig";

interface BattleDisplayProps {
  battleData: Battle;
  beastName: string;
}

/**
 * @component
 * @description Displays the battle results.
 */
export const BattleDisplay = ({
  battleData,
  beastName,
}: BattleDisplayProps) => {
  const damageLocation = battleData?.damageLocation ?? "";
  const BeastFled = battleData.fled;
  const AdventurerAttack = battleData.attacker === "Adventurer";
  const BeastAttack = battleData.attacker === "Beast";
  const BeastHealthExists = (battleData.beastHealth ?? 0) > 0;
  const AdventurerHealthExists = (battleData.adventurerHealth ?? 0) > 0;
  const NoDamageDealt = battleData.damageDealt === 0;
  const NoDamageTaken = battleData.damageTaken === 0;
  const CriticalHit = battleData.criticalHit;

  const renderDiscoveryMessage = () => {
    if (BeastFled) {
      return (
        <span className="flex flex-row items-center justify-between">
          <p>PHEW! Fled the {beastName}!</p>
          <GiWalkingBootIcon />
        </span>
      );
    }

    if (AdventurerAttack && NoDamageDealt && NoDamageTaken && !BeastFled) {
      return (
        <span className="flex flex-row items-center justify-between">
          <p>OH NO! Failed to flee the {beastName}!</p>
          <GiFootTripIcon />
        </span>
      );
    }

    if (AdventurerAttack && BeastHealthExists && !NoDamageDealt) {
      return (
        <span className="flex flex-row items-center justify-between">
          <p className="w-full justify-between text-terminal-yellow">
            NICE! Attacked the {beastName} for {battleData?.damageDealt} damage
            {CriticalHit && (
              <>
                , a <span className="text-terminal-yellow">critical hit</span>
              </>
            )}
            !
          </p>
          <GiBattleGearIcon />
        </span>
      );
    }

    if (AdventurerAttack && !BeastHealthExists && !BeastFled) {
      return (
        <span className="flex flex-row items-center justify-between">
          <p className="w-full justify-between">
            GREAT! Slayed the {beastName} with {battleData?.damageDealt} damage
            {CriticalHit && (
              <>
                , a <span className="text-terminal-yellow">critical hit</span>
              </>
            )}
            !
          </p>
          <GiBattleGearIcon />
        </span>
      );
    }

    if (BeastAttack && AdventurerHealthExists) {
      return (
        <span className="flex flex-row items-center justify-between">
          <p>
            OUCH! The {beastName} dealt {battleData?.damageTaken} damage to{" "}
            {damageLocation}
            {CriticalHit && (
              <>
                , a <span className="text-terminal-yellow">critical hit</span>
              </>
            )}
            !
          </p>
          <GiBattleGearIcon />
        </span>
      );
    }

    if (BeastAttack && !AdventurerHealthExists) {
      return (
        <span className="flex flex-row items-center justify-between">
          <p>
            Killed by the {beastName} taking {""}
            {battleData?.damageTaken} damage to {damageLocation}
            {CriticalHit && (
              <>
                , a <span className="text-terminal-yellow">critical hit</span>
              </>
            )}
            !
          </p>
          <SkullCrossedBonesIcon />
        </span>
      );
    }

    if (BeastAttack && AdventurerHealthExists && NoDamageTaken) {
      return (
        <span className="flex flex-row items-center justify-between">
          <p>PHEW! Defended the {beastName} attack!</p>
          <GiBattleGearIcon />
        </span>
      );
    }
  };

  return (
    <div className="w-full text-sm sm:text-xl">{renderDiscoveryMessage()}</div>
  );
};

interface NotificationBattleDisplayProps {
  battleData: Battle[] | Battle;
}

export const NotificationBattleDisplay = ({
  battleData,
}: NotificationBattleDisplayProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const network = useUIStore((state) => state.network);

  const isArray = Array.isArray(battleData);
  const handleBeastInfo = () => {
    if (isArray) {
      // This can be element in the array as they all contain beast details
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

  const { beastName, beastLevel, tier } = handleBeastInfo();
  const BeastFled = isArray && battleData.some((data) => data.fled);
  const FailedToFlee =
    isArray &&
    battleData.some(
      (data) => data.attacker === "Adventurer" && data.damageDealt == 0
    ) &&
    (battleData[1]?.adventurerHealth ?? 0) > 0;
  const KilledTryingToFlee =
    isArray &&
    battleData.some(
      (data) => data.attacker === "Adventurer" && data.damageDealt == 0
    ) &&
    (battleData[1]?.adventurerHealth ?? 0) == 0;
  const Attacked =
    isArray &&
    battleData.some(
      (data) => data.attacker === "Beast" && (data.adventurerHealth ?? 0) > 0
    ) &&
    battleData.some((data) => data.attacker === "Adventurer");
  const AttackedFromEquipping =
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
    battleData.some(
      (data) => data.attacker === "Beast" && (data.adventurerHealth ?? 0) === 0
    );

  const renderBattleNotification = () => {
    if (BeastFled) {
      return (
        <span className="flex flex-row items-center justify-between w-full">
          <p>Fled the {beastName || ""}!</p>
          <GiWalkingBootIcon />
        </span>
      );
    } else if (FailedToFlee) {
      return (
        <span className="flex flex-row items-center justify-between w-full">
          <span className="flex flex-col gap-1">
            <p>Failed to flee the {beastName || ""}.</p>
            <p>
              {beastName || ""} dealt {battleData[1]?.damageTaken} damage to{" "}
              {battleData[1].damageLocation}
              {battleData[1]?.criticalHit && (
                <>
                  , a <span className="text-terminal-yellow">critical hit</span>
                </>
              )}
              !
            </p>
          </span>
          <GiFootTripIcon />
        </span>
      );
    } else if (KilledTryingToFlee) {
      return (
        <span className="flex flex-row items-center justify-between w-full">
          <span className="flex flex-col gap-1">
            <p>
              Killed by the {beastName || ""} from {battleData[1]?.damageTaken}{" "}
              damage to {battleData[1]?.damageLocation}
              {battleData[1]?.criticalHit && (
                <>
                  , a <span className="text-terminal-yellow">critical hit</span>
                </>
              )}
              !
            </p>
          </span>
          <SkullCrossedBonesIcon />
        </span>
      );
    } else if (Attacked) {
      return (
        <span className="flex flex-row items-center justify-between w-full">
          <span className="flex flex-col gap-1">
            <p>
              Attacked the {beastName || ""} for {battleData[0]?.damageDealt}{" "}
              damage
              {battleData[0]?.criticalHit && (
                <>
                  , a <span className="text-terminal-yellow">critical hit</span>
                </>
              )}
              !
            </p>
            <p>
              {beastName || ""} counterattacked for {battleData[1]?.damageTaken}{" "}
              damage to {battleData[1]?.damageLocation}
              {battleData[1]?.criticalHit && ", a critical hit"}!
            </p>
          </span>
          <GiBattleGearIcon />
        </span>
      );
    } else if (AttackedFromEquipping) {
      return (
        <span className="flex flex-row items-center justify-between w-full">
          <p>
            {beastName || ""} attacked for {battleData[0]?.damageTaken} damage
            to {battleData[0]?.damageLocation} from swapping item
            {battleData[0]?.criticalHit && ", a critical hit"}!
          </p>
          ;
          <GiBattleGearIcon />
        </span>
      );
    } else if (KilledByBeast) {
      return (
        <span className="flex flex-row items-center justify-between w-full">
          <span className="flex flex-col gap-1">
            <p>
              Killed by the {beastName || ""} taking {""}
              {battleData[1]?.damageTaken} damage to{" "}
              {battleData[1]?.damageLocation}
              {battleData[0]?.criticalHit && (
                <>
                  , a <span className="text-terminal-yellow">critical hit</span>
                </>
              )}
              !
            </p>
          </span>
          <SkullCrossedBonesIcon />
        </span>
      );
    } else if (Slayed) {
      return (
        <div className="flex flex-col gap-2 items-center justify-center w-full">
          <span className="flex flex-row items-center justify-between">
            <p>
              Slayed the {beastName || ""} for {battleData[0]?.damageDealt}{" "}
              damage
              {battleData[0]?.criticalHit && (
                <>
                  , a <span className="text-terminal-yellow">critical hit</span>
                </>
              )}
              !
            </p>
            <GiBattleGearIcon />
          </span>
          <TwitterShareButton
            text={`${
              adventurer?.name
            } just slew a level ${beastLevel} ${beastName} (Tier ${tier}) on #LootSurvivor.\n\nThink you can out-survive me?\n\nEnter here and try to survive: ${
              networkConfig[network!].appUrl
            }\n\n@lootrealms #Starknet #Play2Die #🪦`}
            className="animate-pulse"
          />
        </div>
      );
    }
  };
  return (
    <div className="flex flex-row items-center">
      {renderBattleNotification()}
    </div>
  );
};
