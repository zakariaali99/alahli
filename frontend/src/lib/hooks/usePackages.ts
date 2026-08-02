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
  duration_type: "days" | "weeks" | "months"
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
  sport: number | null
  sport_name: string | null
}

export function usePackages(department?: string, sport?: string) {
  const params: Record<string, string> = {}
  if (department) params.department = department
  if (sport) params.sport = sport

  return useQuery({
    queryKey: ["packages", department ?? "all", sport ?? "all"],
    queryFn: () =>
      api.get<{ count: number; results: SubscriptionPackage[] }>(
        "/packages/",
        Object.keys(params).length > 0 ? params : undefined,
      ),
  })
}
