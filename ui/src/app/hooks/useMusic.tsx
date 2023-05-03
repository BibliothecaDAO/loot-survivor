import useSound from "use-sound";

const dir = "/music/ui/";

export const musicSelector = {
  backgroundMusic: "8bit_NES.mp3",
};

export const useMusic = (
  selector: string,
  options?: { volume?: number; loop?: boolean }
) => {
  const [play, { stop }] = useSound(dir + selector, {
    volume: options?.volume || 0.5,
    loop: options?.loop || false,
  });

  return {
    play,
    stop,
  };
};
