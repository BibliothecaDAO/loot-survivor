import { useState, useEffect } from "react";

export const ANSIArt = ({ src, newWidth = 60 }: any) => {
  const [ansiArt, setAnsiArt] = useState("");

  useEffect(() => {
    const getColorCode = (pixel: any) => {
      const [r, g, b] = pixel;
      return `rgba(${r}, ${g}, ${b}, 255)`;
    };

    const loadAndRenderImage = async () => {
      const img = new Image();
      img.src = src;

      await new Promise((resolve) => {
        img.onload = resolve;
      });

      const canvas = document.createElement("canvas");
      const ctx = canvas.getContext("2d") as CanvasRenderingContext2D;
      const aspectRatio = img.height / img.width;
      const height = Math.floor(aspectRatio * newWidth);

      canvas.width = newWidth;
      canvas.height = height;

      ctx.drawImage(img, 0, 0, newWidth, height);

      const imageData = ctx.getImageData(0, 0, newWidth, height).data;
      const blockSize = 4;
      let ansiArtHtml = "";

      for (let y = 0; y < height; y += blockSize) {
        for (let x = 0; x < newWidth; x += blockSize) {
          const i = (y * newWidth + x) * 4;
          const pixel = [imageData[i], imageData[i + 1], imageData[i + 2]];
          const colorCode = getColorCode(pixel);
          const block = "\u2588";

          ansiArtHtml += `<span style="color: ${colorCode};">${block}</span>`;
        }
        ansiArtHtml += "<br>";
      }

      setAnsiArt(ansiArtHtml);
    };

    loadAndRenderImage();
  }, [src, newWidth]);

  return (
    <div
      className="leading-none ansi"
      dangerouslySetInnerHTML={{ __html: ansiArt }}
    ></div>
  );
};
