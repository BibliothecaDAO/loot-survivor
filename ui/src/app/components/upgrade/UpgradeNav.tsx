interface UpgradeNavProps {
  activeSection: number;
}

export const UpgradeNav = ({ activeSection }: UpgradeNavProps) => {
  return (
    <div className="flex justify-center items-center w-full text-shadow-none">
      <div
        className={`uppercase ${
          activeSection >= 1 ? "text-terminal-green" : "text-slate-600"
        }`}
      >
        Loot Fountain
      </div>
      <div
        className={activeSection > 1 ? "text-terminal-green" : "text-slate-600"}
      >
        ........
      </div>
      <div
        className={`uppercase ${
          activeSection >= 2 ? "text-terminal-green" : "text-slate-600"
        }`}
      >
        Upgrade Stat
      </div>
    </div>
  );
};
