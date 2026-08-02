import { useQuery } from "@tanstack/react-query"
import { api } from "@/lib/api"

export interface SubscriptionPackage {
  id: number
  name: string
  description: string
  price: string
  new_price: string
  renewal_price: string
  package_type: "monthly" | "multi_month" | "single_session"
  duration_type: "weeks" | "months"
  duration_value: number
  max_athletes: number
  tag: "discount" | "special" | "normal"
  features: string[]
  icon_name?: string
  color_class?: string
  is_active: boolean
  order: number
  department: number | null
  department_name: string | null
}

export function usePackages(department?: string) {
  return useQuery({
    queryKey: ["packages", department ?? "all"],
    queryFn: () =>
      api.get<{ count: number; results: SubscriptionPackage[] }>(
        "/packages/",
        department ? { department } : undefined,
      ),
  })
}
