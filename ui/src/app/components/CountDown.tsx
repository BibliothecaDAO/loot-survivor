import { useEffect, useRef } from "react";
import { useCountUp } from "react-countup";
import { useState } from "react";
import { penaltyTime } from "../lib/constants";

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

export interface PenaltyCountDownProps {
  dataLoading: boolean;
  startCountdown: boolean;
  updateDeathPenalty: boolean;
  setUpdateDeathPenalty: (value: boolean) => void;
}

export const PenaltyCountDown: React.FC<PenaltyCountDownProps> = ({
  dataLoading,
  startCountdown,
  updateDeathPenalty,
  setUpdateDeathPenalty,
}) => {
  const [seconds, setSeconds] = useState(penaltyTime);
  const [intervalId, setIntervalId] = useState<number | null>(null);

  useEffect(() => {
    const startTimer = () => {
      setSeconds(penaltyTime);
      const targetTime = new Date().getTime() + penaltyTime * 1000;

      // Clear previous interval if it exists
      if (intervalId !== null) {
        window.clearInterval(intervalId);
      }

      const newIntervalId = window.setInterval(() => {
        const currentTime = new Date().getTime();
        const timeRemaining = Math.max(
          0,
          Math.floor((targetTime - currentTime) / 1000)
        );
        setSeconds(timeRemaining);
      }, 1000);

      // Store the new interval ID
      setIntervalId(newIntervalId);
    };

    if (updateDeathPenalty) {
      startTimer();
      setUpdateDeathPenalty(false);
    }
  }, [updateDeathPenalty]);

  return (
    <div className="text-xxs sm:text-lg self-center border px-1 border border-terminal-green">
      {startCountdown ? (
        seconds > 0 ? (
          <span className="flex flex-row gap-1 items-center">
            <p className="hidden sm:block">Penalty:</p>
            <p className="animate-pulse">{formatTime(seconds)}</p>
          </span>
        ) : (
          <p>Penalty Reached!</p>
        )
      ) : (
        <p>Not Started</p>
      )}
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
            <p className="text-2xl">Session Starts in</p>
            <p
              className={`text-6xl ${
                seconds < 10
                  ? "animate-pulse text-red-600"
                  : "text-terminal-yellow"
              }`}
            >
              {seconds === 0 ? "GO" : formatTime(seconds)}
            </p>
          </>
        ) : (
          <p className="text-6xl animate-pulse text-terminal-yellow">Loading</p>
        )}
      </span>
    </div>
  );
};
