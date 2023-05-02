import LootIcon from "./LootIcon";

export const ItemDisplay = (item: any) => {
  const formatItem = item.item;
  const slot = formatItem ? formatItem.slot : "";

  return (
    <div
      className={`flex-shrink flex gap-2 p-2 border border-terminal-green  ${formatItem ? "bg-terminal-green text-terminal-black" : ""
        }`}
    >
      <LootIcon type={slot} />
      <div>
        <span className="font-semibold whitespace-nowrap">
          {formatItem ? formatItem.item : "Nothing Equipped"}
        </span> <br />
        <span className="whitespace-nowrap">
          {formatItem &&
            `[Rank ${formatItem.rank}, Greatness ${formatItem.greatness}, ${formatItem.xp} XP]`}
        </span>
      </div>

    </div>
  );
};
