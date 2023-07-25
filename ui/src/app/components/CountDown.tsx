import { useEffect, useRef } from "react";
import { useCountUp } from "react-countup";
import { useState } from "react";
import { penaltyTime } from "../lib/constants";
import { convertTime } from "../lib/utils";

export const HealthCountDown = ({ health }: any) => {
  const countUpRef = useRef(null);
  const { update } = useCountUp({
    ref: countUpRef,
    start: health,
    end: health,
    delay: 1000,
    duration: 5,
    // onReset: () => console.log("Resetted!"),
    // onUpdate: () => console.log("Updated!"),
    // onPauseResume: () => console.log("Paused or resumed!"),
    // onStart: ({ pauseResume }) => console.log(pauseResume),
    // onEnd: ({ pauseResume }) => console.log(pauseResume),
  });

  useEffect(() => {
    if (countUpRef.current !== health) {
      update(health);
    }
    countUpRef.current = health;
  }, [health, update]);

  return (
    <div>
      <div ref={countUpRef} />
    </div>
  );
};

export interface PenaltyCountDownProps {
  lastDiscoveryTime?: Date;
  lastBattleTime?: Date;
}

export const PenaltyCountDown = ({
  lastDiscoveryTime,
  lastBattleTime,
}: PenaltyCountDownProps) => {
  const [seconds, setSeconds] = useState(0);

  const finishedMessage = "Penalty Reached!";
  const countingMessage = "Penalty:";

  const formatDiscoveryTime = new Date(lastDiscoveryTime ?? 0).getTime();
  const formatBattleTime = new Date(lastBattleTime ?? 0).getTime();

  // Need to adjust this time from UTC to timezone
  const lastAction =
    formatDiscoveryTime > formatBattleTime
      ? formatDiscoveryTime
      : formatBattleTime;

  const formatLastAction = convertTime(lastAction);
  const targetTime = formatLastAction + penaltyTime * 1000;

  useEffect(() => {
    if (targetTime) {
      const updateCountdown = () => {
        const currentTime = new Date().getTime();
        const timeRemaining = targetTime - currentTime;
        setSeconds(Math.floor(timeRemaining / 1000));
      };

      updateCountdown();
      const interval = setInterval(updateCountdown, 1000);

      return () => {
        clearInterval(interval);
      };
    }
  }, [targetTime]);

  const formatTime = (totalSeconds: number) => {
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds - hours * 3600) / 60);
    const seconds = totalSeconds % 60;
    return `${hours.toString().padStart(2, "0")}:${minutes
      .toString()
      .padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
  };

  return (
    <div className="text-xs sm:text-lg">
      {targetTime ? (
        seconds > 0 ? (
          <span className="flex flex-row gap-1 items-center">
            <p>{countingMessage}</p>
            <p className="animate-pulse">{formatTime(seconds)}</p>
          </span>
        ) : (
          <p>{finishedMessage}</p>
        )
      ) : (
        <p className="loading-ellipsis">Loading</p>
      )}
    </div>
  );
};
