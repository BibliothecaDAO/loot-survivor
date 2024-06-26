import { Contract, CallData } from "starknet";
import React, { useEffect, useState } from "react";
import Image from "next/image";
import { getBeastData } from "@/app/lib/utils";
import { HeartIcon } from "@/app/components/icons/Icons";
import EfficacyIcon from "@/app/components/icons/EfficacyIcon";
import { processBeastName } from "@/app/lib/utils";
import { Beast } from "@/app/types";
import { HealthCountDown } from "@/app/components/CountDown";
import { getKeyFromValue } from "@/app/lib/utils";
import { GameData } from "@/app/lib/data/GameData";
import useUIStore from "@/app/hooks/useUIStore";

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

  const gameData = new GameData();

  const onKatana = useUIStore((state) => state.onKatana);

  const handleIsMinted = async () => {
    const minted = await beastsContract.call(
      "isMinted",
      CallData.compile({
        beast: getKeyFromValue(gameData.BEASTS, beastData?.beast ?? "")!,
        prefix: getKeyFromValue(
          gameData.ITEM_NAME_PREFIXES,
          beastData?.special2 ?? ""
        )!,
        suffix: getKeyFromValue(
          gameData.ITEM_NAME_SUFFIXES,
          beastData?.special3 ?? ""
        )!,
      })
    );
    if (minted == "1") {
      setIsMinted(true);
    } else {
      setIsMinted(false);
    }
  };

  useEffect(() => {
    if (namedBeast && !onKatana) {
      handleIsMinted();
    }
  }, [namedBeast]);

  // handle name scroll
  const scrollableRef = React.useRef<HTMLDivElement | null>(null);
  const animationFrameRef = React.useRef<number | null>(null);

  function startScrolling() {
    const el = scrollableRef.current;
    if (!el) return; // Guard clause
    const endPos = el.scrollWidth - el.offsetWidth; // Calculate the width of the overflow

    // Use this to control the speed of the scroll
    const duration = 4000; // In milliseconds

    const start = performance.now();
    const initialScrollLeft = el.scrollLeft;

    requestAnimationFrame(function step(now) {
      const elapsed = now - start;
      let rawProgress = elapsed / duration;

      let progress;
      if (rawProgress <= 0.5) {
        // For the first half, we scale rawProgress from [0, 0.5] to [0, 1]
        progress = rawProgress * 2;
      } else {
        // For the second half, we scale rawProgress from [0.5, 1] to [1, 0]
        progress = 2 - rawProgress * 2;
      }

      el.scrollLeft = initialScrollLeft + progress * endPos;

      if (rawProgress < 1) {
        animationFrameRef.current = requestAnimationFrame(step);
      } else {
        // Restart the animation once it's done
        startScrolling();
      }
    });
  }

  useEffect(() => {
    startScrolling();

    // Cleanup animation frame on unmount
    return () => {
      if (animationFrameRef.current !== null) {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, []); // Empty dependency array means this effect runs once when component mounts

  return (
    <div className="relative flex flex-col items-center h-full border-2 border-terminal-green">
      <div className="flex flex-col w-full sm:p-3 uppercase">
        <div className="flex justify-between items-center py-1 sm:py-3 text-2xl sm:text-4xl border-b border-terminal-green px-2 ">
          <p
            className="w-3/4 overflow-x-auto whitespace-nowrap item-scroll"
            ref={scrollableRef}
          >
            {beastName}
          </p>
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
