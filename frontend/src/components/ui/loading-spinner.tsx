import React from "react"

type Props = {
  size?: "sm" | "md" | "lg"
  className?: string
}

const sizeMap = {
  sm: "w-5 h-5 border-2",
  md: "w-8 h-8 border-[3px]",
  lg: "w-12 h-12 border-4",
}

export function LoadingSpinner({ size = "md", className = "" }: Props) {
  return (
    <div className={`flex items-center justify-center ${className}`}>
      <div
        className={`${sizeMap[size]} animate-spin rounded-full border-primary/20 border-t-primary`}
      />
    </div>
  )
}

export function PageLoading() {
  return (
    <div className="min-h-[60vh] flex items-center justify-center">
      <LoadingSpinner size="lg" />
    </div>
  )
}

export function TableSkeleton({ rows = 5, cols = 4 }: { rows?: number; cols?: number }) {
  return (
    <div className="space-y-3">
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="flex gap-4">
          {Array.from({ length: cols }).map((_, j) => (
            <div key={j} className="h-5 bg-muted rounded animate-pulse flex-1" />
          ))}
        </div>
      ))}
    </div>
  )
}
