import { Battle, Discovery } from "@/app/types";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import {
  processBeastName,
  getBeastData,
  getRankFromList,
  getOrdinalSuffix,
} from "@/app/lib/utils";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import TwitterShareButton from "../buttons/TwitterShareButtons";
import { appUrl } from "@/app/lib/constants";

interface DeathDisplayProps {
  type: string;
  battleData: Battle[];
  discoveryData: Discovery[];
}

export const DeathDisplay = ({
  type,
  battleData,
  discoveryData,
}: DeathDisplayProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  // This can be element in the array as they all contain beast details
  const handleBeastInfo = () => {
    if (type === "battle") {
      const beastName = processBeastName(
        battleData[0]?.beast ?? "",
        battleData[0]?.special2 ?? "",
        battleData[0]?.special3 ?? ""
      );
      const beastLevel = battleData[0]?.beastLevel;
      const { tier, attack, armor, image } = getBeastData(
        battleData[0]?.beast ?? ""
      );
      return { beastName, beastLevel, tier };
    } else {
      const beastName = processBeastName(
        discoveryData[0]?.entity ?? "",
        discoveryData[0]?.special2 ?? "",
        discoveryData[0]?.special3 ?? ""
      );
      const beastLevel = discoveryData[0]?.entityLevel;
      const { tier, attack, armor, image } = getBeastData(
        discoveryData[0]?.entity ?? ""
      );
      return { beastName, beastLevel, tier };
    }
  };

  const { beastName, beastLevel, tier } = handleBeastInfo();
  const adventurersByXp = useQueriesStore(
    (state) => state.data.adventurersByXPQuery?.adventurers ?? []
  );
  const rank = getRankFromList(adventurer?.id ?? 0, adventurersByXp);
  const ordinalRank = getOrdinalSuffix(rank + 1 ?? 0);

  if (type === "battle") {
    const BeastFled = battleData.some((data) => data.fled);
    const FailedToFlee =
      battleData.some(
        (data) => data.attacker === "Adventurer" && data.damageDealt == 0
      ) && (battleData[0]?.adventurerHealth ?? 0) > 0;
    const KilledTryingToFlee =
      battleData.some(
        (data) => data.attacker === "Adventurer" && data.damageDealt == 0
      ) && (battleData[0]?.adventurerHealth ?? 0) == 0;
    const Attacked = battleData.some(
      (data) => data.attacker === "Beast" && (data.adventurerHealth ?? 0) > 0
    );
    const Slayed =
      battleData[0]?.attacker === "Adventurer" &&
      (battleData[0]?.beastHealth ?? 0) == 0;
    const KilledByBeast =
      battleData.some((data) => data.attacker === "Beast") &&
      adventurer?.health === 0;
    const IdleDamagePenalty =
      battleData.length == 1 &&
      !battleData[0].beast &&
      (battleData[0].adventurerHealth ?? 0) > 0;

    const KilledByIdlePenalty =
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
  } else if (type === "discovery") {
    const AdventurerHealthExists = (discoveryData?.adventurerHealth ?? 0) > 0;

    const renderDiscoveryMessage = () => {
      if (discoveryData?.discoveryType === "Beast") {
        if (discoveryData?.ambushed) {
          if (AdventurerHealthExists) {
            return (
              <span className="flex flex-row items-center justify-between">
                <p>YIKES! You were ambushed by a {beastName}</p>
                <GiBruteIcon />
              </span>
            );
          } else {
            return (
              <span className="flex flex-row items-center justify-between">
                <p>YIKES! You were killed from an ambush by a {beastName}</p>
                <SkullCrossedBonesIcon />
              </span>
            );
          }
        } else {
          return (
            <span className="flex flex-row items-center justify-between">
              <p>OH NO! You discovered a {beastName}!</p>
              <GiBruteIcon />
            </span>
          );
        }
      }

      if (discoveryData?.discoveryType === "Obstacle") {
        if (discoveryData?.dodgedObstacle) {
          return (
            <span className="flex flex-row items-center justify-between">
              <p>PHEW! You avoided the {discoveryData?.obstacle} obstacle!</p>
              <SpikedWallIcon />
            </span>
          );
        } else if (!AdventurerHealthExists) {
          return (
            <span className="flex flex-row items-center justify-between">
              <p>
                OUCH!{" "}
                {discoveryData?.obstacle?.endsWith("s")
                  ? `A ${discoveryData?.obstacle}`
                  : discoveryData?.obstacle}{" "}
                killed you with {discoveryData?.damageTaken} damage!
              </p>
              <SkullCrossedBonesIcon />
            </span>
          );
        } else {
          return (
            <span className="flex flex-row items-center justify-between">
              <p>
                OUCH!{" "}
                {discoveryData?.obstacle?.endsWith("s")
                  ? discoveryData?.obstacle
                  : `A ${discoveryData?.obstacle}`}{" "}
                inflicted {discoveryData?.damageTaken} damage!
              </p>
              <SpikedWallIcon />
            </span>
          );
        }
      }

      if (!discoveryData?.discoveryType) {
        if (!AdventurerHealthExists) {
          return (
            <span className="flex flex-row items-center justify-between">
              <p>OOPS! You were killed by the idle penalty of 80 damage!</p>
              <GiSandsOfTimeIcon />
            </span>
          );
        } else {
          return (
            <span className="flex flex-row items-center justify-between">
              <p>OOPS! You recieved the idle penalty of 80 damage!</p>
              <GiSandsOfTimeIcon />
            </span>
          );
        }
      }

      if (discoveryData?.discoveryType === "Item") {
        if (discoveryData?.subDiscoveryType === "Gold") {
          return (
            <span className="flex flex-row items-center justify-between">
              <div className="flex flex-row gap-1 self-center items-center text-terminal-yellow">
                <p className="text-terminal-green">NICE! You discovered </p>
                <span className="flex flex-row items-center">
                  <CoinIcon className="mt-1 self-center w-5 h-5 fill-current" />
                  <span className="text-terminal-yellow">
                    {discoveryData?.outputAmount}
                  </span>{" "}
                </span>
              </div>
              <TwoCoinIcon />
            </span>
          );
        }

        if (discoveryData?.subDiscoveryType === "Health") {
          return (
            <span className="flex flex-row items-center justify-between">
              <div className="flex self-center">
                <p>
                  GREAT! You discovered {discoveryData?.outputAmount} health!{" "}
                </p>
                <HeartIcon className="mt-1 self-center w-5 h-5 fill-current" />
              </div>
              <HealthPotionIcon />
            </span>
          );
        }

        if (discoveryData?.subDiscoveryType === "XP") {
          return (
            <span className="flex flex-row items-center justify-between">
              <p>NICE! You discovered {discoveryData.outputAmount} XP!</p>
              <GiStarsStackIcon />
            </span>
          );
        }
      }

      return null;
    };

    return renderDiscoveryMessage();
  }
};
