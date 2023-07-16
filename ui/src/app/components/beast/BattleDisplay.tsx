import TwitterShareButton from "../buttons/TwitterShareButtons";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import { useQueriesStore } from "../../hooks/useQueryStore";
import { getRankFromList, getOrdinalSuffix } from "../../lib/utils";
import { processBeastName } from "../../lib/utils";

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
          battleData.damage == 0 ? (
            <p>You were ambushed by the {beastName} but managed to avoid it!</p>
          ) : (
            <p>
              You were ambushed by the {beastName} taking {battleData.damage}{" "}
              damage!
            </p>
          )
        ) : battleData.damage == 0 ? (
          <p>
            You were counter attacked by the {beastName} but defended the
            attack!
          </p>
        ) : (
          <p>
            You were counter attacked by the {beastName} taking{" "}
            {battleData.damage} damage!
          </p>
        )
      ) : battleData.ambushed ? (
        <p>
          You were killed by the {beastName} from an ambush taking{" "}
          {battleData.damage} damage!
        </p>
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
  beast: any;
  type: string;
}

export const NotificationBattleDisplay = ({
  battleData,
  beast,
  type,
}: NotificationBattleDisplayProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const appUrl = "https://loot-survivor.vercel.app/";
  const beastName = processBeastName(beast);
  const beastLevel = beast?.level;
  const beastTier = beast?.rank;
  const { data } = useQueriesStore();
  const rank = getRankFromList(
    adventurer?.id ?? 0,
    data.adventurersByXPQuery?.adventurers ?? []
  );
  const ordinalRank = getOrdinalSuffix(rank + 1 ?? 0);
  const isArray = Array.isArray(battleData);
  return (
    <div>
      {isArray && battleData.some((data) => data.fled) ? (
        <p>You fled the {beastName ? beastName : ""}!</p>
      ) : isArray &&
        battleData[0]?.ambushed &&
        battleData[0]?.targetHealth == 0 ? (
        <p>
          You were killed by the {beastName ? beastName : ""}, from an ambush
          taking {battleData[0].damage}!
        </p>
      ) : isArray &&
        battleData.length == 1 &&
        battleData[0]?.ambushed &&
        battleData[0]?.damage > 0 ? (
        <p>
          You were ambushed by the {beastName ? beastName : ""}, taking{" "}
          {battleData[0]?.damage}!
        </p>
      ) : isArray &&
        battleData.length == 1 &&
        battleData[0]?.ambushed &&
        battleData[0]?.damage == 0 ? (
        <p>
          You were ambushed by the {beastName ? beastName : ""}, but avoided it!
        </p>
      ) : isArray &&
        type == "Flee" &&
        battleData.length == 1 &&
        battleData[0]?.attacker == "Beast" &&
        battleData[0]?.targetHealth > 0 ? (
        <p>
          You failed to flee the {beastName ? beastName : ""} and were attacked
          taking {battleData[0]?.damage} damage!{" "}
        </p>
      ) : isArray &&
        type == "Flee" &&
        battleData.length == 1 &&
        battleData[0]?.attacker == "Beast" &&
        battleData[0]?.targetHealth == 0 ? (
        <p>
          You were killed trying to flee the {beastName ? beastName : ""}
          taking {battleData[0]?.damage} damage!{" "}
        </p>
      ) : (
        battleData[0]?.attacker == "Adventurer" &&
        (battleData[0]?.targetHealth > 0 && battleData[1]?.targetHealth > 0 ? (
          <p>
            You attacked the {beastName ? beastName : ""} with a mighty strike
            and dealt {battleData[0]?.damage} damage! They counterattacked for{" "}
            {battleData[1]?.damage} damage!
          </p>
        ) : battleData[0]?.attacker == "Adventurer" &&
          battleData[0]?.targetHealth == 0 ? (
          <div className="flex flex-col gap-2 items-center justify-center">
            <p>
              You slayed the {beastName ? beastName : ""} after inflicting{" "}
              {battleData[0]?.damage} damage!
            </p>
            <TwitterShareButton
              text={`My adventurer just slew a level ${beastLevel} ${beastName} (Tier ${beastTier}) on #LootSurvivor.\n\n${adventurer?.name} is currently ${ordinalRank} place on the leaderboard.\n\nThink you can out-survive me?\n\nEnter here and try to survive: ${appUrl}\n\n@lootrealms #Starknet #Play2Die #LootSurvivor`}
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
