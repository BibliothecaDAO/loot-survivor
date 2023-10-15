import { efficacyData } from "@/app/lib/constants";

export const EfficacyHint = () => {
  return (
    <div className="flex flex-col gap-2 uppercase items-center text-center h-full">
      <h3 className="mt-0 uppercase">Elemental</h3>
      <div className="flex flex-col gap-5">
        <p className="sm:text-2xl">
          Understanding weapon and armor elemental is vital to survival
        </p>
        <table className="uppercase whitespace-nowrap border border-terminal-green text-sm">
          <thead>
            <tr className="text-l tracking-wide text-center border-b border-terminal-green ">
              <th className="px-4 py-3 border border-terminal-green">
                Weapon/Armor
              </th>
              <th className="px-4 py-3 border border-terminal-green">Metal</th>
              <th className="px-4 py-3 border border-terminal-green">Hide</th>
              <th className="px-4 py-3 border border-terminal-green">Cloth</th>
            </tr>
          </thead>
          <tbody className="border-terminal-green">
            {efficacyData.map((row, i) => (
              <tr key={i} className="text-terminal-green text-center">
                <td className="px-4 py-3 border border-terminal-green">
                  {row.weapon}
                </td>
                <td className="px-4 py-3 border border-terminal-green text-terminal-yellow">
                  {row.metal}
                </td>
                <td className="px-4 py-3 border border-terminal-green text-terminal-yellow">
                  {row.hide}
                </td>
                <td className="px-4 py-3 border border-terminal-green text-terminal-yellow">
                  {row.cloth}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div></div>
    </div>
  );
};
