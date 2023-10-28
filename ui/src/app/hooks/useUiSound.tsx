import useSound from "use-sound";

const dir = "/music/ui/";

export const soundSelector = {
  click: "beep.wav",
  discoverItem: "boost.mp3",
  flee: "flee.wav",
  jump: "jump.wav",
  slay: "slay.mp3",
  hit: "hurt.mp3",
};

export const useUiSounds = (selector: string) => {
  const [play] = useSound(dir + selector, {
    volume: 0.2,
  });

  return {
    play,
  };
};
