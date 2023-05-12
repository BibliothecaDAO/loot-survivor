import React from "react";
import { Button } from "./Button";

interface Props {
  text: string;
}

const TwitterShareButton: React.FC<Props> = ({ text }) => {
  const tweetUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(
    text
  )}`;

  return (
    <Button className="animate-pulse">
      <a href={tweetUrl} target="_blank" rel="noopener noreferrer">
        Share to Twitter
      </a>
    </Button>
  );
};

export default TwitterShareButton;
