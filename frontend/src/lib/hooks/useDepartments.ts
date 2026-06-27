import { useQuery } from "@tanstack/react-query"
import { api } from "@/lib/api"
import type { PaginatedResponse, Department } from "@/lib/types"

export function useDepartments() {
  return useQuery({
    queryKey: ["departments"],
    queryFn: () => api.get<PaginatedResponse<Department>>("/departments/"),
  })
}
