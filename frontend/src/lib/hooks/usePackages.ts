import { useQuery } from "@tanstack/react-query"
import { api } from "@/lib/api"

export interface SubscriptionPackage {
  id: number
  name: string
  description: string
  price: string
  duration_type: "weeks" | "months"
  duration_value: number
  max_athletes: number
  tag: "discount" | "special" | "normal"
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
