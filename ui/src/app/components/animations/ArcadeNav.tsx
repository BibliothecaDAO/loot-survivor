interface ArcadeNavProps {
  activeSection: number;
}

interface NavItem {
  label: string;
  section: number;
}

const arcadeNav: NavItem[] = [
  { label: "Prefunding Account", section: 1 },
  { label: "Deploying Account", section: 2 },
  { label: "Setting Permissons", section: 3 },
];

export const ArcadeNav = ({ activeSection }: ArcadeNavProps) => {
  return (
    <div className="flex flex-row w-full text-shadow-none">
      {arcadeNav.map((item: NavItem, index: number) => (
        <span key={index} className="relative flex flex-row">
          {(item.section == 1 || item.section == 3) && (
            <div className="absolute top-[-20px] uppercase">
              {item.section == 1 ? "1st TX" : "2nd TX"}
            </div>
          )}
          <div
            className={`uppercase sm:text-2xl ${
              activeSection >= item.section
                ? "text-terminal-green"
                : "text-slate-600"
            } ${activeSection === item.section ? "animate-pulse" : ""}`}
          >
            {item.label}
          </div>
          {item.section !== arcadeNav.length && (
            <div
              className={` sm:text-2xl
                ${
                  activeSection > item.section
                    ? "text-terminal-green"
                    : "text-slate-600"
                }
              `}
            >
              ........
            </div>
          )}
        </span>
      ))}
    </div>
  );
};
