import { useBurner } from "@/app/lib/burner";
import { Button } from "../buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";

export const ArcadeIntro = () => {
  const { create } = useBurner();
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed text-center sm:top-1/8 sm:left-1/8 sm:left-1/4 sm:w-3/4 sm:w-1/2 h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4 overflow-y-auto">
        <h3 className="mt-4">Create Arcade Account</h3>
        <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
          Welcome Adventurer! In order to begin your journey you will need to
          create an arcade account.
        </p>
        <Button onClick={() => create()} disabled={isWrongNetwork}>
          CREATE
        </Button>
      </div>
    </>
  );
};
