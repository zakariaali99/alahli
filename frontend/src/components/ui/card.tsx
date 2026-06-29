import React, { useRef } from "react"
import { cn } from "@/lib/utils"

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: "default" | "glass" | "elevated" | "interactive" | "spotlight"
}

export const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ className, variant = "default", ...props }, ref) => {
    const localRef = useRef<HTMLDivElement>(null)
    const combinedRef = (ref || localRef) as React.RefObject<HTMLDivElement>

    const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
      if (variant !== "spotlight" || !combinedRef.current) return
      const rect = combinedRef.current.getBoundingClientRect()
      const x = e.clientX - rect.left
      const y = e.clientY - rect.top
      combinedRef.current.style.setProperty("--spotlight-x", `${x}px`)
      combinedRef.current.style.setProperty("--spotlight-y", `${y}px`)
    }

    const variantStyles = {
      default: "bg-card text-card-foreground border border-border/40 rounded-3xl",
      glass: "glass-card rounded-3xl",
      elevated: "bg-card text-card-foreground rounded-3xl shadow-[0_10px_30px_rgba(0,0,0,0.04)] border border-border/10",
      interactive: "glass-card glass-card-hover rounded-3xl cursor-pointer",
      spotlight: "glass-card card-spotlight rounded-3xl",
    }

    return (
      <div
        ref={combinedRef}
        onMouseMove={handleMouseMove}
        className={cn(variantStyles[variant], "p-6", className)}
        {...props}
      />
    )
  }
)
Card.displayName = "Card"

export const CardHeader = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn("flex flex-col space-y-1.5 pb-4", className)} {...props} />
)
CardHeader.displayName = "CardHeader"

export const CardTitle = ({ className, ...props }: React.HTMLAttributes<HTMLHeadingElement>) => (
  <h3 className={cn("text-lg font-bold leading-tight text-foreground", className)} {...props} />
)
CardTitle.displayName = "CardTitle"

export const CardDescription = ({ className, ...props }: React.HTMLAttributes<HTMLParagraphElement>) => (
  <p className={cn("text-xs text-muted-foreground", className)} {...props} />
)
CardDescription.displayName = "CardDescription"

export const CardContent = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn("pt-0", className)} {...props} />
)
CardContent.displayName = "CardContent"

export const CardFooter = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn("flex items-center pt-4 border-t border-border/10 mt-4", className)} {...props} />
)
CardFooter.displayName = "CardFooter"
