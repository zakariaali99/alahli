import React, { useState, useEffect, useCallback } from "react"
import { Link, Outlet, useLocation, useNavigate, Navigate } from "react-router-dom"
import { motion, AnimatePresence } from "framer-motion"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import {
  LayoutDashboard,
  Users,
  CreditCard,
  QrCode,
  Bell,
  BarChart3,
  Building2,
  Settings,
  LogOut,
  Search,
  ChevronLeft,
  Menu,
  Dumbbell,
  UserCog,
} from "lucide-react"
import { useAuth } from "@/lib/auth"
import { ErrorBoundary } from "@/components/ui/error-boundary"
import { cn } from "@/lib/utils"

const navItems = [
  { name: "لوحة القيادة", path: "/dashboard", icon: LayoutDashboard },
  { name: "اللاعبين", path: "/dashboard/athletes", icon: Users },
  { name: "الاشتراكات", path: "/dashboard/memberships", icon: CreditCard },
  { name: "الفحص السريع", path: "/dashboard/verify", icon: QrCode },
  { name: "الطلبات الجديدة", path: "/dashboard/registrations", icon: Users },
  { name: "الأكاديميات", path: "/dashboard/academies", icon: Building2 },
  { name: "المدربون", path: "/dashboard/coaches", icon: Dumbbell },
  { name: "الإدارة", path: "/dashboard/staff", icon: UserCog },
  { name: "التنبيهات", path: "/dashboard/notifications", icon: Bell },
  { name: "التقارير", path: "/dashboard/reports", icon: BarChart3 },
]

