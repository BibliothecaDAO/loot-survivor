import {
  getValueFromKey,
  getItemData,
  convertToBoolean,
} from "@/app/lib/utils";
import { ItemPurchase, UpgradeSummary } from "@/app/types";
import { GameData } from "@/app/lib/data/GameData";
import { HealthPotionIcon } from "@/app/components/icons/Icons";
import LootIcon from "@/app/components/icons/LootIcon";

interface UpgradeSummaryProps {
  summary: UpgradeSummary;
  attributes: any[];
}

const Summary = ({ summary, attributes }: UpgradeSummaryProps) => {
  const gameData = new GameData();
  return (
    <div className="flex flex-col gap-5 items-center animate-pulse w-2/3">
      <h3 className="mx-auto">Upgrading</h3>
      <p className="text-2xl">Stat Increases:</p>
      {Object.entries(summary["Stats"]).map(([key, value]) => {
        if (value !== 0) {
          return (
            <div className="flex flex-row gap-2 items-center" key={key}>
              <span className="w-10 h-10">
                {attributes.find((a) => a.name === key)?.icon}
              </span>
              <p className="text-no-wrap uppercase text-lg">{`${key} x ${value}`}</p>
            </div>
          );
        }
      })}
      {(summary["Items"].length > 0 || summary["Potions"] > 0) && (
        <p className="text-2xl">Item Purchases:</p>
      )}
      {summary["Items"].length > 0 && (
        <>
          {summary["Items"].map((item: ItemPurchase, index: number) => {
            const { slot } = getItemData(
              getValueFromKey(gameData.ITEMS, parseInt(item.item)) ?? ""
            );
            return (
              <div className="flex flex-row gap-2 items-center" key={index}>
                <div className="sm:hidden">
                  <LootIcon size={"w-4"} type={slot} />
                </div>
                <div className="hidden sm:block">
                  <LootIcon size={"w-5"} type={slot} />
                </div>
                <p className="text-lg">
                  {getValueFromKey(gameData.ITEMS, parseInt(item.item))}
                </p>
                <p>
                  {convertToBoolean(parseInt(item.equip)) ? " - Equipping" : ""}
                </p>
              </div>
            );
          })}
        </>
      )}
      {summary["Potions"] > 0 && (
        <div className="flex flex-row gap-2 items-center">
          <HealthPotionIcon />
          <p className="text-lg">{`Health Potions x ${summary["Potions"]}`}</p>
        </div>
      )}
    </div>
  );
};

export default Summary;
