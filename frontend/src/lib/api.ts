if (!import.meta.env.VITE_API_URL) {
  console.warn("VITE_API_URL not set — using localhost fallback. Set it in .env or build arg for production.")
}
export const API_BASE = import.meta.env.VITE_API_URL || "http://localhost:8000/api"

const REQUEST_TIMEOUT_MS = 15_000

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

function collectErrorMessages(value: unknown): string[] {
  if (value == null) return []
  if (typeof value === "string") return value.trim() ? [value] : []
  if (typeof value === "number" || typeof value === "boolean") return [String(value)]
  if (Array.isArray(value)) {
    return value.flatMap((item) => collectErrorMessages(item))
  }
  if (typeof value === "object") {
    return Object.values(value as Record<string, unknown>).flatMap((item) => collectErrorMessages(item))
  }
  return []
}

let refreshPromise: Promise<boolean> | null = null

async function refreshTokens(): Promise<boolean> {
  if (refreshPromise) return refreshPromise
  const tokens = getTokens()
  if (!tokens) return false
  refreshPromise = (async () => {
    try {
      const res = await fetchWithTimeout(`${API_BASE}/auth/token/refresh/`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refresh: tokens.refresh }),
      })
      if (!res.ok) {
        clearTokens()
        return false
      }
      const data = await res.json()
      setTokens(data.access, data.refresh)
      return true
    } catch {
      clearTokens()
      return false
    } finally {
      refreshPromise = null
    }
  })()
  return refreshPromise
}

async function fetchWithTimeout(url: string, init: RequestInit = {}): Promise<Response> {
  const controller = new AbortController()
  const timeoutId = window.setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)
  try {
    const response = await fetch(url, { ...init, signal: controller.signal })
    return response
  } catch (err: unknown) {
    if (err instanceof DOMException && err.name === "AbortError") {
      throw new ApiError("انتهت مهلة الاتصال بالخادم. حاول مرة أخرى.", 408)
    }
    if (err instanceof TypeError) {
      throw new ApiError("تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.", 0)
    }
    throw err
  } finally {
    window.clearTimeout(timeoutId)
  }
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

  let res: Response
  try {
    res = await fetchWithTimeout(url.toString(), { method, headers, body: fetchBody })
  } catch (err) {
    if (err instanceof ApiError) throw err
    throw new ApiError("تعذر الاتصال بالخادم", 0)
  }

  if (res.status === 401 && !opts.skipAuth) {
    const refreshed = await refreshTokens()
    if (refreshed) {
      const tokens = getTokens()
      headers["Authorization"] = `Bearer ${tokens!.access}`
      res = await fetchWithTimeout(url.toString(), { method, headers, body: fetchBody })
    } else {
      clearTokens()
      window.dispatchEvent(new CustomEvent("auth:logout"))
      throw new ApiError("انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.", 401)
    }
  }

  if (res.status === 204) return undefined as T

  let data: any
  try {
    data = await res.json()
  } catch {
    throw new ApiError(`عاد الخادم باستجابة غير صالحة (${res.status})`, res.status)
  }

  if (!res.ok) {
    const detail = data.detail
    const message = collectErrorMessages(detail).join("\n")
      || collectErrorMessages(data.non_field_errors).join("\n")
      || collectErrorMessages(data).join("\n")
      || "حدث خطأ غير متوقع"
    throw new ApiError(message, res.status, data)
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
