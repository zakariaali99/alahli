import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query"
import { api } from "@/lib/api"
import type { PaginatedResponse } from "@/lib/types"

interface Renewal {
  id: number
  subscription: number
  amount: string
  months: number
  renewal_date: string
  created_by: number | null
  created_at: string
}

interface Subscription {
  id: number
  athlete: number
  athlete_name: string
  department_name: string
  membership_number: string
  group: number | null
  group_name: string
  start_date: string
  end_date: string
  amount: string
  payment_method: "cash" | "bank_transfer"
  invoice_pdf: string | null
  invoice_pdf_url: string | null
  status: "active" | "expired" | "pending" | "rejected"
  package_name: string
  renewals: Renewal[]
  created_at: string
  updated_at: string
}

interface SubscriptionListParams {
  page?: number
  page_size?: number
  status?: string
  athlete?: string
  search?: string
  ordering?: string
}

export function useSubscriptions(params: SubscriptionListParams = {}) {
  return useQuery({
    queryKey: ["subscriptions", params],
    queryFn: () => api.get<PaginatedResponse<Subscription>>("/subscriptions/", params as Record<string, string>),
  })
}

export function useSubscription(id: number) {
  return useQuery({
    queryKey: ["subscriptions", id],
    queryFn: () => api.get<Subscription>(`/subscriptions/${id}/`),
    enabled: !!id,
  })
}

export function useCreateSubscription() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (data: { athlete: number; start_date: string; end_date: string; amount: string }) =>
      api.post<Subscription>("/subscriptions/", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["subscriptions"] })
    },
  })
}

export function useDeleteSubscription() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: number) => api.delete(`/subscriptions/${id}/`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["subscriptions"] })
    },
  })
}

export function useRenewSubscription() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, months, amount }: { id: number; months: number; amount: string }) =>
      api.post<Subscription>(`/subscriptions/${id}/renew/`, { months, amount }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["subscriptions"] })
    },
  })
}

export function useUpdateSubscription() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, status }: { id: number; status: "active" | "expired" | "pending" | "rejected" }) =>
      api.patch<Subscription>(`/subscriptions/${id}/`, { status }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["subscriptions"] })
    },
  })
}

export type { Subscription, Renewal }
