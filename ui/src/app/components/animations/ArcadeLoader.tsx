import { useEffect, useState } from "react";
import PixelatedImage from "@/app/components/animations/PixelatedImage";
import { ArcadeNav } from "./ArcadeNav";

interface ArcadeLoaderProps {
  isPrefunding?: boolean;
  isDeploying?: boolean;
  isSettingPermissions?: boolean;
  isGeneratingNewKey?: boolean;
  fullDeployment?: boolean;
  showLoader?: boolean;
}

export default function ArcadeLoader({
  isPrefunding,
  isDeploying,
  isSettingPermissions,
  isGeneratingNewKey,
  fullDeployment,
  showLoader,
}: ArcadeLoaderProps) {
  const [loadingMessage, setLoadingMessage] = useState<string | null>(null);

  useEffect(() => {
    const timer = setInterval(() => {
      setLoadingMessage((prev) =>
        prev === "Please Wait" || !prev
          ? isPrefunding
            ? "Prefunding Arcade"
            : isSettingPermissions
            ? "Setting Permissions"
            : isGeneratingNewKey
            ? "Generating New Key"
            : "Deploying Arcade Account"
          : "Please Wait"
      );
    }, 5000);

    return () => {
      clearInterval(timer); // Cleanup timer on component unmount
    };
  }, [isPrefunding, isSettingPermissions, isGeneratingNewKey]);

  return (
    <>
      {showLoader && (
        <div className="fixed flex flex-col items-center sm:flex-row inset-0 bg-black z-50 sm:m-2 w-full h-full">
          <div className="flex items-center justify-center w-full sm:w-1/2 h-3/4 sm:h-full">
            <PixelatedImage
              src={"/scenes/intro/arcade-account.png"}
              pixelSize={5}
              pulsate={true}
            />
          </div>
          <div className="flex flex-col gap-10 h-full sm:w-1/2">
            <p className="text-lg sm:text-3xl flex items-start sm:items-center justify-center sm:justify-start w-full h-1/4 uppercase">
              Don&apos;t refresh!
            </p>
            <p className="text-lg sm:text-3xl loading-ellipsis flex items-start sm:items-center justify-center sm:justify-start w-full h-1/4">
              {loadingMessage}
            </p>
            {fullDeployment && (
              <ArcadeNav
                activeSection={isPrefunding ? 1 : isDeploying ? 2 : 3}
              />
            )}
          </div>
        </div>
      )}
    </>
  );
}
