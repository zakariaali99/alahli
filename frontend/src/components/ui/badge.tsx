import React from "react"
import { cn } from "@/lib/utils"

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: "success" | "error" | "warning" | "info" | "neutral"
  dot?: boolean
}

export const Badge = ({
  className,
  variant = "neutral",
  dot = false,
  children,
  ...props
}: BadgeProps) => {
  const variantStyles = {
    success: "bg-secondary/10 text-secondary border border-secondary/10",
    error: "bg-destructive/10 text-destructive border border-destructive/10",
    warning: "bg-warning/10 text-warning border border-warning/10",
    info: "bg-accent text-accent-fg border border-accent/20",
    neutral: "bg-muted text-muted-foreground border border-border/30",
  }

  const dotStyles = {
    success: "bg-secondary",
    error: "bg-destructive",
    warning: "bg-warning",
    info: "bg-primary",
    neutral: "bg-muted-foreground",
  }

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold tracking-wide select-none leading-none",
        variantStyles[variant],
        className
      )}
      {...props}
    >
      {dot && (
        <span className="relative flex h-1.5 w-1.5 shrink-0">
          <span className={cn("animate-ping absolute inline-flex h-full w-full rounded-full opacity-75", dotStyles[variant])} />
          <span className={cn("relative inline-flex rounded-full h-1.5 w-1.5", dotStyles[variant])} />
        </span>
      )}
      {children}
    </span>
  )
}
Badge.displayName = "Badge"
