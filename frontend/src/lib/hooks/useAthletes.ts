import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query"
import { api } from "@/lib/api"
import type { PaginatedResponse } from "@/lib/types"

interface Athlete {
  id: number
  membership_number: string
  full_name: string
  phone: string
  parent_phone: string
  birth_date: string
  gender: "male" | "female"
  department: number | null
  department_name: string
  photo: string | null
  qr_code: string | null
  notes: string
  is_active: boolean
  created_at: string
  updated_at: string
}

interface AthleteListParams {
  page?: number
  page_size?: number
  search?: string
  department?: string
  gender?: string
  is_active?: string
  ordering?: string
}

export function useAthletes(params: AthleteListParams = {}) {
  return useQuery({
    queryKey: ["athletes", params],
    queryFn: () => api.get<PaginatedResponse<Athlete>>("/athletes/", params as Record<string, string>),
  })
}

export function useAthlete(id: number) {
  return useQuery({
    queryKey: ["athletes", id],
    queryFn: () => api.get<Athlete>(`/athletes/${id}/`),
    enabled: !!id,
  })
}

export function useCreateAthlete() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (formData: FormData) =>
      api.post<Athlete>("/athletes/", formData, { formData: true }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["athletes"] })
    },
  })
}

export function useUpdateAthlete(id: number) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (data: any) => api.patch<Athlete>(`/athletes/${id}/`, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["athletes"] })
    },
  })
}

export function useDeleteAthlete() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: number) => api.delete(`/athletes/${id}/`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["athletes"] })
    },
  })
}

export function useVerifyAthlete() {
  return useMutation({
    mutationFn: (membershipNumber: string) =>
      api.get<{
        active: boolean
        athlete_id: number
        athlete_name: string
        department: string
        expiry_date: string | null
        membership_number: string
        subscription_id: number | null
      }>(`/athletes/verify/${membershipNumber}/`),
  })
}
