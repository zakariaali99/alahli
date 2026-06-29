const API_BASE = import.meta.env.VITE_API_URL || "http://localhost:8000/api"

export function toAbsoluteMediaUrl(url?: string | null): string | null {
  if (!url) return null
  if (url.startsWith("http://") || url.startsWith("https://")) return url

  const origin = API_BASE.replace(/\/api\/?$/, "")
  if (url.startsWith("/")) {
    return `${origin}${url}`
  }
  return `${origin}/${url}`
}
