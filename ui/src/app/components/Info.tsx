import { NullAdventurer } from "../types";
import { useQuery } from "@apollo/client";
import { getItemsByAdventurer } from "../hooks/graphql/queries";
import { ANSIArt } from "./ANSIGenerator";
import Heart from "../../../public/heart.svg";
import Coin from "../../../public/coin.svg";
interface InfoProps {
  adventurer: any;
}

export default function Info({ adventurer }: InfoProps) {
  const formatAdventurer = adventurer ? adventurer : NullAdventurer;
  const {
    loading: itemsByAdventurerLoading,
    error: itemsByAdventurerError,
    data: itemsByAdventurerData,
    refetch: itemsByAdventurerRefetch,
  } = useQuery(getItemsByAdventurer, {
    variables: {
      adventurer: formatAdventurer.id,
    },
    pollInterval: 5000,
  });

  const items = itemsByAdventurerData ? itemsByAdventurerData.items : [];

  const ItemDisplay = (item: any) => {
    const formatItem = item.item;
    return <>{formatItem ? formatItem.item : "Nothing"}</>;
  };

  return (
    <div className="h-full border border-terminal-green">
      {!itemsByAdventurerLoading ? (
        <>

          <div className="flex flex-row gap-2 p-1">
            <div>
              <ANSIArt
                newWidth={240}
                src={
                  formatAdventurer.health == 0 ? "/skull.png" : "/MIKE.png"
                }
              />
            </div>

            <div className="flex flex-col w-full p-2 uppercase">
              <div className="flex justify-between w-full text-4xl font-medium border-b border-terminal-green">
                {formatAdventurer.name}
                <span className="flex text-terminal-yellow">
                  <Coin className="self-center w-6 h-6 fill-current" /> {formatAdventurer.gold}
                </span>
                <span className="flex ">
                  <Heart className="self-center w-6 h-6 fill-current" /> {formatAdventurer.health}
                </span>



              </div>
              <div className="flex justify-between w-full text-2xl border-b border-terminal-green">
                <p className="">
                  Level {formatAdventurer.level}
                </p>
                <p className="">
                  xp {formatAdventurer.xp}
                </p>
              </div>
              <div className="flex flex-row justify-between">
                <div className="flex flex-col">
                  <p className="">
                    WEAPON -{" "}
                    <ItemDisplay
                      item={items.find(
                        (item: any) => item.id == formatAdventurer.weaponId
                      )}
                    />
                  </p>
                  <p className="">
                    HEAD -{" "}
                    <ItemDisplay
                      item={items.find(
                        (item: any) => item.id == formatAdventurer.headId
                      )}
                    />
                  </p>
                  <p className="">
                    CHEST -{" "}
                    <ItemDisplay
                      item={items.find(
                        (item: any) => item.id == formatAdventurer.chestId
                      )}
                    />
                  </p>
                  <p className="">
                    HAND -{" "}
                    <ItemDisplay
                      item={items.find(
                        (item: any) => item.id == formatAdventurer.handsId
                      )}
                    />
                  </p>
                  <p className="">
                    WAIST -{" "}
                    <ItemDisplay
                      item={items.find(
                        (item: any) => item.id == formatAdventurer.waistId
                      )}
                    />
                  </p>
                  <p className="">
                    FOOT -{" "}
                    <ItemDisplay
                      item={items.find(
                        (item: any) => item.id == formatAdventurer.feetId
                      )}
                    />
                  </p>
                  <p className="">
                    NECK -{" "}
                    <ItemDisplay
                      item={items.find(
                        (item: any) => item.id == formatAdventurer.neckId
                      )}
                    />
                  </p>
                  <p className="">
                    RING -{" "}
                    <ItemDisplay
                      item={items.find(
                        (item: any) => item.id == formatAdventurer.ringId
                      )}
                    />
                  </p>
                </div>
                <div className="flex flex-col">
                  <p className="">
                    STRENGTH - {formatAdventurer.strength}
                  </p>
                  <p className="">
                    DEXTERITY - {formatAdventurer.dexterity}
                  </p>
                  <p className="">
                    INTELLIGENCE - {formatAdventurer.intelligence}
                  </p>
                  <p className="">
                    VITALITY - {formatAdventurer.vitality}
                  </p>
                  <p className="">
                    WISDOM - {formatAdventurer.wisdom}
                  </p>
                  <p className="">
                    LUCK - {formatAdventurer.luck}
                  </p>
                </div>
              </div>
            </div>
          </div>


        </>
      ) : null
      }
    </div >
  );
}
