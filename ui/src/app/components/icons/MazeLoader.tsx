import React from "react";

const MazeLoader: React.FC = () => {
  const rows = 8;
  const cols = 8;

  return (
    <div className="w-64 h-64 bg-gray-200 relative grid grid-rows-8 grid-cols-8 gap-1">
      {Array.from({ length: rows * cols }).map((_, index) => (
        <div
          key={index}
          className="w-7 h-7 bg-gray-400 animate-fadeIn"
          style={{ animationDelay: `${Math.random() * 2}s` }}
        />
      ))}
    </div>
  );
};

export default MazeLoader;
