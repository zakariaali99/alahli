import type { ReactNode } from "react"
import { useAuth } from "@/lib/auth"
import { can, type Action } from "@/lib/permissions"

interface CanProps {
  action: Action
  fallback?: ReactNode
  children: ReactNode
}

export function Can({ action, fallback = null, children }: CanProps) {
  const { user } = useAuth()
  if (can(user, action)) return <>{children}</>
  return <>{fallback}</>
}
