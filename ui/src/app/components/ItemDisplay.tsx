export const ItemDisplay = (item: any) => {
    const formatItem = item.item;
    return (
        <div className={`flex flex-row gap-2 p-2 border border-terminal-green  ${formatItem ? "bg-terminal-green text-terminal-black" : ""}`}>
            <p className="whitespace-nowrap">
                {formatItem ? formatItem.item : "Nothing Equipped"}
            </p>
            <p className="whitespace-nowrap">
                {formatItem &&
                    `[Rank ${formatItem.rank}, Greatness ${formatItem.greatness}, ${formatItem.xp} XP]`}
            </p>
        </div>
    );
};