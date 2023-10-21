import SpriteAnimation from "./SpriteAnimation";

interface TokenLoaderProps {
  isToppingUpEth?: boolean;
  isToppingUpLords?: boolean;
}

export default function TokenLoader({
  isToppingUpEth,
  isToppingUpLords,
}: TokenLoaderProps) {
  return (
    <div className="hidden sm:flex flex-row items-center justify-center h-full">
      <SpriteAnimation
        frameWidth={400}
        frameHeight={400}
        columns={8}
        rows={1}
        frameRate={5}
        className="coin-sprite"
      />
      <h3 className="text-lg sm:text-3xl loading-ellipsis flex items-center justify-center w-1/2 h-full">
        {isToppingUpEth
          ? "Topping Up Eth"
          : isToppingUpLords
          ? "Topping Up Lords"
          : "Withdrawing Tokens"}
      </h3>
    </div>
  );
}
