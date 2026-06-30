import React, { createContext, useContext, useState, useEffect, useCallback } from "react"
import { api } from "./api"

interface User {
  id: number
  phone: string
  first_name_ar: string
  last_name_ar: string
  full_name_ar: string
  role: "super_admin" | "reception" | "trainer" | "athlete" | "parent" | "viewer" | "academy_manager"
  is_active: boolean
  photo: string | null
  academy?: number | null
  academy_name?: string | null
  athlete_detail?: {
    id: number
    membership_number: string
    full_name: string
    phone: string
    birth_date: string
    gender: "male" | "female"
    department: number | null
    department_name: string | null
    photo: string | null
  } | null
}

interface AuthContextType {
  user: User | null
  isLoading: boolean
  isAuthenticated: boolean
  login: (phone: string, password: string) => Promise<User>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const fetchUser = useCallback(async () => {
    try {
      const tokens = api.getTokens()
      if (!tokens) {
        setUser(null)
        return
      }
      const userData = await api.get<User>("/auth/me/")
      setUser(userData)
    } catch {
      setUser(null)
    }
  }, [])

  useEffect(() => {
    fetchUser().finally(() => setIsLoading(false))
  }, [fetchUser])

  const login = useCallback(async (phone: string, password: string) => {
    const data = await api.post<{ access: string; refresh: string; user: User }>(
      "/auth/login/",
      { phone, password },
      { skipAuth: true },
    )
    api.setTokens(data.access, data.refresh)
    setUser(data.user)
    return data.user
  }, [])

  const logout = useCallback(async () => {
    try {
      const tokens = api.getTokens()
      if (tokens) {
        await api.post("/auth/logout/", { refresh: tokens.refresh })
      }
    } catch {
    } finally {
      api.clearTokens()
      setUser(null)
    }
  }, [])

  return (
    <AuthContext.Provider
      value={{ user, isLoading, isAuthenticated: !!user, login, logout }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error("useAuth must be used within AuthProvider")
  return ctx
}
