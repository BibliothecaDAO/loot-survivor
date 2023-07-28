import useUIStore from "@/app/hooks/useUIStore";

export const ArcadeDialog = () => {

  const showTutorialDialog = useUIStore((state) => state.showTutorialDialog);


  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed text-center top-1/8 left-1/8 sm:left-1/4 w-3/4 sm:w-1/2 h-3/4 rounded-lg border border-red-500 bg-terminal-black z-50">

      </div>
    </>
  );
};
