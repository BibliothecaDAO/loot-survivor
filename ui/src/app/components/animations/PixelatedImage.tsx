import React, { useEffect, useRef, useState } from "react";

interface PixelatedImageProps {
  src: string;
  pixelSize: number;
  setImageLoading?: (imageLoaded: boolean) => void;
  fill?: boolean;
  pulsate?: boolean;
}

const PixelatedImage: React.FC<PixelatedImageProps> = ({
  src,
  pixelSize,
  setImageLoading,
  fill,
  pulsate,
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
    const pixelateImage = () => {
      const image = new Image();
      image.src = src;

      image.onload = () => {
        setImageLoading && setImageLoading(true);
        const canvas = canvasRef.current;
        if (!canvas) return;

        const ctx = canvas.getContext("2d");
        if (!ctx) return;

        const { width, height } = dimensions;

        const aspectRatio = image.width / image.height;

        // Unless fill is true, from the smallest dimension calculate the width and height of the image
        const minDimension = Math.min(width, height);
        const newHeight = fill ? height : Math.min(minDimension, image.width);
        const newWidth = fill ? width : newHeight / aspectRatio;

        ctx.fillStyle = "black";
        ctx.fillRect(0, 0, width, height);

        const scaledWidth = Math.ceil(newWidth / pixelSize);
        const scaledHeight = Math.ceil(newHeight / pixelSize);
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
          setImageLoading && setImageLoading(false);
        }, maxTimeout);
      };
    };
    pixelateImage();
  }, [src, pixelSize, dimensions]);

  return (
    <canvas
      className={`absolute ${pulsate ? "animate-pulse" : ""}`}
      ref={canvasRef}
      width={dimensions.width}
      height={dimensions.height}
    ></canvas>
  );
};

export default PixelatedImage;
