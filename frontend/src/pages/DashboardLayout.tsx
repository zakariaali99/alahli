import React, { useState, useEffect } from "react"
import { Link, Outlet, useLocation, useNavigate } from "react-router-dom"
import { motion, AnimatePresence } from "framer-motion"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import {
  LayoutDashboard,
  Users,
  CreditCard,
  QrCode,
  Bell,
  BarChart3,
  Settings,
  LogOut,
  Search,
  ChevronLeft,
  Menu,
  X,
  User,
} from "lucide-react"
import { useAuth } from "@/lib/auth"

const navItems = [
  { name: "لوحة القيادة", path: "/dashboard", icon: LayoutDashboard },
  { name: "اللاعبين", path: "/dashboard/athletes", icon: Users },
  { name: "الاشتراكات", path: "/dashboard/memberships", icon: CreditCard },
  { name: "الفحص السريع", path: "/dashboard/verify", icon: QrCode },
  { name: "التنبيهات", path: "/dashboard/notifications", icon: Bell },
  { name: "التقارير", path: "/dashboard/reports", icon: BarChart3 },
]

export default function DashboardLayout() {
  const location = useLocation()
  const navigate = useNavigate()
  const { user, logout, isAuthenticated, isLoading } = useAuth()
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      navigate("/login", { replace: true })
    }
  }, [isLoading, isAuthenticated, navigate])

  useEffect(() => {
    const handler = () => navigate("/login", { replace: true })
    window.addEventListener("auth:logout", handler)
    return () => window.removeEventListener("auth:logout", handler)
  }, [navigate])

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 10)
    window.addEventListener("scroll", onScroll, { passive: true })
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

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

  if (!user) return null

  const handleLogout = async () => {
    await logout()
    navigate("/login")
  }

  return (
    <div className="min-h-screen bg-background text-foreground flex">
      {/* ── Sidebar ── */}
      <aside
        className={`fixed top-0 right-0 h-screen z-50 flex flex-col transition-all duration-300 ease-[cubic-bezier(0.22,1,0.36,1)]
          ${sidebarOpen ? "w-64 opacity-100 visible" : "w-0 -right-64 opacity-0 invisible pointer-events-none overflow-hidden"}
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
        <nav className="flex-1 overflow-y-auto p-3 space-y-0.5">
          {navItems.map((item) => {
            const isActive = location.pathname === item.path
            const Icon = item.icon
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-all duration-200 group ${
                  isActive
                    ? "bg-sidebar-item-active text-sidebar-item-active-fg font-semibold shadow-sm"
                    : "text-sidebar-fg hover:bg-sidebar-item-hover hover:text-white"
                }`}
              >
                <Icon className={`w-5 h-5 shrink-0 ${isActive ? "text-primary dark:text-primary" : ""}`} />
                <span>{item.name}</span>
                {isActive && (
                  <div className="mr-auto w-1 h-5 rounded-full bg-primary dark:bg-primary" />
                )}
              </Link>
            )
          })}
        </nav>

        {/* Bottom Section */}
        <div className="p-3 border-t border-sidebar-border space-y-1">
          <Button
            variant="ghost"
            size="lg"
            className="w-full justify-start text-sidebar-fg hover:text-white hover:bg-sidebar-item-hover text-sm"
          >
            <span className="w-5 h-5 shrink-0 flex items-center justify-center text-base">⇄</span>
            <span>تبديل الأكاديمية</span>
          </Button>
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

      {/* ── Sidebar Overlay (mobile) ── */}
      {!sidebarOpen && (
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
      <div className={`flex-1 flex flex-col min-h-screen transition-all duration-300 ${sidebarOpen ? "mr-64" : "mr-0"}`}>
        {/* ── Floating Header ── */}
        <header
          className={`sticky top-0 z-30 transition-all duration-300 ${
            scrolled
              ? "bg-white/85 dark:bg-card/85 backdrop-blur-xl shadow-sm"
              : "bg-transparent"
          }`}
        >
          <div className="flex items-center justify-between px-6 h-16">
            {/* Left: Breadcrumb / Page title area */}
            <div className="flex items-center gap-3">
              {!sidebarOpen && (
                <Button
                  onClick={() => setSidebarOpen(true)}
                  variant="ghost"
                  size="icon"
                >
                  <Menu className="w-5 h-5" />
                </Button>
              )}
              <div className="relative w-64 sm:w-80">
                <Search className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 pointer-events-none" />
                <input
                  className="w-full bg-surface-container-low border border-border/40 rounded-xl py-2 pr-9 pl-3 text-sm text-foreground placeholder:text-muted-foreground focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all outline-none"
                  placeholder="ابحث عن لاعب أو اشتراك..."
                  type="text"
                />
              </div>
            </div>

            {/* Right: Actions */}
            <div className="flex items-center gap-3">
              <Button variant="ghost" size="icon" className="relative">
                <Bell className="w-5 h-5" />
                <span className="absolute top-2 right-2 w-2 h-2 bg-destructive rounded-full ring-2 ring-white dark:ring-card" />
              </Button>
              <div className="flex items-center gap-2.5 pr-3 border-r border-border/40">
                <div className="text-left">
                  <p className="text-sm font-semibold text-foreground leading-tight">
                    {user.full_name_ar || "المسؤول"}
                  </p>
                  <p className="text-[11px] text-muted-foreground">
                    {user.role === "super_admin" ? "مدير النظام" : user.role === "reception" ? "موظف استقبال" : "مشاهد"}
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
        <main className="flex-1 px-6 pb-8 pt-6">
          <div className="max-w-7xl mx-auto">
            <AnimatePresence mode="wait">
              <motion.div
                key={location.pathname}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -12 }}
                transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
              >
                <Outlet />
              </motion.div>
            </AnimatePresence>
          </div>
        </main>
      </div>
    </div>
  )
}
