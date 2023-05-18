"use effect";

import useSound from "use-sound";
import { useCallback, useEffect, useState } from "react";

const dir = "/music/ui/";

export const musicSelector = {
  backgroundMusic: "intro.mp3",
  battle: "fight4.mp3",
  death: "game_over.mp3",
};

export const useMusic = (
  playState: { isInBattle: boolean; isDead: boolean; isMuted: boolean },
  options?: { volume?: number; loop?: boolean }
) => {
  const [music, setMusic] = useState<string>(musicSelector.backgroundMusic);

  const [play, { stop }] = useSound(dir + music, {
    volume: options?.volume || 0.1,
    loop: options?.loop || false,
  });

  const start = useCallback(() => {
    play();
  }, []);

  useEffect(() => {
    stop();
    if (playState.isInBattle) {
      setMusic(musicSelector.battle);
    } else if (playState.isDead) {
      setMusic(musicSelector.death);
    } else {
      setMusic(musicSelector.backgroundMusic);
    }
    start();
  }, [playState.isInBattle, playState.isDead]);

  useEffect(() => {
    if (playState.isMuted) {
      stop();
    } else {
      play();
    }
  }, [play, stop, playState.isMuted]);

  return {
    play,
    stop,
  };
};
