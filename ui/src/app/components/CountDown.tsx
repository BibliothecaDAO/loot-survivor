import { useEffect, useRef } from "react";
import { useCountUp } from "react-countup";
import { useState } from "react";
import { penaltyTime } from "../lib/constants";

export const HealthCountDown = ({ health }: any) => {
  const countUpRef = useRef(null);
  const { update } = useCountUp({
    ref: countUpRef,
    start: health,
    end: health,
    delay: 1000,
    duration: 5,
    onReset: () => console.log("Resetted!"),
    onUpdate: () => console.log("Updated!"),
    onPauseResume: () => console.log("Paused or resumed!"),
    onStart: ({ pauseResume }) => console.log(pauseResume),
    onEnd: ({ pauseResume }) => console.log(pauseResume),
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

export const PenaltyCountDown = ({
  lastDiscoveryTime,
  lastBattleTime,
}: any) => {
  const [seconds, setSeconds] = useState(0);
  const [displayTime, setDisplayTime] = useState("");

  const finishedMessage = "You have reached idle penalty!";
  const countingMessage = "Time until idle penalty:";

  const lastAction =
    lastDiscoveryTime > lastBattleTime ? lastDiscoveryTime : lastBattleTime;

  const lastTime = new Date(lastAction);

  const targetTime = lastTime.getTime() + penaltyTime * 1000;

  const currentTime = new Date().getTime();

  console.log(lastAction);
  console.log(targetTime - currentTime);

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

  useEffect(() => {
    if (seconds <= 0) {
      setDisplayTime(finishedMessage);
    } else {
      setDisplayTime(`${countingMessage} ${formatTime(seconds)}`);
    }
  }, [seconds, countingMessage, finishedMessage]);

  const formatTime = (totalSeconds: number) => {
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds - hours * 3600) / 60);
    const seconds = totalSeconds % 60;
    return `${hours.toString().padStart(2, "0")}:${minutes
      .toString()
      .padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
  };

  return (
    <div>
      {targetTime ? (
        <p>{displayTime}</p>
      ) : (
        <p className="loading-ellipsis">Loading</p>
      )}
    </div>
  );
};
