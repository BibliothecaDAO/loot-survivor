import React from "react";
import { Button } from "./Button";
import { TwitterIcon } from "./Icons";

interface Props {
  text: string;
}

const TwitterShareButton: React.FC<Props> = ({ text }) => {
  const tweetUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(
    text
  )}`;

  return (
    <Button className="flex flex-row gap-5 items-center animate-pulse">
      <div className="w-10 h-10 flex items-center justify-center">
        <TwitterIcon />
      </div>
      <a href={tweetUrl} target="_blank" rel="noopener noreferrer">
        Share to Twitter
      </a>
    </Button>
  );
};

export default TwitterShareButton;
