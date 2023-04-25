interface InventoryDisplayProps {
  items: any[];
  activeMenu: any;
}

export const InventoryDisplay = ({ items }: InventoryDisplayProps) => {
  return (
    <div className="absolute top-64 left-96 flex flex-col gap-4 w-full overflow-auto">
      {/* {isActive &&
        items?.map((item: any, index: number) => (
          <>
            {item.id != equippedItemId ? (
              <div key={index} className="flex flex-row items-center">
                <ItemDisplay item={item} />
                <Button
                  key={index}
                  ref={(ref) => (buttonRefs.current[index] = ref)}
                  className={
                    selectedIndex === index && isActive
                      ? item.equippedAdventurerId
                        ? "animate-pulse bg-white"
                        : "animate-pulse"
                      : "h-[20px]"
                  }
                  variant={selectedIndex === index ? "subtle" : "outline"}
                  size={"xs"}
                  onClick={() => {
                    !items[selectedIndex].equippedAdventurerId
                      ? handleAddEquipItem(items[selectedIndex].id)
                      : null;
                  }}
                >
                  Equip
                </Button>
              </div>
            ) : null}
          </>
        ))} */}
    </div>
  );
};
