import React from "react"
import { AlertCircle } from "lucide-react"

type Props = {
  message?: string
  onRetry?: () => void
}

export function ErrorDisplay({ message = "حدث خطأ غير متوقع", onRetry }: Props) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="w-14 h-14 rounded-full bg-error/10 flex items-center justify-center mb-4">
        <AlertCircle className="w-7 h-7 text-error" />
      </div>
      <p className="text-foreground font-semibold mb-1">{message}</p>
      <p className="text-muted-foreground text-sm">يرجى المحاولة مرة أخرى لاحقاً</p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="mt-4 px-5 py-2 bg-primary text-primary-foreground rounded-xl text-sm font-semibold hover:bg-primary/90 transition-all"
        >
          إعادة المحاولة
        </button>
      )}
    </div>
  )
}
