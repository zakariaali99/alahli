import { useMutation } from "@tanstack/react-query"
import { api } from "@/lib/api"

export function useLogAttendance() {
  return useMutation({
    mutationFn: (data: { athlete: number; subscription?: number }) =>
      api.post("/attendance/", data),
  })
}
