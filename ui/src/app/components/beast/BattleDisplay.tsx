import TwitterShareButton from "../buttons/TwitterShareButtons";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import { useQueriesStore } from "../../hooks/useQueryStore";
import { getRankFromList, getOrdinalSuffix } from "../../lib/utils";
import { processBeastName, getBeastData } from "../../lib/utils";
import { Adventurer, Battle } from "@/app/types";
import Head from "../../../../public/icons/loot/head.svg";
import Hand from "../../../../public/icons/loot/hand.svg";
import Chest from "../../../../public/icons/loot/chest.svg";
import Waist from "../../../../public/icons/loot/waist.svg";
import Foot from "../../../../public/icons/loot/foot.svg";

interface BattleDisplayProps {
  adventurer: Adventurer;
  battleData: Battle;
  beastName: string;
}

const getAttackLocationIcon = (attackLocation: string) => {
  if (!attackLocation) return null;

  if (attackLocation == "Hands")
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
  adventurer,
  battleData,
  beastName,
}: BattleDisplayProps) => {
  const damageLocation = battleData?.damageLocation ?? "";
  return (
    <div>
      {battleData.attacker == "Adventurer" ? (
        battleData.beastHealth ?? 0 > 0 ? (
          <p>
            You attacked the {beastName} with a mighty strike and dealt{" "}
            {battleData.damageDealt} damage!
          </p>
        ) : battleData.fled ? (
          <p>You fled the {beastName}!</p>
        ) : (
          <p>
            You slayed the {beastName} after inflicting {battleData.damageDealt}{" "}
            damage!
          </p>
        )
      ) : adventurer.health ?? 0 > 0 ? (
        battleData.damageTaken == 0 ? (
          <p>
            The {beastName} attacked your{" "}
            {getAttackLocationIcon(damageLocation)} but you defended the attack!
          </p>
        ) : (
          <p>
            The {beastName} attacked your{" "}
            {getAttackLocationIcon(damageLocation)} doing
            {battleData.damageTaken} damage!
          </p>
        )
      ) : (
        <p>
          The {beastName} killed you {battleData.damageTaken} damage to your{" "}
          {getAttackLocationIcon(damageLocation)}!
        </p>
      )}
    </div>
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
  const appUrl = "https://loot-survivor.vercel.app/";
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

  const { beastName, beastLevel, tier } = handleBeastInfo();
  const { data } = useQueriesStore();
  const rank = getRankFromList(
    adventurer?.id ?? 0,
    data.adventurersByXPQuery?.adventurers ?? []
  );
  const ordinalRank = getOrdinalSuffix(rank + 1 ?? 0);
  return (
    <div>
      {isArray && battleData.some((data) => data.fled) ? (
        <p>You fled the {beastName ? beastName : ""}!</p>
      ) : isArray &&
        type == "Flee" &&
        battleData.length == 1 &&
        battleData[0]?.attacker == "Beast" &&
        (battleData[0]?.beastHealth ?? 0) > 0 ? (
        <p>
          You failed to flee the {beastName ? beastName : ""} and were attacked
          taking {battleData[0]?.damageTaken} damage!{" "}
        </p>
      ) : isArray &&
        type == "Flee" &&
        battleData.length == 1 &&
        battleData[0]?.attacker == "Beast" &&
        adventurer?.health == 0 ? (
        <p>
          You were killed trying to flee the {beastName ? beastName : ""}
          taking {battleData[0]?.damageTaken} damage!{" "}
        </p>
      ) : (
        isArray &&
        battleData[0]?.attacker == "Adventurer" &&
        ((battleData[0]?.beastHealth ?? 0) > 0 &&
        (battleData[1]?.beastHealth ?? 0) > 0 ? (
          <p>
            You attacked the {beastName ? beastName : ""} with a mighty strike
            and dealt {battleData[0]?.damageDealt} damage! They counterattacked
            for {battleData[1]?.damageTaken} damage!
          </p>
        ) : battleData[0]?.attacker == "Adventurer" &&
          battleData[0]?.beastHealth == 0 ? (
          <div className="flex flex-col gap-2 items-center justify-center">
            <p>
              You slayed the {beastName ? beastName : ""} after inflicting{" "}
              {battleData[0]?.damageDealt} damage!
            </p>
            <TwitterShareButton
              text={`My adventurer just slew a level ${beastLevel} ${beastName} (Tier ${tier}) on #LootSurvivor.\n\n${adventurer?.name} is currently ${ordinalRank} place on the leaderboard.\n\nThink you can out-survive me?\n\nEnter here and try to survive: ${appUrl}\n\n@lootrealms #Starknet #Play2Die #LootSurvivor`}
            />
          </div>
        ) : (
          <p>
            You were killed by the {beastName ? beastName : ""} taking{" "}
            {battleData[1]?.damageTaken} damage!
          </p>
        ))
      )}
    </div>
  );
};
