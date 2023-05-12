import React from "react";
import { Button } from "./Button";

interface Props {
  url: string;
  text: string;
  via?: string;
  hashtags?: string[];
}

const TwitterShareButton: React.FC<Props> = ({ url, text, via, hashtags }) => {
  let tweetUrl = `https://twitter.com/intent/tweet?url=${encodeURIComponent(
    url
  )}&text=${encodeURIComponent(text)}`;

  if (via) {
    tweetUrl += `&via=${encodeURIComponent(via)}`;
  }

  if (hashtags) {
    tweetUrl += `&hashtags=${encodeURIComponent(hashtags.join(","))}`;
  }

  return (
    <Button className="animate-pulse">
      <a href={tweetUrl} target="_blank" rel="noopener noreferrer">
        Share to Twitter
      </a>
    </Button>
  );
};

export default TwitterShareButton;
