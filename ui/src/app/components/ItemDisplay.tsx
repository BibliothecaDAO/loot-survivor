import LootIcon from "./LootIcon";

export const ItemDisplay = (item: any) => {
  const formatItem = item.item;
  const slot = formatItem ? formatItem.slot : "";

  return (
    <div
      className={`flex-shrink flex gap-2 p-2 mb-1  ${
        formatItem ? "bg-terminal-green text-terminal-black" : ""
      }`}
    >
      <LootIcon type={slot} />
      <div>
        <span className="font-semibold whitespace-nowrap">
          {formatItem ? formatItem.item : "Nothing Equipped"}
          {slot == "Neck" || slot == "Ring" ? " +1 Luck" : ""}
        </span>{" "}
        <br />
        <span className="whitespace-nowrap">
          {formatItem &&
            `[Tier ${formatItem.rank}, Greatness ${formatItem.greatness}, ${formatItem.xp} XP]`}
        </span>
      </div>
    </div>
  );
};
