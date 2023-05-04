import useSound from "use-sound";
import { useEffect } from "react";

const dir = "/music/ui/";

export const musicSelector = {
  backgroundMusic: "8bit_NES.mp3",
};

export const useMusic = (
  selector: string,
  options?: { volume?: number; loop?: boolean; isMuted: boolean }
) => {
  const [play, { stop }] = useSound(dir + selector, {
    volume: options?.volume || 0.1,
    loop: options?.loop || false,
  });

  useEffect(() => {
    if (options?.isMuted) {
      stop();
    } else {
      play();
    }
  }, [options?.isMuted, play, stop]);

  return {
    play,
    stop,
  };
};
