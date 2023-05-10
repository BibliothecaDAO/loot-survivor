import LootIcon from "./LootIcon";

export const ItemDisplay = (item: any) => {
  const processName = (item: any) => {
    if (item) {
      if (item.prefix1 && item.suffix && item.greatness >= 20) {
        return `${item.prefix1} ${item.prefix2} ${item.item} of ${item.suffix} +1`;
      } else if (item.prefix1 && item.suffix) {
        return `${item.prefix1} ${item.prefix2} ${item.item} of ${item.suffix}`;
      } else if (item.suffix) {
        return `${item.item} of ${item.suffix}`;
      } else {
        return `${item.item}`;
      }
    }
  };

  const formatItem = item?.item;

  const itemName = processName(formatItem);
  const slot = formatItem ? formatItem.slot : "";

  return (
    <div
      className={`flex-shrink flex gap-2 p-2 mb-1  ${
        item ? "bg-terminal-green text-terminal-black" : ""
      }`}
    >
      <LootIcon
        type={
          item.type == "feet"
            ? "foot"
            : item.type == "hands"
            ? "hand"
            : item.type
        }
      />
      <div>
        <span className="font-semibold whitespace-nowrap">
          {formatItem ? itemName : "Nothing Equipped"}
          {slot == "Neck" || slot == "Ring" ? " [+1 Luck]" : ""}
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
