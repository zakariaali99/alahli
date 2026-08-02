import { useQuery } from "@tanstack/react-query"
import { api } from "@/lib/api"
import { extractResults } from "@/lib/response"
import type { PaginatedResponse, Department, Sport } from "@/lib/types"

export function useDepartments() {
  return useQuery({
    queryKey: ["departments"],
    queryFn: () => api.get<PaginatedResponse<Department>>("/departments/"),
    staleTime: 5 * 60_000,
  })
}

export function useDepartment(id: number | undefined) {
  return useQuery({
    queryKey: ["departments", id],
    queryFn: () => api.get<Department>(`/departments/${id}/`),
    enabled: !!id,
    staleTime: 5 * 60_000,
  })
}

export function useSports(departmentId: number | undefined) {
  return useQuery({
    queryKey: ["sports", departmentId],
    queryFn: async () => {
      const res = await api.get<{ results: Sport[] } | Sport[]>("/sports/", {
        department: String(departmentId),
      })
      return extractResults(res)
    },
    enabled: !!departmentId,
    staleTime: 60_000,
  })
}
