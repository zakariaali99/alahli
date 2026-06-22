import { useQuery } from "@tanstack/react-query"
import { api } from "@/lib/api"

interface Department {
  id: number
  name: string
  name_ar: string
  color: string
  logo: string | null
  is_active: boolean
  created_at: string
}

export function useDepartments() {
  return useQuery({
    queryKey: ["departments"],
    queryFn: () => api.get<{ results: Department[] }>("/departments/"),
  })
}
