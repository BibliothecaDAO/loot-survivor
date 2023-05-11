import React, { useState, useEffect } from "react";
import { formatTime } from "../lib/utils";
import next from "next/types";

export const UTCClock: React.FC = () => {
  const [currentTime, setCurrentTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);

    // Clean up the timer when the component is unmounted
    return () => clearInterval(timer);
  }, []);

  return (
    <div>
      <p>{`Time: ${formatTime(currentTime)} UTC`}</p>
    </div>
  );
};

interface CountdownProps {
  countingMessage: string;
  finishedMessage: string;
  nextMintTime?: Date;
  expiryTime?: Date;
}

export const Countdown: React.FC<CountdownProps> = ({
  countingMessage,
  finishedMessage,
  nextMintTime,
  expiryTime,
}) => {
  const [seconds, setSeconds] = useState(0);
  const [displayTime, setDisplayTime] = useState("");

  useEffect(() => {
    let targetTime: Date | undefined;
    if (nextMintTime) {
      targetTime = nextMintTime;
    } else if (expiryTime) {
      targetTime = new Date(expiryTime);
    }

    if (targetTime) {
      const updateCountdown = () => {
        const currentTime = new Date().getTime();
        if (targetTime) {
          const timeRemaining = targetTime.getTime() - currentTime;
          setSeconds(Math.floor(timeRemaining / 1000));
        }
      };

      updateCountdown();
      const interval = setInterval(updateCountdown, 1000);

      return () => {
        clearInterval(interval);
      };
    }
  }, [nextMintTime, expiryTime]);

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
      {nextMintTime || expiryTime ? (
        <p>{displayTime}</p>
      ) : (
        <p className="loading-ellipsis">Loading</p>
      )}
    </div>
  );
};
