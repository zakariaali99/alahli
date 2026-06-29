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

export function useDashboardStats(academyId?: number) {
  return useQuery({
    queryKey: ["analytics", "stats", academyId],
    queryFn: () => api.get<DashboardStats>("/analytics/stats/", academyId ? { academy_id: String(academyId) } : {}),
  })
}

export function useMonthlyGrowth(academyId?: number) {
  return useQuery({
    queryKey: ["analytics", "monthly-growth", academyId],
    queryFn: () => api.get<MonthlyGrowth[]>("/analytics/monthly-growth/", academyId ? { academy_id: String(academyId) } : {}),
  })
}

export function useDepartmentDistribution(academyId?: number) {
  return useQuery({
    queryKey: ["analytics", "department-distribution", academyId],
    queryFn: () => api.get<DepartmentDistribution[]>("/analytics/department-distribution/", academyId ? { academy_id: String(academyId) } : {}),
  })
}

export function useRevenue(academyId?: number) {
  return useQuery({
    queryKey: ["analytics", "revenue", academyId],
    queryFn: () => api.get<RevenueEntry[]>("/analytics/revenue/", academyId ? { academy_id: String(academyId) } : {}),
  })
}
