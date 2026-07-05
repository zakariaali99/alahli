import { useAuth } from "@/lib/auth"
import { can, type Action } from "@/lib/permissions"

export function useCan() {
  const { user } = useAuth()
  return (action: Action) => can(user, action)
}
