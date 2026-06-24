import { useQuery } from "@tanstack/react-query"
import { api } from "@/lib/api"

interface DashboardStats {
  total_athletes: number
  active_memberships: number
  expired_memberships: number
  expiring_soon: number
  new_this_month: number
  total_revenue: number
  renewal_rate: number
}

interface MonthlyGrowth {
  month: string
  count: number
}

interface DepartmentDistribution {
  department__name_ar: string
  count: number
}

interface RevenueEntry {
  month: string
  revenue: number
}

export function useDashboardStats() {
  return useQuery({
    queryKey: ["analytics", "stats"],
    queryFn: () => api.get<DashboardStats>("/analytics/stats/"),
  })
}

export function useMonthlyGrowth() {
  return useQuery({
    queryKey: ["analytics", "monthly-growth"],
    queryFn: () => api.get<MonthlyGrowth[]>("/analytics/monthly-growth/"),
  })
}

export function useDepartmentDistribution() {
  return useQuery({
    queryKey: ["analytics", "department-distribution"],
    queryFn: () => api.get<DepartmentDistribution[]>("/analytics/department-distribution/"),
  })
}

export function useRevenue() {
  return useQuery({
    queryKey: ["analytics", "revenue"],
    queryFn: () => api.get<RevenueEntry[]>("/analytics/revenue/"),
  })
}
