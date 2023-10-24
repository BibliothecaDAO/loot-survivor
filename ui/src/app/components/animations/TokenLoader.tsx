import SpriteAnimation from "@/app/components/animations/SpriteAnimation";

interface TokenLoaderProps {
  isToppingUpEth?: boolean;
  isToppingUpLords?: boolean;
}

export default function TokenLoader({
  isToppingUpEth,
  isToppingUpLords,
}: TokenLoaderProps) {
  return (
    <div className="fixed flex flex-col items-center sm:flex-row inset-0 bg-black z-50 sm:m-2 w-full h-full">
      <div className="flex items-center justify-center w-full sm:w-1/2 h-3/4 sm:h-full">
        <SpriteAnimation
          frameWidth={400}
          frameHeight={400}
          columns={8}
          rows={1}
          frameRate={5}
          className="coin-sprite"
        />
      </div>
      <h3 className="text-lg sm:text-3xl loading-ellipsis flex items-start sm:items-center justify-center sm:justify-start w-full sm:w-1/2 h-1/2">
        {isToppingUpEth
          ? "Topping Up Eth"
          : isToppingUpLords
          ? "Topping Up Lords"
          : "Withdrawing Tokens"}
      </h3>
    </div>
  );
}
