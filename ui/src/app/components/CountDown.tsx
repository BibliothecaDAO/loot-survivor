import { useEffect, useRef } from "react";
import { useCountUp } from "react-countup";

export const CountDown = ({health}: any) => {
    const countUpRef = useRef(null);
    const { update } = useCountUp({
      ref: countUpRef,
      start: health,
      end: health,
      delay: 1000,
      duration: 5,
      onReset: () => console.log('Resetted!'),
      onUpdate: () => console.log('Updated!'),
      onPauseResume: () => console.log('Paused or resumed!'),
      onStart: ({ pauseResume }) => console.log(pauseResume),
      onEnd: ({ pauseResume }) => console.log(pauseResume),
    });
  
    useEffect(() => {
      if (countUpRef.current !== health) {
        update(health);
      }
      countUpRef.current = health;
    }, [health, update]);
  
    return (
      <div>
        <div ref={countUpRef} />
      </div>
    );
  };