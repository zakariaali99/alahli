export function extractResults<T>(
  payload: { results?: T[]; data?: T[] } | T[] | null | undefined,
): T[] {
  if (!payload) return []
  if (Array.isArray(payload)) return payload
  if (Array.isArray(payload.results)) return payload.results
  if (Array.isArray(payload.data)) return payload.data
  return []
}
