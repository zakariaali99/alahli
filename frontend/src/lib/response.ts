export function extractResults<T>(
  payload: { results?: T[] } | T[] | null | undefined,
): T[] {
  if (!payload) return []
  if (Array.isArray(payload)) return payload
  if (Array.isArray(payload.results)) return payload.results
  return []
}
