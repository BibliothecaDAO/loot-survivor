import React, { useState, useEffect } from "react";

export const UTCClock: React.FC = () => {
  const [currentTime, setCurrentTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);

    // Clean up the timer when the component is unmounted
    return () => clearInterval(timer);
  }, []);

  const formatUTCTime = (date: Date) => {
    return date.toISOString().slice(0, 19); // Extract the time portion (hh:mm:ss) from the ISO string
  };

  return (
    <div>
      <p>{formatUTCTime(currentTime)}</p>
    </div>
  );
};

interface CountdownProps {
  endTime: Date;
  countingMessage: string;
  finishedMessage: string;
}

export const Countdown: React.FC<CountdownProps> = ({
  endTime,
  countingMessage,
  finishedMessage,
}) => {
  const startTime = new Date();
  const initialDifferenceInSeconds = Math.floor(
    (endTime.getTime() - startTime.getTime()) / 1000
  );
  const [seconds, setSeconds] = useState(initialDifferenceInSeconds);

  useEffect(() => {
    if (seconds <= 0) return;

    const timer = setInterval(() => {
      setSeconds((prevSeconds) => prevSeconds - 1);
    }, 1000);

    // Clean up the timer when the component is unmounted
    return () => clearInterval(timer);
  }, [seconds]);

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
      <p>
        {seconds <= 0
          ? finishedMessage
          : `${countingMessage} ${formatTime(seconds)}`}
      </p>
    </div>
  );
};
