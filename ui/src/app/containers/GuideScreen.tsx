import React from "react";
import { Button } from "@/app/components/buttons/Button";
import { DiscordIcon } from "@/app/components/icons/Icons";

export default function GuideScreen() {
  return (
    <div className="overflow-y-auto p-2 table-scroll text-xs sm:text-base sm:text-left h-full">
      <div className="flex justify-center items-center mb-4 self-center flex-col">
        <a
          href="https://survivor-docs.realms.world/"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Button size={"lg"}>Survivor Docs</Button>
        </a>
        <a
          href="https://discord.gg/realmsworld"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Button className="py-2 px-4 animate-pulse hidden sm:flex flex-row gap-2 mt-8">
            Join the Discord <DiscordIcon className="w-5" />
          </Button>
        </a>
      </div>
    </div>
  );
}
