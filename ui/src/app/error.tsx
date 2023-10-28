"use client";

import Image from "next/image";

export default function ErrorPage() {
  return (
    <div>
      <Image src={"/scenes/intro/opening.png"} alt="Error Page" fill={true} />
      <div className="absolute inset-0 bg-black opacity-50" />
      <div className="fixed inset-0 flex flex-col items-center justify-center text-center h-full gap-10">
        <p className="sm:text-6xl text-terminal-yellow">
          ERROR: You have been vanquished by an unexpected bug!
        </p>
        <p className="sm:text-2xl">
          You have strayed into the accursed realm of Errors and Glitches. Seek
          the guidance of a wise developer to overcome this treacherous path.
        </p>
        <p className="sm:text-2xl">
          May the code be with you, brave adventurer!
        </p>
      </div>
    </div>
  );
}
