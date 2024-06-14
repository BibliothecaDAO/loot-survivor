import { useEffect, useRef } from "react";
import { useCountUp } from "react-countup";
import { useState } from "react";

const formatTime = (totalSeconds: number) => {
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds - hours * 3600) / 60);
  const seconds = totalSeconds % 60;
  return `${minutes.toString().padStart(2, "0")}:${seconds
    .toString()
    .padStart(2, "0")}`;
};

export const HealthCountDown = ({ health }: any) => {
  const countUpRef = useRef(null);
  const { update } = useCountUp({
    ref: countUpRef,
    start: health,
    end: health,
    delay: 1000,
    duration: 5,
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

export interface EntropyCountDownProps {
  targetTime: number | null;
  countDownExpired: () => void;
}

export const EntropyCountDown = ({
  targetTime,
  countDownExpired,
}: EntropyCountDownProps) => {
  const [seconds, setSeconds] = useState(0);
  useEffect(() => {
    if (targetTime) {
      const updateCountdown = () => {
        const currentTime = new Date().getTime();
        const timeRemaining = targetTime - currentTime;
        setSeconds(Math.floor(timeRemaining / 1000));

        if (timeRemaining <= 0) {
          countDownExpired(); // Call the countDownExpired function when countdown expires
        } else {
          setSeconds(Math.floor(timeRemaining / 1000));
        }
      };

      updateCountdown();
      const interval = setInterval(updateCountdown, 1000);

      return () => {
        clearInterval(interval);
      };
    }
  }, [targetTime]);
  return (
    <div className="h-1/4 flex items-center justify-center">
      <span className="flex flex-col gap-1 items-center justify-center">
        {targetTime ? (
          <>
            <p
              className={`text-6xl ${
                seconds < 10
                  ? "animate-pulse text-terminal-yellow"
                  : "text-terminal-yellow"
              }`}
            >
              {formatTime(seconds)}
            </p>
          </>
        ) : (
          <p className="text-6xl animate-pulse text-terminal-yellow">Loading</p>
        )}
      </span>
    </div>
  );
};
