"use client";

import Image from "next/image";
import { Button } from "@/app/components/buttons/Button";
import { DiscordIcon } from "@/app/components/icons/Icons";

export default function ErrorPage() {
  return (
    <div>
      <Image src={"/scenes/intro/opening.png"} alt="Error Page" fill={true} />
      <div className="absolute inset-0 bg-black opacity-50" />
      <div className="fixed inset-0 flex flex-col items-center justify-center text-center h-full gap-10 p-20">
        <p className="sm:text-6xl text-terminal-yellow">
          ERROR: You have been hit by an unexpected bug!
        </p>
        <p className="sm:text-3xl">
          You have strayed into the accursed realm of Errors and Glitches.
          Refresh or seek the guidance of a wise developer to overcome this
          treacherous path.
        </p>
        <p className="sm:text-2xl">
          May the code be with you, brave adventurer!
        </p>
        <a
          href="https://discord.gg/realmsworld"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Button className="py-2 px-4 animate-pulse hidden sm:flex flex-row gap-2">
            Go to Discord <DiscordIcon className="w-5" />
          </Button>
        </a>
      </div>
    </div>
  );
}
