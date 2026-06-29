import React from "react"
import { cn } from "@/lib/utils"

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  icon?: React.ReactNode
  iconPosition?: "left" | "right"
}

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type = "text", icon, iconPosition = "right", ...props }, ref) => {
    return (
      <div className="relative w-full">
        {icon && iconPosition === "right" && (
          <div className="pointer-events-none absolute right-3.5 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 flex items-center justify-center">
            {icon}
          </div>
        )}
        <input
          type={type}
          ref={ref}
          className={cn(
            "flex w-full bg-surface-container-low border border-border/40 rounded-xl py-2.5 px-3.5 text-sm text-foreground placeholder:text-muted-foreground focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all duration-200 outline-none",
            icon && iconPosition === "right" && "pr-10",
            icon && iconPosition === "left" && "pl-10",
            className
          )}
          {...props}
        />
        {icon && iconPosition === "left" && (
          <div className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 flex items-center justify-center">
            {icon}
          </div>
        )}
      </div>
    )
  }
)
Input.displayName = "Input"

export interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  icon?: React.ReactNode
}

export const Select = React.forwardRef<HTMLSelectElement, SelectProps>(
  ({ className, icon, children, ...props }, ref) => {
    return (
      <div className="relative w-full">
        {icon && (
          <div className="pointer-events-none absolute right-3.5 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 flex items-center justify-center">
            {icon}
          </div>
        )}
        <select
          ref={ref}
          className={cn(
            "flex w-full bg-surface-container-low border border-border/40 rounded-xl py-2.5 px-3.5 text-sm text-foreground placeholder:text-muted-foreground focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all duration-200 outline-none appearance-none",
            icon ? "pr-10" : "pr-3",
            className
          )}
          {...props}
        >
          {children}
        </select>
        <div className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground w-3 h-3 flex items-center justify-center text-[10px]">
          ▼
        </div>
      </div>
    )
  }
)
Select.displayName = "Select"
