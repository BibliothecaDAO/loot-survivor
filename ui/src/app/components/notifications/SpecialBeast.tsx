import { useState, useEffect } from "react";
import { fetchBeastImage } from "@/app/api/fetchMetadata";
import Image from "next/image";
import useUIStore from "@/app/hooks/useUIStore";
import { useContracts } from "@/app/hooks/useContracts";

export const SpecialBeast = () => {
  const { beastsContract } = useContracts();
  const [beastImage, setBeastImage] = useState(null);

  const specialBeast = useUIStore((state) => state.specialBeast);

  const fetchBeast = async () => {
    const image = await fetchBeastImage(
      beastsContract?.address ?? "",
      specialBeast.tokenId
    );
    setBeastImage(image);
  };

  useEffect(() => {
    fetchBeast();
  }, []);

  // TODO: ADD BUTTONS

  return (
    <div className="top-0 left-0 fixed text-center h-full w-full z-40">
      <div className="absolute inset-0 bg-black opacity-75" />
      <div className="flex flex-col gap-4 sm:gap-10 items-center justify-center z-10 p-10 sm:p-20 h-full">
        <div className="flex flex-col z-10 h-full w-full">
          <p className="text-6xl h-1/4 animate-pulseFast text-terminal-yellow">
            UNLOCKED BEAST
          </p>
          {beastImage && (
            <div className="relative h-3/4 w-full">
              <Image
                src={beastImage}
                fill={true}
                alt="Special Beast"
                className="z-10"
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
