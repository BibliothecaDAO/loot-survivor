import React, { useState, useEffect } from "react";
import "../SpriteAnimation.css";

interface AnimationInfo {
  name: string;
  startFrame: number;
  frameCount: number;
}

interface SpriteAnimationProps {
  frameWidth: number;
  frameHeight: number;
  columns: number;
  rows: number;
  frameRate: number;
  animations: AnimationInfo[];
  currentAnimation: string;
}

const SpriteAnimation: React.FC<SpriteAnimationProps> = ({
  frameWidth,
  frameHeight,
  columns,
  rows,
  frameRate,
  animations,
  currentAnimation,
}) => {
  const [frame, setFrame] = useState(0);

  const animationInfo = animations.find(
    (animation) => animation.name === currentAnimation
  );

  useEffect(() => {
    if (animationInfo) {
      const interval = setInterval(() => {
        setFrame((prevFrame) => (prevFrame + 1) % animationInfo.frameCount);
      }, 1000 / frameRate);

      return () => clearInterval(interval);
    }
  }, [frameRate, animationInfo]);

  const frameIndex = animationInfo ? animationInfo.startFrame + frame : 0;
  const bgPositionX = -(frameIndex % columns) * frameWidth;
  const bgPositionY = -Math.floor(frameIndex / columns) * frameHeight;

  return (
    <div
      className="sprite"
      style={{
        backgroundPositionX: `${bgPositionX}px`,
        backgroundPositionY: `${bgPositionY}px`,
        backgroundSize: `${columns * (frameWidth + 10)}px ${
          rows * frameHeight
        }px`,
        width: frameWidth,
        height: frameHeight,
      }}
    />
  );
};

export default SpriteAnimation;
