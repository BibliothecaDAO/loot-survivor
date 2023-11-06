"use client";

import { ApolloProvider } from "@apollo/client";
import { gameClient, goldenTokenClient } from "@/app/lib/clients";
import "@/app/globals.css";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body
        suppressHydrationWarning={false}
        className="min-h-screen overflow-hidden text-terminal-green bg-conic-to-br to-terminal-black from-terminal-black bezel-container"
      >
        <img
          src="/crt_green_mask.png"
          alt="crt green mask"
          className="absolute w-full pointer-events-none crt-frame hidden sm:block"
        />
        <ApolloProvider client={gameClient}>
          <ApolloProvider client={goldenTokenClient}>{children}</ApolloProvider>
        </ApolloProvider>
      </body>
    </html>
  );
}
