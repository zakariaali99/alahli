import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from "react"
import { AlertCircle, CheckCircle2, Info, X } from "lucide-react"

type ToastType = "success" | "error" | "info"

type ToastItem = {
  id: number
  message: string
  type: ToastType
}

type ToastContextType = {
  success: (message: string) => void
  error: (message: string) => void
  info: (message: string) => void
}

const ToastContext = createContext<ToastContextType | undefined>(undefined)

const AUTO_DISMISS_MS = 3200

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([])

  const removeToast = useCallback((id: number) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id))
  }, [])

  const pushToast = useCallback((message: string, type: ToastType) => {
    const id = Date.now() + Math.floor(Math.random() * 1000)
    setToasts((prev) => [...prev, { id, message, type }])
    window.setTimeout(() => removeToast(id), AUTO_DISMISS_MS)
  }, [removeToast])

  const value = useMemo<ToastContextType>(() => ({
    success: (message: string) => pushToast(message, "success"),
    error: (message: string) => pushToast(message, "error"),
    info: (message: string) => pushToast(message, "info"),
  }), [pushToast])

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="pointer-events-none fixed left-4 top-4 z-[120] flex w-[min(92vw,24rem)] flex-col gap-2">
        {toasts.map((toast) => {
          const styleByType: Record<ToastType, string> = {
            success: "border-secondary/30 bg-secondary/10 text-secondary",
            error: "border-error/30 bg-error/10 text-error",
            info: "border-primary/30 bg-primary/10 text-primary",
          }
          const iconByType = {
            success: CheckCircle2,
            error: AlertCircle,
            info: Info,
          }
          const Icon = iconByType[toast.type]

          return (
            <div
              className={`pointer-events-auto flex items-start gap-2 rounded-xl border px-3 py-2 text-sm shadow-lg backdrop-blur ${styleByType[toast.type]}`}
              key={toast.id}
              role="status"
            >
              <Icon className="mt-0.5 h-4 w-4 shrink-0" />
              <p className="flex-1 leading-5">{toast.message}</p>
              <button
                aria-label="dismiss"
                className="rounded-md p-1 opacity-80 transition hover:opacity-100"
                onClick={() => removeToast(toast.id)}
                type="button"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          )
        })}
      </div>
    </ToastContext.Provider>
  )
}

export function useToast() {
  const context = useContext(ToastContext)
  if (!context) {
    throw new Error("useToast must be used within ToastProvider")
  }
  return context
}
