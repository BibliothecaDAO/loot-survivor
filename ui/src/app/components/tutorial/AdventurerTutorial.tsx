export const AdventurerTutorial = () => {
  return (
    <div className="flex flex-col uppercase">
      <h1 className="mt-0">Welcome to Loot Survivor!</h1>
      <br />
      {/* <h3 className="text-xl sm:text-2xl">Create an Adventurer</h3> */}
      <p className="text-sm sm:text-lg">
        You will first need to create your Adventurer. Think of it as stepping
        into a pair of sturdy boots that will carry you across the vast expanses
        of our eerie world until the very end.
      </p>
      <br />
      <p className="text-sm sm:text-lg">
        To bring your Adventurer to life, you will need to provide some unique
        information:
      </p>
      <ul>
        <li>
          <span className="text-xl">Name</span> - A worthy name for a lordly
          adventurer. Max of 16 characters.
        </li>
        <li>
          <span className="text-xl">Home Realm</span> - An id of a realm from
          where your adventurer was born.
        </li>
        <li>
          <span className="text-xl">Race</span> - What race shall your
          adventurer be?
        </li>
        <li>
          <span className="text-xl">Starting Weapon</span> - There are 4 choices
          of starter weapon. Choose wisely!
        </li>
      </ul>
      <br />
      <p className="text-sm sm:text-lg">
        Once your Adventurer is minted, you will be able need to perform actions
        with the hope to climb the ranks, achieve glory and reap the rewards if
        you manage reach prestigious top three highest score.
      </p>
      <br />
      <p className="text-sm sm:text-lg">
        Minting you adventure will cost just 25 $LORDS with rewards split
        between the top three players, DAO and frontend provider.
      </p>
      <br />
      <p className="text-sm sm:text-lg">So... Are you ready to survive?</p>
    </div>
  );
};
