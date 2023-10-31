import { Contract, CallData } from "starknet";
import { useEffect, useState } from "react";
import Image from "next/image";
import { getBeastData } from "@/app/lib/utils";
import { HeartIcon } from "@/app/components/icons/Icons";
import EfficacyIcon from "@/app/components/icons/EfficacyIcon";
import { processBeastName } from "@/app/lib/utils";
import { Beast } from "@/app/types";
import { HealthCountDown } from "@/app/components/CountDown";

interface BeastDisplayProps {
  beastData: Beast;
  beastsContract: Contract;
}

export const BeastDisplay = ({
  beastData,
  beastsContract,
}: BeastDisplayProps) => {
  const [isMinted, setIsMinted] = useState(false);
  const beastName = processBeastName(
    beastData?.beast ?? "",
    beastData?.special2 ?? "",
    beastData?.special3 ?? ""
  );
  const { tier, attack, armor, image } = getBeastData(beastData?.beast ?? "");

  const namedBeast = beastData?.special2 ? true : false;

  const handleIsMinted = async () => {
    const minted = await beastsContract.call(
      "isMinted",
      CallData.compile({
        beast: beastData?.beast ?? "",
        prefix: beastData?.special2 ?? "",
        suffix: beastData?.special3 ?? "",
      })
    );
    if (minted == "1") {
      setIsMinted(true);
    } else {
      setIsMinted(false);
    }
  };

  useEffect(() => {
    if (namedBeast) {
      handleIsMinted();
    }
  }, [namedBeast]);

  return (
    <div className="relative flex flex-col items-center h-full border-2 border-terminal-green">
      <div className="flex flex-col w-full sm:p-3 uppercase">
        <div className="flex justify-between items-center py-1 sm:py-3 text-2xl sm:text-4xl border-b border-terminal-green px-2 ">
          <p className="w-1/4">{beastName}</p>
          <div
            className={`text-4xl flex ${
              beastData?.health === 0 ? "text-red-600" : "text-terminal-green"
            } w-1/4 justify-end`}
          >
            <HeartIcon className="self-center w-4 h-4 fill-current mr-1" />{" "}
            <div className="self-center text-xl sm:text-4xl">
              <HealthCountDown health={beastData?.health || 0} />
            </div>
          </div>
        </div>
        <div className="flex justify-between w-full p-2 text-lg sm:text-3xl text-terminal-yellow">
          <p>Level {beastData?.level}</p>
          {!isMinted && namedBeast && (
            <p className="sm:text-lg animate-pulseFast text-terminal-yellow self-center w-1/2 text-center">
              Collectible
            </p>
          )}
          <p>Tier {tier}</p>
        </div>
        <div className="flex flex-row justify-center gap-4 items-center w-full py-1 sm:py-4 space-x-2">
          <div className="flex flex-row gap-2 items-center">
            <EfficacyIcon
              type={attack}
              size="w-6"
              className="self-center h-4 w-4 sm:w-6 sm:h-6"
            />
            <p className="text-sm text-center sm:text-xl">{attack} Attack</p>
          </div>
          <div className="flex flex-row gap-2 items-center">
            <EfficacyIcon
              type={armor}
              size="w-6"
              className="self-center h-4 w-4 sm:w-6 sm:h-6"
            />
            <p className="text-sm text-center sm:text-xl">{armor} Armor</p>
          </div>
        </div>
      </div>
      <div className="relative flex-grow w-full h-[18rem] sm:h-[150%]">
        <Image
          className="animate-pulse"
          src={image}
          alt="monsters"
          fill={true}
          sizes="xl"
          placeholder="blur"
          blurDataURL={
            "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAABCAQAAABeK7cBAAAADUlEQVR42mNkrmdgAAABkwCE1XPyYQAAAABJRU5ErkJggg=="
          }
          style={{
            objectFit: "contain",
          }}
        />
      </div>
    </div>
  );
};
