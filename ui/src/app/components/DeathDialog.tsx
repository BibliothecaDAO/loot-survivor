import TwitterShareButton from "./TwitterShareButton";

export const DeathDialog = () => {
  return (
    <>
      <div className="fixed top-0 left-0 right-0 bottom-0 opacity-80 bg-terminal-black z-2" />
      <div className="w-1/2 h-3/4 m-auto rounded-lg border-terminal-green bg-terminal-black z-3">
        <TwitterShareButton
          url="https://example.com/my-page"
          text="Check out My Page on Example.com!"
          via="mytwitterhandle"
          hashtags={["Example", "NextJs", "TypeScript"]}
        />
      </div>
    </>
  );
};
