import { useEffect, useState } from "react";
import PixelatedImage from "@/app/components/animations/PixelatedImage";

interface ArcadeLoaderProps {
  isSettingPermissions?: boolean;
  isGeneratingNewKey?: boolean;
}

export default function ArcadeLoader({
  isSettingPermissions,
  isGeneratingNewKey,
}: ArcadeLoaderProps) {
  const [loadingMessage, setLoadingMessage] = useState<string | null>(null);

  useEffect(() => {
    const timer = setInterval(() => {
      setLoadingMessage((prev) =>
        prev === "Please Wait" || !prev
          ? isSettingPermissions
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
  }, [isSettingPermissions]);

  return (
    <div className="fixed flex flex-col items-center sm:flex-row inset-0 bg-black z-50 sm:m-2 w-full h-full">
      <div className="flex items-center justify-center w-full sm:w-1/2 h-3/4 sm:h-full">
        <PixelatedImage
          src={"/scenes/intro/arcade-account.png"}
          pixelSize={5}
          pulsate={true}
        />
      </div>
      <h3 className="text-lg sm:text-3xl loading-ellipsis flex items-start sm:items-center justify-center sm:justify-start w-full sm:w-1/2 h-1/2">
        {loadingMessage}
      </h3>
    </div>
  );
}
