export const AdventurerTutorial = () => {
  return (
    <div className="flex flex-col uppercase justify-center h-full">
      <h3 className="mt-0">Welcome to Loot Survivor!</h3>

      {/* <h3 className="text-xl sm:text-2xl">Create an Adventurer</h3> */}
      <p className="text-sm sm:text-lg">
        You will first need to create your Adventurer. Minting an adventure will
        cost 25 $LORDS with rewards split between the top three players, DAO and
        frontend provider.
      </p>

      <p className="text-sm sm:text-lg">
        To bring your Adventurer to life, you will need to provide some unique
        information.
      </p>

      <p className="text-sm sm:text-lg">
        Once your Adventurer is minted, you will first need to slay the beast
        before you can journey into the mist. Reap the rewards if you manage
        reach prestigious top three highest score.
      </p>
    </div>
  );
};
