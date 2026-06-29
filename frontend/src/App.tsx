import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { useState } from "react"
import { AuthProvider } from "@/lib/auth"
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom"
import Login from "@/pages/Login"
import Landing from "@/pages/Landing"
import RegisterAthlete from "@/pages/RegisterAthlete"
import RegisterParent from "@/pages/RegisterParent"
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
import UserDashboardLayout from "@/pages/UserDashboardLayout"
import SubscriptionPage from "@/pages/SubscriptionPage"
import AthletePage from "@/pages/AthletePage"
import NewAthletes from "@/pages/admin/NewAthletes"
import AcademyManagement from "@/pages/admin/AcademyManagement"
import AdminNotifications from "@/pages/admin/AdminNotifications"
import StaffManagement from "@/pages/admin/StaffManagement"
import CoachesManagement from "@/pages/admin/CoachesManagement"
import { ToastProvider } from "@/lib/toast"

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
        <ToastProvider>
          <BrowserRouter>
            <Routes>
              <Route path="/" element={<Landing />} />
              <Route path="/login" element={<Login />} />
              <Route path="/register/athlete" element={<RegisterAthlete />} />
              <Route path="/register/parent" element={<RegisterParent />} />

              <Route path="/dashboard" element={<DashboardLayout />}>
                <Route index element={<DashboardHome />} />
                <Route path="athletes" element={<AthletesList />} />
                <Route path="athletes/add" element={<AddAthlete />} />
                <Route path="athletes/:id" element={<AthleteProfile />} />
                <Route path="memberships" element={<Memberships />} />
                <Route path="verify" element={<Verify />} />
                <Route path="reports" element={<Reports />} />
                <Route path="settings" element={<Settings />} />
                <Route path="registrations" element={<NewAthletes />} />
                <Route path="academies" element={<AcademyManagement />} />
                <Route path="staff" element={<StaffManagement />} />
                <Route path="coaches" element={<CoachesManagement />} />
                <Route path="notifications" element={<AdminNotifications />} />
                <Route path="notification-preferences" element={<Notifications />} />
                <Route path="admin-notifications" element={<Navigate to="/dashboard/notifications" replace />} />
              </Route>

              <Route path="/user" element={<UserDashboardLayout />}>
                <Route index element={<SubscriptionPage />} />
                <Route path="athlete" element={<AthletePage />} />
              </Route>

              <Route path="*" element={<Navigate to="/login" replace />} />
            </Routes>
          </BrowserRouter>
        </ToastProvider>
      </AuthProvider>
    </QueryClientProvider>
  )
}
