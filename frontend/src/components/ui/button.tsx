import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex shrink-0 items-center justify-center border border-transparent text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/80",
        outline: "border-border bg-background hover:bg-muted hover:text-foreground",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-muted hover:text-foreground",
        destructive: "bg-destructive/10 text-destructive hover:bg-destructive/20",
        link: "text-primary underline-offset-4 hover:underline",
        pill: "rounded-full bg-primary text-primary-foreground hover:bg-primary/80 shadow-md",
        "pill-outline": "rounded-full border-border bg-background hover:bg-muted hover:text-foreground",
      },
      size: {
        default: "h-8 gap-1.5 px-2.5 rounded-lg",
        xs: "h-6 gap-1 px-2 text-xs rounded-lg",
        sm: "h-7 gap-1 px-2.5 text-[0.8rem] rounded-lg",
        lg: "h-9 gap-1.5 px-2.5 rounded-lg",
        "pill-sm": "h-8 gap-1.5 px-4 rounded-full",
        "pill-md": "h-10 gap-2 px-6 rounded-full",
        "pill-lg": "h-12 gap-2.5 px-8 rounded-full text-base",
        icon: "size-8",
        "icon-xs": "size-6",
        "icon-sm": "size-7",
        "icon-lg": "size-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

function Button({ className, variant, size, ...props }: ButtonProps) {
  return (
    <button
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  )
}

export { Button, buttonVariants }
