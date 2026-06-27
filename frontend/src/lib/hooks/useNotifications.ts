import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query"
import { api } from "@/lib/api"
import type { PaginatedResponse } from "@/lib/types"

interface Notification {
  id: number
  athlete: number | null
  title: string
  body: string
  is_read: boolean
  created_at: string
}

interface NotificationListParams {
  page?: number
  page_size?: number
  is_read?: string
  ordering?: string
}

export function useNotifications(params: NotificationListParams = {}) {
  return useQuery({
    queryKey: ["notifications", params],
    queryFn: () => api.get<PaginatedResponse<Notification>>("/notifications/", params as Record<string, string>),
  })
}

export function useCreateNotification() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (data: { title: string; body: string; athlete?: number | null }) =>
      api.post<Notification>("/notifications/", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["notifications"] })
    },
  })
}

export function useMarkNotificationRead() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: number) => api.post<Notification>(`/notifications/${id}/mark_read/`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["notifications"] })
    },
  })
}

export function useMarkAllNotificationsRead() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: () => api.post<{ detail: string }>("/notifications/mark_all_read/"),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["notifications"] })
    },
  })
}

export function useDeleteNotification() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: number) => api.delete(`/notifications/${id}/`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["notifications"] })
    },
  })
}
