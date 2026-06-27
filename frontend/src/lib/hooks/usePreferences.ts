import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query"
import { api } from "@/lib/api"

export interface UserPreference {
  id: number
  user: number
  notifications_enabled: boolean
  sms_enabled: boolean
  email_enabled: boolean
  language: string
  theme: string
}

export function usePreferences() {
  return useQuery({
    queryKey: ["preferences"],
    queryFn: () => api.get<UserPreference>("/preferences/"),
  })
}

export function useUpdatePreferences() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data: Partial<UserPreference>) =>
      api.patch<UserPreference>("/preferences/", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["preferences"] })
    },
  })
}
