export default function Head() {
  return (
    <>
      <title>Loot Survivor 💀</title>

      <meta charSet="utf-8" />
      <meta content="width=device-width, initial-scale=1" name="viewport" />
      <link
        rel="icon"
        href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🪦</text></svg>"
      />
      <meta property="og:site_name" content="Loot Survivor" />
      <meta
        name="description"
        content="Loot Survivor is the first Play2Die game from Realms on Starknet."
      />
      <meta property="og:title" content="Loot Survivor" />
      <meta property="og:type" content="website" />
      <meta
        property="og:description"
        content="Loot Survivor is the first Play2Die game from Realms on Starknet."
      />
      <meta property="og:url" content="https://survivor.realms.world" />
      <meta
        property="og:image"
        content="https://survivor.realms.world/scenes/intro/beast.png"
      />
      <meta property="og:image:width" content="800" />
      <meta property="og:image:height" content="600" />
      <meta property="og:image:alt" content="Loot Survivor Beast" />

      {/* Twitter Card data */}
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content="Loot Survivor" />
      <meta
        name="twitter:description"
        content="Loot Survivor is the first Play2Die game from Realms on Starknet."
      />
      <meta name="twitter:site:id" content="1467726470533754880" />
      <meta name="twitter:creator" content="@bibliothecadao" />
      <meta name="twitter:creator:id" content="1467726470533754880" />
      <meta
        name="twitter:image"
        content="https://survivor.realms.world/scenes/intro/beast.png"
      />

      {/* Robots data */}
      <meta name="robots" content="noindex, follow, nocache" />
      <meta
        name="googlebot"
        content="index, nofollow, noimageindex, max-video-preview:-1, max-image-preview:large, max-snippet:-1"
      />
    </>
  );
}
