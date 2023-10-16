import React, { useState, useEffect } from "react";

const RowLoader: React.FC = () => {
  const cols = 6; // Change to 6 columns
  const [loaderData, setLoaderData] = useState<number[]>(Array(cols).fill(-1));

  useEffect(() => {
    const row = loaderData;
    const randomStartX = Math.floor(Math.random() * cols);

    row[randomStartX] = 0; // Set the initial square to 0

    let order = 0;
    for (let i = 0; i < cols; i++) {
      row[i] = order++;
    }

    setLoaderData([...row]);
  }, []);

  return (
    <div className="w-full h-full flex items-center justify-center">
      <div className="w-full h-full relative flex items-center justify-between gap-1">
        {loaderData.map((order, colIndex) => (
          <div
            key={colIndex}
            className={`w-3 h-3 2xl:w-6 2xl:h-6 ${
              order !== -1 ? "bg-terminal-green animate-ping" : ""
            }`}
            style={{
              animationDelay: order !== -1 ? `${order * 0.2}s` : "0s",
            }}
          />
        ))}
      </div>
    </div>
  );
};

export default RowLoader;
