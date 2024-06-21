import React from "react";
import useUIStore from "@/app/hooks/useUIStore";
import { MdClose } from "react-icons/md";
import { useUiSounds, soundSelector } from "@/app/hooks/useUiSound";

export const FleeDialog = (props: any) => {
  const showFleeDialog = useUIStore((state) => state.showFleeDialog);
  const { play: clickPlay } = useUiSounds(soundSelector.click);

  return (
    <>
      <div
        className="fixed inset-0 opacity-80 bg-terminal-black z-40"
        onClick={() => showFleeDialog(false)}
      />

      <div className="fixed text-center sm:top-1/8 sm:left-1/4 sm:left-1/4 sm:w-1/2 sm:w-1/2 h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4 overflow-y-auto uppercase">
        <div className="flex justify-center items-center">
          <h3 className="m-0">Flee Details</h3>
        </div>
        <button
          className="absolute top-0 right-0"
          onClick={() => {
            showFleeDialog(false);
            clickPlay();
          }}
        >
          <MdClose className="w-10 h-10" />
        </button>

        {React.Children.toArray(
          props.events?.map((event: any) => (
            <>
              {event.type === "beast_attack" && (
                <>
                  <div className="flex w-full justify-between px-6 py-1">
                    {`Failed to flee`}
                  </div>

                  <div className="flex w-full justify-between px-6 text-red-500">
                    {`Beast attack ${event.location} for ${event.totalDamage} ${
                      event.isCriticalHit ? "critical hit!" : "damage"
                    }`}
                  </div>
                </>
              )}
            </>
          ))
        )}

        {props.success ? (
          <div className="flex w-full justify-between px-6 py-1 text-terminal-yellow">
            {`Flee success!`}
          </div>
        ) : (
          <div className="flex w-full justify-between px-6 py-1 text-red-500">
            {`Killed by beast`}
          </div>
        )}
      </div>
    </>
  );
};
