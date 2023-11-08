import { Button } from "../buttons/Button";

export const TournamentEnd = () => {
  return (
    <div className="self-center p-8 sm:w-1/2 h-full">
      <h1>
        The pre-release tournament has concluded. Your exploits have left an
        enduring mark in the tapestry of our perilous adventure.
      </h1>
      <h5>Loot Survivor will be back soon on mainnet...</h5>
      <h5>Play now on Testnet</h5>
      <Button
        onClick={() => window.open("https://goerli-survivor.realms.world/")}
      >
        {"Play on Testnet"}
      </Button>
    </div>
  );
};