export default function DashboardLayout() {
  const location = useLocation()
  const navigate = useNavigate()
  const { user, logout, isLoading } = useAuth()
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [isMobile, setIsMobile] = useState(false)
  const [scrolled, setScrolled] = useState(false)

  const handleForcedLogout = useCallback(() => {
    navigate("/login", { replace: true })
  }, [navigate])

  useEffect(() => {
    if (isLoading) return

    if (!user) {
      navigate("/login", { replace: true })
      return
    }

    if (user.role === "athlete" || user.role === "parent") {
      navigate("/user", { replace: true })
    }
  }, [isLoading, user, navigate])

  useEffect(() => {
    window.addEventListener("auth:logout", handleForcedLogout)
    return () => window.removeEventListener("auth:logout", handleForcedLogout)
  }, [handleForcedLogout])

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 10)
    window.addEventListener("scroll", onScroll, { passive: true })
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

  useEffect(() => {
    const onResize = () => {
      const mobile = window.innerWidth < 768
      setIsMobile(mobile)
      setSidebarOpen(!mobile)
    }

    onResize()
    window.addEventListener("resize", onResize)
    return () => window.removeEventListener("resize", onResize)
  }, [])

  useEffect(() => {
    if (isMobile) {
      setSidebarOpen(false)
    }
  }, [location.pathname, isMobile])

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-3">
          <LoadingSpinner size="lg" />
          <span className="text-sm text-muted-foreground">جاري التحميل...</span>
        </div>
      </div>
    )
  }

  if (!user) return <Navigate to="/login" replace />

  const handleLogout = async () => {
    await logout()
    navigate("/login")
  }

  return (
    <div className="min-h-screen bg-background text-foreground flex overflow-x-hidden max-w-[100vw]">
      {/* ── Sidebar ── */}
      <aside
        className={`fixed top-0 right-0 h-screen z-50 flex w-72 md:w-64 flex-col transition-all duration-300 ease-[cubic-bezier(0.22,1,0.36,1)]
          ${sidebarOpen ? "translate-x-0 opacity-100" : "max-md:translate-x-full opacity-0 pointer-events-none"}
          bg-sidebar-bg border-l border-sidebar-border
          shadow-[4px_0_24px_rgba(0,0,0,0.12)]`}
      >
        {/* Sidebar Header */}
        <div className="flex items-center justify-between p-5 border-b border-sidebar-border">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-primary-container flex items-center justify-center text-white font-bold text-sm shadow-lg shrink-0">
              أ
            </div>
            <div className="min-w-0">
              <h2 className="text-sm font-bold text-white truncate">الأهلي للياقة</h2>
              <p className="text-[10px] text-sidebar-fg truncate">نظام إدارة الأداء</p>
            </div>
          </div>
          <Button
            onClick={() => setSidebarOpen(false)}
            variant="ghost"
            size="icon-xs"
            className="text-sidebar-fg hover:text-white"
          >
            <ChevronLeft className="w-4 h-4" />
          </Button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto p-3 space-y-1">
          {navItems.map((item) => {
            const isActive = location.pathname === item.path
            const Icon = item.icon
            return (
              <Link
                key={item.path}
                to={item.path}
                onClick={() => {
                  if (isMobile) setSidebarOpen(false)
                }}
                className={cn(
                  "relative flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-colors duration-200 group z-10",
                  isActive
                    ? "text-sidebar-item-active-fg font-semibold"
                    : "text-sidebar-fg hover:text-white"
                )}
              >
                {isActive && (
                  <motion.div
                    layoutId="activeNav"
                    className="absolute inset-0 bg-sidebar-item-active rounded-xl -z-10"
                    transition={{ type: "spring", stiffness: 380, damping: 30 }}
                  />
                )}
                <Icon className={cn("w-5 h-5 shrink-0 transition-colors", isActive ? "text-white" : "text-sidebar-fg group-hover:text-white")} />
                <span>{item.name}</span>
              </Link>
            )
          })}
        </nav>

        {/* Bottom Section */}
        <div className="p-3 border-t border-sidebar-border space-y-1">
          <Link
            to="/dashboard/settings"
            className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-all duration-200 ${
              location.pathname === "/dashboard/settings"
                ? "bg-sidebar-item-active text-sidebar-item-active-fg font-semibold shadow-sm"
                : "text-sidebar-fg hover:bg-sidebar-item-hover hover:text-white"
            }`}
          >
            <Settings className="w-5 h-5 shrink-0" />
            <span>الإعدادات</span>
          </Link>
          <Button
            onClick={handleLogout}
            variant="ghost"
            size="lg"
            className="w-full justify-start text-error hover:bg-error/10 hover:text-error"
          >
            <LogOut className="w-5 h-5 shrink-0" />
            <span>تسجيل الخروج</span>
          </Button>
        </div>
      </aside>

      {isMobile && sidebarOpen && (
        <button
          aria-label="close-sidebar"
          className="fixed inset-0 z-40 bg-black/40 md:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* ── Sidebar Open Trigger ── */}
      {isMobile && !sidebarOpen && (
        <Button
          onClick={() => setSidebarOpen(true)}
          variant="ghost"
          size="icon"
          className="fixed top-4 right-4 z-50 bg-sidebar-bg text-white shadow-lg hover:bg-sidebar-item-hover"
        >
          <Menu className="w-5 h-5" />
        </Button>
      )}

      {/* ── Ambient Background Decorations ── */}
      <div className="fixed inset-0 pointer-events-none -z-10 overflow-hidden">
        <div className="absolute -top-[20%] -right-[10%] w-[60vw] h-[60vw] rounded-full bg-primary/[0.03] blur-[120px]" />
        <div className="absolute -bottom-[15%] -left-[10%] w-[40vw] h-[40vw] rounded-full bg-secondary/[0.03] blur-[100px]" />
      </div>

      {/* ── Main Content ── */}
      <div className={`flex-1 flex flex-col min-h-screen min-w-0 transition-all duration-300 ${sidebarOpen ? "md:mr-64" : "md:mr-0"}`}>
        {/* ── Floating Header ── */}
        <header
          className={`sticky top-0 z-30 transition-all duration-300 ${
            scrolled
              ? "bg-white/85 dark:bg-card/85 backdrop-blur-xl shadow-sm"
              : "bg-transparent"
          }`}
        >
          <div className="flex flex-wrap items-center justify-between gap-3 px-4 py-3 md:h-16 md:px-6 md:py-0">
            {/* Left: Breadcrumb / Page title area */}
            <div className="flex w-full items-center gap-3 md:w-auto">
              {!sidebarOpen && (
                <Button
                  onClick={() => setSidebarOpen(true)}
                  variant="ghost"
                  size="icon"
                >
                  <Menu className="w-5 h-5" />
                </Button>
              )}
              <div className="hidden w-full md:block md:w-64 lg:w-80">
                <Input
                  className="bg-surface-container-low/50"
                  placeholder="ابحث عن لاعب أو اشتراك..."
                  icon={<Search className="w-4 h-4 text-muted-foreground" />}
                />
              </div>
            </div>

            {/* Right: Actions */}
            <div className="mr-auto flex items-center gap-3 md:mr-0">
              <div className="flex items-center gap-2.5">
                <div className="hidden text-left sm:block">
                  <p className="text-sm font-semibold text-foreground leading-tight">
                    {user.full_name_ar || "المسؤول"}
                  </p>
                  <p className="text-[11px] text-muted-foreground">
                    {user.role === "super_admin" ? "مدير النظام" : user.role === "reception" ? "موظف استقبال" : user.role === "academy_manager" ? "مدير الأكاديمية" : "مشاهد"}
                  </p>
                </div>
                <div className="w-9 h-9 rounded-full bg-gradient-to-br from-primary to-primary-container flex items-center justify-center text-white font-bold text-sm shadow-md shrink-0">
                  {user.full_name_ar?.charAt(0) || "م"}
                </div>
              </div>
            </div>
          </div>
        </header>

        {/* ── Page Content ── */}
        <main className="flex-1 px-3 pb-8 pt-4 md:px-6 md:pt-6">
          <div className="max-w-7xl mx-auto">
            <AnimatePresence mode="wait">
              <motion.div
                key={location.pathname}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -12 }}
                transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
              >
                <ErrorBoundary>
                  <Outlet />
                </ErrorBoundary>
              </motion.div>
            </AnimatePresence>
          </div>
        </main>
      </div>
    </div>
  )
}
