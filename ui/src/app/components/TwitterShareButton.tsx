import React from "react";

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
    <a href={tweetUrl} target="_blank" rel="noopener noreferrer">
      Share to Twitter
    </a>
  );
};

export default TwitterShareButton;
