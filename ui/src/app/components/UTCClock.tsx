import React, { useState, useEffect } from "react";

const UTCClock: React.FC = () => {
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

export default UTCClock;
