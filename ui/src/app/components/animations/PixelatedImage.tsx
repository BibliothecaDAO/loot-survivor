import React, { useEffect, useRef, useState } from "react";

interface PixelatedImageProps {
  src: string;
  pixelSize: number;
  setImageLoading: (imageLoaded: boolean) => void;
}

const PixelatedImage: React.FC<PixelatedImageProps> = ({
  src,
  pixelSize,
  setImageLoading,
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 });

  useEffect(() => {
    const updateDimensions = () => {
      const parent = canvasRef.current?.parentElement;
      if (parent) {
        setDimensions({
          width: parent.clientWidth,
          height: parent.clientHeight,
        });
      }
    };

    updateDimensions();
    window.addEventListener("resize", updateDimensions);

    return () => window.removeEventListener("resize", updateDimensions);
  }, []);

  useEffect(() => {
    const image = new Image();
    image.src = src;

    image.onload = () => {
      setImageLoading(true);
      const canvas = canvasRef.current;
      if (!canvas) return;

      const ctx = canvas.getContext("2d");
      if (!ctx) return;

      const { width, height } = dimensions;

      ctx.fillStyle = "black";
      ctx.fillRect(0, 0, width, height);

      const scaledWidth = Math.ceil(width / pixelSize);
      const scaledHeight = Math.ceil(height / pixelSize);
      let maxTimeout = 0;

      for (let y = 0; y < scaledHeight; y++) {
        for (let x = 0; x < scaledWidth; x++) {
          const timeout = Math.random() * 100;
          maxTimeout = Math.max(maxTimeout, timeout);
          setTimeout(() => {
            // Updated drawImage method to scale the image to the canvas size
            ctx.drawImage(
              image,
              x * (image.width / scaledWidth),
              y * (image.height / scaledHeight),
              image.width / scaledWidth,
              image.height / scaledHeight,
              x * pixelSize,
              y * pixelSize,
              pixelSize,
              pixelSize
            );
          }, timeout);
        }
      }

      setTimeout(() => {
        setImageLoading(false);
      }, maxTimeout);
    };
  }, [src, pixelSize, dimensions]);

  return (
    <canvas
      className="absolute"
      ref={canvasRef}
      width={dimensions.width}
      height={dimensions.height}
    ></canvas>
  );
};

export default PixelatedImage;
