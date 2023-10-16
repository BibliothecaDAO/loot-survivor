import useSound from "use-sound";

const dir = "/music/ui/";

export const soundSelector = {
  click: "beep.wav",
};

export const useUiSounds = (selector: string) => {
  const [play] = useSound(dir + selector, {
    volume: 0.2,
  });

  return {
    play,
  };
};
