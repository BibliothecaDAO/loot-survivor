"use client";

import * as React from "react";
import { VariantProps, cva } from "class-variance-authority";

import { cn } from "@/app/lib/utils";
import Link from "next/link";
import { soundSelector, useUiSounds } from "../../hooks/useUiSound";

const buttonVariants = cva(
  "active:scale-95 inline-flex items-center justify-center font-medium transition-colors focus:outline-none focus:ring-offset-2 dark:hover:bg-slate-800 dark:hover:text-slate-100 disabled:bg-terminal-black disabled:text-terminal-green dark:focus:ring-slate-400 disabled:pointer-events-none dark:focus:ring-offset-slate-900 data-[state=open]:bg-slate-100 dark:data-[state=open]:bg-slate-800 uppercase font-sans-serif border border-transparent disabled:text-slate-600",
  {
    variants: {
      variant: {
        default:
          "bg-terminal-green text-black hover:bg-terminal-green/80 hover:animate-pulse shadow-inner text-center ",
        destructive:
          "bg-red-500 text-white hover:bg-red-600 dark:hover:bg-red-600",
        outline:
          "bg-transparent hover:bg-terminal-black dark:border-slate-700 dark:text-slate-100 text-center",
        subtle:
          "bg-slate-100 text-slate-900 hover:bg-slate-200 dark:bg-slate-700 dark:text-slate-100",
        ghost:
          "bg-transparent hover:border-terminal-green hover:border text-center",
        link: "bg-transparent dark:bg-transparent underline-offset-4 hover:underline text-slate-900 dark:text-slate-100 hover:bg-transparent dark:hover:bg-transparent",
        contrast:
          "bg-black/70 text-terminal-green hover:bg-black/80 hover:animate-pulse text-center disabled:text-slate-300",
      },
      size: {
        default:
          "sm:h-10 md:h-8 px-2 py-1 sm:py-2 md:py-1 sm:px-4 text-xs sm:text-sm md:text-lg",
        xxs: "h-4 px-1 text-xs",
        xs: "h-6 px-3 text-xs",
        sm: "h-9 px-3 text-sm ",
        md: "h-8 px-2 text-sm",
        lg: "h-11 px-8 text-lg",
        xl: "h-12 px-10 text-xl",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  children: React.ReactNode;
  href?: string;
  loading?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    { children, className, variant, size, href, onClick, loading, ...props },
    ref
  ) => {
    const { play } = useUiSounds(soundSelector.click);

    if (href) {
      return (
        <Link
          className={cn(buttonVariants({ variant, size, className }))}
          href={href}
          target="_blank"
          rel="noopener noreferrer"
        >
          {children}
        </Link>
      );
    }
    return (
      <button
        onClick={(event) => {
          onClick?.(event);
          play();
        }}
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      >
        {children}
      </button>
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };
