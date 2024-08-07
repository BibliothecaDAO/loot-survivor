import { processBeastName, getBeastData } from "@/app/lib/utils";

interface BeastRowProps {
  beast: any;
  rank: number;
}

const BeastRow = ({ beast, rank }: BeastRowProps) => {
  const beastName = processBeastName(
    beast?.beast!,
    beast.special2!,
    beast.special3!
  );

  const { tier } = getBeastData(beast?.beast!);

  return (
    <tr className="text-center border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black cursor-pointer xl:h-2 xl:text-lg 2xl:text-xl 2xl:h-10">
      <td>{rank}</td>
      <td>{beastName}</td>
      <td>{tier}</td>
      <td>{beast?.level}</td>
      <td>{beast?.level! * (6 - tier)}</td>
      <td>
        {beast?.name} - {beast?.adventurerId}
      </td>
    </tr>
  );
};

export default BeastRow;
