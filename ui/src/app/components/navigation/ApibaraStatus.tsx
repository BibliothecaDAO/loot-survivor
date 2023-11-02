interface ApibaraStatusProps {
  status?:
    | "none"
    | "minor"
    | "major"
    | "critical"
    | "maintenance"
    | "downtime"
    | "unknown";
}

export default function ApibaraStatus({ status }: ApibaraStatusProps) {
  const color = status === "none" ? "bg-terminal-green" : "bg-red-500";

  return (
    <div
      className={`w-2 h-2 sm:w-4 sm:h-4 rounded-lg ${color} cursor-pointer`}
      onClick={() => window.open("https://apibara.statuspage.io/", "_blank")}
    />
  );
}
