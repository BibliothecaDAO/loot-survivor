import { useState, useEffect } from "react";
import { fetchBeastImage } from "@/app/api/fetchMetadata";
import Image from "next/image";
import useUIStore from "@/app/hooks/useUIStore";
import { useContracts } from "@/app/hooks/useContracts";
import { processBeastName } from "@/app/lib/utils";
import TwitterShareButton from "@/app/components/buttons/TwitterShareButtons";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { Button } from "@/app/components/buttons/Button";

export const SpecialBeast = () => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const { beastsContract } = useContracts();
  const [beastImage, setBeastImage] = useState(null);

  const specialBeast = useUIStore((state) => state.specialBeast);
  const setSpecialBeast = useUIStore((state) => state.setSpecialBeast);
  const setSpecialBeastDefeated = useUIStore(
    (state) => state.setSpecialBeastDefeated
  );

  const fetchBeast = async () => {
    const image = await fetchBeastImage(
      beastsContract?.address ?? "",
      specialBeast?.tokenId ?? 0
    );
    setBeastImage(image);
  };

  useEffect(() => {
    fetchBeast();
  }, [specialBeast]);

  const beastName = processBeastName(
    specialBeast?.data?.beast ?? "Ent",
    specialBeast?.data?.special2 ?? "Agony",
    specialBeast?.data?.special3 ?? "Bane"
  );

  const resetBeast = () => {
    setSpecialBeastDefeated(false);
    setSpecialBeast(null);
  };

  const beastUrl =
    (process.env.NEXT_PUBLIC_BEASTS_VIEWER_URL ?? "") +
    "/" +
    specialBeast?.tokenId?.toString();

  return (
    <div className="top-0 left-0 fixed text-center h-full w-full z-40">
      <div className="absolute inset-0 bg-black" />
      <div className="flex flex-col gap-4 sm:gap-10 items-center justify-center z-10 p-10 sm:p-20 h-full">
        <div className="flex flex-col gap-5 z-10 h-full w-full items-center justify-center">
          <div className="flex flex-col text-6xl h-1/6 text-terminal-yellow">
            <p className="animate-pulseFast">COLLECTED BEAST</p>
            <p className="uppercase">{beastName}</p>
          </div>
          {beastImage && (
            <div className="relative h-1/2 w-full">
              <Image
                src={beastImage}
                fill={true}
                alt="Special Beast"
                className="z-10 animate-pulse"
              />
            </div>
          )}
          <div className="flex flex-col gap-5 items-center justify-center w-1/6">
            <TwitterShareButton
              text={`${adventurer?.name} just defeated the first ${beastName} and collects the 1:1 Beast #LootSurvivor.\n\nToken: ${beastUrl}👹\n\nEnter here and try to survive: ${process.env.NEXT_PUBLIC_APP_URL}\n\n@lootrealms #Starknet #Play2Die #LootSurvivor`}
            />
            <a href={beastUrl} target="_blank">
              <Button>View Collectible</Button>
            </a>
            <Button onClick={() => resetBeast()}>Continue</Button>
          </div>
        </div>
      </div>
    </div>
  );
};
