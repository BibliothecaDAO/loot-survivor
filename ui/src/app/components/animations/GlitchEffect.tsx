import React, { useEffect, useRef } from "react";
import "@/app/GlitchEffect.css";

const GlitchEffect: React.FC = () => {
  const textRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const textElement = textRef.current;

    if (!textElement) return;

    const glitch = () => {
      // Generating random values to simulate the glitch effect
      const randomInt = (min: number, max: number) =>
        Math.floor(Math.random() * (max - min + 1) + min);

      const randomTime = () => `${randomInt(1, 100)}ms`;
      const randomPosition = () => `${randomInt(1, 100)}%`;

      // Applying glitch effect using CSS variables
      textElement.style.setProperty("--clip-top", randomPosition());
      textElement.style.setProperty("--clip-bottom", randomPosition());
      textElement.style.setProperty("--anim-duration", randomTime());
    };

    const interval = setInterval(glitch, 1000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div
      ref={textRef}
      className="glitch text-red-500 text-4xl sm:text-6xl"
      data-text="YOU DIED!"
      style={
        {
          "--clip-top": "0%",
          "--clip-bottom": "100%",
          "--anim-duration": "0ms",
        } as React.CSSProperties
      }
    >
      YOU DIED!
    </div>
  );
};

export default GlitchEffect;
