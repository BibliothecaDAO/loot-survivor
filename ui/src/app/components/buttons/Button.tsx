import * as React from "react";
import Link from "next/link";
import { VariantProps, cva } from "class-variance-authority";
import { cn } from "@/app/lib/utils";
import { soundSelector, useUiSounds } from "@/app/hooks/useUiSound";

const buttonVariants = cva(
  "active:scale-95 inline-flex items-center justify-center font-medium transition-colors focus:outline-none focus:ring-offset-2 disabled:bg-terminal-black disabled:text-terminal-green disabled:pointer-events-none data-[state=open]:bg-slate-100  uppercase font-sans-serif border border-transparent disabled:text-slate-600",
  {
    variants: {
      variant: {
        default:
          "bg-terminal-green text-black hover:bg-terminal-green/80 hover:animate-pulse shadow-inner text-center ",
        destructive: "bg-red-500 text-white hover:bg-red-600",
        outline: "bg-transparent hover:bg-terminal-black text-center",
        subtle: "bg-slate-100 text-slate-900 hover:bg-slate-200",
        ghost:
          "bg-transparent hover:border-terminal-green hover:border text-center",
        link: "bg-transparent underline-offset-4 hover:underline text-slate-900 hover:bg-transparent",
        contrast:
          "bg-black/70 text-terminal-green hover:bg-black/80 hover:animate-pulse text-center disabled:text-slate-300",
        token:
          "bg-terminal-black border-terminal-green hover:bg-terminal-green/20 hover:animate-pulse text-terminal-green",
      },
      size: {
        default: "sm:h-10 px-2 py-1 sm:py-2 sm:px-4 text-xs sm:text-sm",
        xxxs: "h-3 px-1 text-xxs sm:h-3 sm:px-1 sm:text-xs md:h-3 md:px-1 md:text-xxs lg:h-5 lg:px-2 lg:text-xs xl:h-5 xl:px-3 xl:text-xs",
        xxs: "h-4 px-1 text-xs sm:h-5 sm:px-2 sm:text-xs md:h-6 md:px-3 md:text-xs lg:h-7 lg:px-4 lg:text-xs xl:h-8 xl:px-5 xl:text-xs",
        xs: "h-6 px-3 text-xs sm:h-7 sm:px-4 sm:text-sm md:h-8 md:px-5 md:text-sm lg:h-9 lg:px-6 lg:text-sm xl:h-10 xl:px-7 xl:text-sm",
        sm: "h-9 px-3 text-sm sm:h-10 sm:px-4 sm:text-base md:h-11 md:px-5 md:text-base lg:h-12 lg:px-6 lg:text-base xl:h-13 xl:px-7 xl:text-base",
        md: "h-8 px-2 text-sm sm:h-9 sm:px-3 sm:text-base md:h-10 md:px-4 md:text-base lg:h-11 lg:px-5 lg:text-lg xl:h-12 xl:px-6 xl:text-lg",
        lg: "h-11 px-8 text-lg sm:h-12 sm:px-9 sm:text-lg md:h-13 md:px-10 md:text-lg lg:h-14 lg:px-11 lg:text-xl xl:h-15 xl:px-12 xl:text-xl",
        xl: "h-12 px-10 text-xl sm:h-13 sm:px-11 sm:text-2xl md:h-14 md:px-12 md:text-2xl lg:h-15 lg:px-13 lg:text-2xl xl:h-16 xl:px-14 xl:text-2xl",
        fill: "w-full h-full",
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
