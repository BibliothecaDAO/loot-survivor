import LootIcon from "./LootIcon";

export const ItemDisplay = (item: any) => {
  const processName = () => {
    if (item.prefix1 && item.suffix && item.greatness) {
      return `${item.prefix1} ${item.prefix2} ${item.item} ${item.suffix} +1`;
    } else if (item.prefix1 && item.suffix) {
      return `${item.prefix1} ${item.prefix2} ${item.item} ${item.suffix}`;
    } else if (item.prefix1) {
      return `${item.prefix1} ${item.prefix2} ${item.item}`;
    }
  };

  const formatItem = processName();
  const slot = item ? item.slot : "";

  return (
    <div
      className={`flex-shrink flex gap-2 p-2 mb-1  ${
        item ? "bg-terminal-green text-terminal-black" : ""
      }`}
    >
      <LootIcon type={slot} />
      <div>
        <span className="font-semibold whitespace-nowrap">
          {item ? formatItem : "Nothing Equipped"}
          {slot == "Neck" || slot == "Ring" ? " +1 Luck" : ""}
        </span>{" "}
        <br />
        <span className="whitespace-nowrap">
          {item &&
            `[Tier ${item.rank}, Greatness ${item.greatness}, ${item.xp} XP]`}
        </span>
      </div>
    </div>
  );
};
