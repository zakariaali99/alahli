import { useCallback, useEffect } from "react"
import { Outlet, useNavigate, useLocation, Link, Navigate } from "react-router-dom"
import { motion, AnimatePresence } from "framer-motion"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { CreditCard, User, LogOut, Bell } from "lucide-react"
import { useAuth } from "@/lib/auth"
import { ErrorBoundary } from "@/components/ui/error-boundary"

const tabs = [
  { name: "الاشتراكات", path: "/user", icon: CreditCard },
  { name: "الرياضيون", path: "/user/athlete", icon: User },
]

export default function UserDashboardLayout() {
  const location = useLocation()
  const navigate = useNavigate()
  const { user, logout, isLoading } = useAuth()

  const handleForcedLogout = useCallback(() => {
    navigate("/login", { replace: true })
  }, [navigate])

  useEffect(() => {
    if (isLoading) return

    if (!user) {
      navigate("/login", { replace: true })
      return
    }

    if (user.is_superuser || user.role === "super_admin" || user.role === "reception") {
      navigate("/dashboard", { replace: true })
    }
  }, [isLoading, user, navigate])

  useEffect(() => {
    window.addEventListener("auth:logout", handleForcedLogout)
    return () => window.removeEventListener("auth:logout", handleForcedLogout)
  }, [handleForcedLogout])

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!user) return <Navigate to="/login" replace />

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <header className="sticky top-0 z-30 bg-card/90 backdrop-blur-xl border-b border-border">
        <div className="flex items-center justify-between px-4 h-14 max-w-2xl mx-auto w-full">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center text-white font-bold text-xs">
              أ
            </div>
            <span className="font-bold text-sm">الأهلي الرياضي</span>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="ghost" size="icon-xs" onClick={logout}>
              <LogOut className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-2xl mx-auto w-full px-3 py-4 pb-24 sm:px-4">
        <AnimatePresence mode="wait">
          <motion.div
            key={location.pathname}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.2 }}
          >
            <ErrorBoundary>
              <Outlet />
            </ErrorBoundary>
          </motion.div>
        </AnimatePresence>
      </main>

      <nav className="fixed bottom-0 left-0 right-0 z-30 bg-card/95 backdrop-blur-xl border-t border-border">
        <div className="flex max-w-2xl mx-auto w-full">
          {tabs.map((tab) => {
            const isActive = location.pathname === tab.path
            const Icon = tab.icon
            return (
              <Link
                key={tab.path}
                to={tab.path}
                className={`flex-1 flex flex-col items-center py-2 text-xs transition-colors ${
                  isActive ? "text-primary font-semibold" : "text-muted-foreground"
                }`}
              >
                <Icon className="w-5 h-5 mb-0.5" />
                {tab.name}
              </Link>
            )
          })}
        </div>
      </nav>
    </div>
  )
}
