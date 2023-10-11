import { EntropyCountDown } from "../components/CountDown";

interface InterludeScreenProps {
  nextEntropyTime: number;
}

export default function InterludeScreen({
  nextEntropyTime,
}: InterludeScreenProps) {
  return (
    <div className="fixed inset-0 opacity-80 bg-terminal-black z-50 m-2 w-full h-full">
      <EntropyCountDown targetTime={1000000000000000000000} />
    </div>
  );
}
