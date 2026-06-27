const API_BASE = import.meta.env.VITE_API_URL || "http://localhost:8000/api"

interface TokenStore {
  access: string
  refresh: string
}

function getTokens(): TokenStore | null {
  if (typeof window === "undefined") return null
  const access = localStorage.getItem("access_token")
  const refresh = localStorage.getItem("refresh_token")
  if (!access || !refresh) return null
  return { access, refresh }
}

function setTokens(access: string, refresh: string) {
  localStorage.setItem("access_token", access)
  localStorage.setItem("refresh_token", refresh)
}

function clearTokens() {
  localStorage.removeItem("access_token")
  localStorage.removeItem("refresh_token")
  localStorage.removeItem("user")
}

class ApiError extends Error {
  status: number
  data: any

  constructor(message: string, status: number, data?: any) {
    super(message)
    this.status = status
    this.data = data
  }
}

let refreshPromise: Promise<boolean> | null = null

async function refreshTokens(): Promise<boolean> {
  if (refreshPromise) return refreshPromise
  const tokens = getTokens()
  if (!tokens) return false
  refreshPromise = (async () => {
    try {
      const res = await fetch(`${API_BASE}/auth/token/refresh/`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refresh: tokens.refresh }),
      })
      if (!res.ok) return false
      const data = await res.json()
      setTokens(data.access, data.refresh)
      return true
    } catch {
      return false
    } finally {
      refreshPromise = null
    }
  })()
  return refreshPromise
}

async function request<T = any>(
  method: string,
  path: string,
  body?: any,
  opts: { formData?: boolean; skipAuth?: boolean; params?: Record<string, string> } = {},
): Promise<T> {
  const url = new URL(`${API_BASE}${path}`)
  if (opts.params) {
    Object.entries(opts.params).forEach(([k, v]) => {
      if (v != null) url.searchParams.set(k, v)
    })
  }

  const headers: Record<string, string> = {}
  if (!opts.formData) {
    headers["Content-Type"] = "application/json"
  }

  if (!opts.skipAuth) {
    const tokens = getTokens()
    if (tokens) {
      headers["Authorization"] = `Bearer ${tokens.access}`
    }
  }

  let fetchBody: BodyInit | undefined
  if (body !== undefined) {
    fetchBody = opts.formData ? body : JSON.stringify(body)
  }

  let res = await fetch(url.toString(), { method, headers, body: fetchBody })

  if (res.status === 401 && !opts.skipAuth) {
    const refreshed = await refreshTokens()
    if (refreshed) {
      const tokens = getTokens()
      headers["Authorization"] = `Bearer ${tokens!.access}`
      res = await fetch(url.toString(), { method, headers, body: fetchBody })
    } else {
      clearTokens()
      window.dispatchEvent(new CustomEvent("auth:logout"))
      throw new ApiError("Session expired", 401)
    }
  }

  if (res.status === 204) return undefined as T

  let data: any
  try {
    data = await res.json()
  } catch {
    throw new ApiError(`Server returned ${res.status} with non-JSON response`, res.status)
  }

  if (!res.ok) {
    const detail = data.detail || Object.values(data).flat().join(", ") || "Unknown error"
    throw new ApiError(detail, res.status, data)
  }

  return data as T
}

export const api = {
  get: <T = any>(path: string, params?: Record<string, string>) =>
    request<T>("GET", path, undefined, { params }),
  post: <T = any>(path: string, body?: any, opts?: { formData?: boolean; skipAuth?: boolean }) =>
    request<T>("POST", path, body, opts),
  put: <T = any>(path: string, body?: any, opts?: { formData?: boolean }) =>
    request<T>("PUT", path, body, opts),
  patch: <T = any>(path: string, body?: any, opts?: { formData?: boolean }) =>
    request<T>("PATCH", path, body, opts),
  delete: <T = any>(path: string) => request<T>("DELETE", path),
  setTokens,
  clearTokens,
  getTokens,
  ApiError,
}

export type { TokenStore }
