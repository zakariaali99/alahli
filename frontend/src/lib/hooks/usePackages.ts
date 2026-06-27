import { useQuery } from "@tanstack/react-query"
import { api } from "@/lib/api"

export interface SubscriptionPackage {
  id: number
  name: string
  description: string
  price: string
  duration_days: number
  features: string[]
  icon_name: string
  color_class: string
  is_active: boolean
  order: number
}

export function usePackages() {
  return useQuery({
    queryKey: ["packages"],
    queryFn: () => api.get<{ count: number; results: SubscriptionPackage[] }>("/packages/"),
  })
}
