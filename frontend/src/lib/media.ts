import { API_BASE } from "./api"

export function toAbsoluteMediaUrl(url?: string | null): string | null {
  if (!url) return null
  if (url.startsWith("http://") || url.startsWith("https://")) return url

  const origin = API_BASE.replace(/\/api\/?$/, "")
  if (url.startsWith("/")) {
    return `${origin}${url}`
  }
  return `${origin}/${url}`
}
