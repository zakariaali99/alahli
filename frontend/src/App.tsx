import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { useState } from "react"
import { AuthProvider } from "@/lib/auth"
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom"
import Login from "@/pages/Login"
import DashboardLayout from "@/pages/DashboardLayout"
import DashboardHome from "@/pages/DashboardHome"
import AthletesList from "@/pages/AthletesList"
import AthleteProfile from "@/pages/AthleteProfile"
import AddAthlete from "@/pages/AddAthlete"
import Memberships from "@/pages/Memberships"
import Verify from "@/pages/Verify"
import Notifications from "@/pages/Notifications"
import Reports from "@/pages/Reports"
import Settings from "@/pages/Settings"

export default function App() {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: { queries: { staleTime: 30_000, retry: 1 } },
      }),
  )

  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/" element={<DashboardLayout />}>
              <Route index element={<DashboardHome />} />
              <Route path="athletes" element={<AthletesList />} />
              <Route path="athletes/add" element={<AddAthlete />} />
              <Route path="athletes/:id" element={<AthleteProfile />} />
              <Route path="memberships" element={<Memberships />} />
              <Route path="verify" element={<Verify />} />
              <Route path="notifications" element={<Notifications />} />
              <Route path="reports" element={<Reports />} />
              <Route path="settings" element={<Settings />} />
            </Route>
            <Route path="*" element={<Navigate to="/login" replace />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  )
}
