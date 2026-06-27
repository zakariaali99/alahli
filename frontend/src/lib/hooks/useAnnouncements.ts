import { useQuery } from "@tanstack/react-query"
import { api } from "@/lib/api"

export interface Announcement {
  id: number
  title: string
  body: string
  is_active: boolean
  created_at: string
}

export function useAnnouncements() {
  return useQuery({
    queryKey: ["announcements"],
    queryFn: () => api.get<{ count: number; results: Announcement[] }>("/notifications/announcements/"),
  })
}
