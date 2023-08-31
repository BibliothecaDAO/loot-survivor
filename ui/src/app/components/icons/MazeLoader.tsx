import React, { useState, useEffect } from "react";

const MazeLoader: React.FC = () => {
  const rows = 8;
  const cols = 8;
  const [maze, setMaze] = useState<number[][]>(
    Array(rows)
      .fill(null)
      .map(() => Array(cols).fill(-1))
  );

  useEffect(() => {
    const directions: [number, number][] = [
      [-2, 0],
      [2, 0],
      [0, -2],
      [0, 2],
    ];

    const generateMaze = (startX: number, startY: number) => {
      let stack: [number, number][] = [];
      let order = 0;
      let maze = Array(rows)
        .fill(null)
        .map(() => Array(cols).fill(-1));

      const visit = (x: number, y: number) => {
        maze[x][y] = order++;
        stack.push([x, y]);
      };

      visit(startX, startY);

      while (stack.length) {
        let [x, y] = stack.pop() as [number, number];

        const shuffledDirections = directions.sort(() => Math.random() - 0.5);

        for (let [dx, dy] of shuffledDirections) {
          let nx = x + dx;
          let ny = y + dy;

          if (
            nx >= 0 &&
            ny >= 0 &&
            nx < rows &&
            ny < cols &&
            maze[nx][ny] === -1
          ) {
            visit(x + dx / 2, y + dy / 2); // Visit in-between cell.
            visit(nx, ny);
          }
        }
      }

      setMaze(maze);
    };

    const randomStartX = Math.floor(Math.random() * rows);
    const randomStartY = Math.floor(Math.random() * cols);

    generateMaze(randomStartX, randomStartY); // Use the random starting point
  }, []);

  return (
    <div
      className="fixed top-0 left-0 w-full h-full flex items-center justify-center z-50"
      style={{ backgroundColor: "rgba(0, 0, 0, 0.5)" }}
    >
      <div className="w-64 h-64 relative grid grid-rows-8 grid-cols-8 gap-1">
        {maze.map((row, rowIndex) =>
          row.map((order, colIndex) => (
            <div
              key={`${rowIndex}-${colIndex}`}
              className={`w-2 h-2 ${
                order !== -1
                  ? "bg-terminal-green animate-ping"
                  : "bg-terminal-dark"
              }`}
              style={{
                animationDelay: order !== -1 ? `${order * 0.2}s` : "0s",
              }}
            />
          ))
        )}
      </div>
    </div>
  );
};

export default MazeLoader;
