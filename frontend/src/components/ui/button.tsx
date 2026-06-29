import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex shrink-0 items-center justify-center border border-transparent text-sm font-medium whitespace-nowrap transition-all duration-200 outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 active:scale-[0.97] cursor-pointer",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground shadow-sm shadow-primary/10 hover:bg-primary/90 hover:shadow-md",
        outline: "border-border bg-background hover:bg-surface-container-low hover:text-foreground",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/90",
        ghost: "hover:bg-surface-container-low hover:text-foreground",
        destructive: "bg-destructive/10 text-destructive hover:bg-destructive/20",
        link: "text-primary underline-offset-4 hover:underline",
        pill: "rounded-full bg-primary text-primary-foreground hover:bg-primary/90 shadow-md",
        "pill-outline": "rounded-full border-border bg-background hover:bg-surface-container-low hover:text-foreground",
        glass: "bg-primary/10 border border-primary/20 backdrop-blur-md text-primary hover:bg-primary/20",
      },
      size: {
        default: "h-9 gap-1.5 px-3 rounded-xl",
        xs: "h-7 gap-1 px-2.5 text-xs rounded-xl",
        sm: "h-8 gap-1 px-3 text-[0.8rem] rounded-xl",
        lg: "h-10 gap-1.5 px-4 rounded-xl",
        "pill-sm": "h-8 gap-1.5 px-4 rounded-full",
        "pill-md": "h-10 gap-2 px-6 rounded-full",
        "pill-lg": "h-12 gap-2.5 px-8 rounded-full text-base",
        icon: "size-9 rounded-xl",
        "icon-xs": "size-7 rounded-xl",
        "icon-sm": "size-8 rounded-xl",
        "icon-lg": "size-10 rounded-xl",
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
