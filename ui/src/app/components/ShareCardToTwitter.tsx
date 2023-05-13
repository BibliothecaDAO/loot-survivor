import html2canvas from "html2canvas";

export async function shareCardToTwitter(
  cardRef: React.RefObject<HTMLDivElement>
) {
  const cardElement = cardRef.current;

  if (!cardElement) {
    console.error(`Table not found.`);
    return;
  }

  // Convert the HTML table to a canvas element
  const canvas = await html2canvas(cardElement);

  // Convert the canvas to a Blob
  const blob = await new Promise<Blob>((resolve, reject) =>
    canvas.toBlob((blob) => {
      if (blob) {
        resolve(blob);
      } else {
        reject(new Error("Error converting canvas to Blob."));
      }
    }, "image/png")
  );

  // Create a FormData object to hold the Blob
  const formData = new FormData();
  formData.append("file", blob);

  const uploadPreset = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET;
  const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME;

  if (!uploadPreset || !cloudName) {
    console.error("Missing Cloudinary configuration");
    return;
  }

  formData.append("upload_preset", uploadPreset);

  // Send the image to Cloudinary
  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${cloudName}/upload`,
    {
      // replace with your Cloudinary Cloud Name
      method: "POST",
      body: formData,
    }
  );

  if (!response.ok) {
    const errorResponse = await response.json();
    console.error("Error response from Cloudinary:", errorResponse);
    throw new Error("Network response was not ok");
  }

  const responseData = await response.json();
  const imageUrl = responseData.secure_url;

  // // Step 1: Generate the social card
  // const cardResponse = await fetch("https://api.socialcardservice.com/cards", {
  //   method: "POST",
  //   headers: {
  //     "Content-Type": "application/json",
  //     Authorization: `Bearer ${process.env.SOCIAL_CARD_SERVICE_API_KEY}`,
  //   },
  //   body: JSON.stringify({ imageUrl }),
  // });

  // if (!cardResponse.ok) {
  //   console.error("Error creating social card:", await cardResponse.text());
  //   return;
  // }

  // const cardData = await cardResponse.json();
  // const cardUrl = cardData.cardUrl;

  // Step 2: Share the card URL on Twitter
  const text = `Check out this awesome table: ${imageUrl}`;
  const tweetUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(
    text
  )}`;

  window.open(tweetUrl, "_blank", "noopener noreferrer");
}
