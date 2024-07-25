export default function Head() {
  return (
    <>
      <title>Loot Survivor</title>

      <meta charSet="utf-8" />
      <meta content="width=device-width, initial-scale=1" name="viewport" />
      <link
        rel="icon"
        type="image/png"
        sizes="32x32"
        href="/favicon-32x32.png"
      />
      <link
        rel="icon"
        type="image/png"
        sizes="16x16"
        href="/favicon-16x16.png"
      />
      <meta
        name="description"
        content="Loot Survivor is a fully on-chain arcade dungeon crawler game on Starknet."
      />
      <meta property="og:title" content="Loot Survivor" />
      <meta property="og:type" content="website" />
      <meta
        property="og:description"
        content="Loot Survivor is a fully on-chain arcade dungeon crawler game on Starknet."
      />
      <meta property="og:url" content="https://lootsurvivor.io" />
      <meta
        property="og:image"
        content="https://lootsurvivor.io/scenes/intro/beast.png"
      />
      <meta property="og:image:width" content="800" />
      <meta property="og:image:height" content="600" />
      <meta property="og:image:alt" content="Loot Survivor Beast" />

      {/* Twitter Card data */}
      <meta name="twitter:card" content="player" />
      <meta name="twitter:site" content="@LootSurvivor" />
      <meta name="twitter:title" content="Loot Survivor" />
      <meta
        name="twitter:description"
        content="Loot Survivor is a fully on-chain arcade dungeon crawler game on Starknet."
      />
      <meta
        name="twitter:player"
        content="https://lootsurvivor.io/twitter-card.html"
      />
      <meta name="twitter:player:width" content="360" />
      <meta name="twitter:player:height" content="680" />
      <meta
        name="twitter:image"
        content="https://lootsurvivor.io/scenes/intro/beast.png"
      />
      {/* PWA */}
      <link rel="manifest" href="/manifest.json" />
      <meta name="theme-color" content="#33FF33" />
      <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
    </>
  );
}
