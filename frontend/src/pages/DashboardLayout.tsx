import React, { useState, useEffect } from "react"
import { Link, Outlet, useLocation, useNavigate } from "react-router-dom"
import { motion, AnimatePresence } from "framer-motion"
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
  Grid,
  TrendingUp,
} from "lucide-react"
import { useAuth } from "@/lib/auth"

export default function DashboardLayout() {
  const location = useLocation()
  const navigate = useNavigate()
  const { user, logout, isAuthenticated, isLoading } = useAuth()
  const [academyTheme, setAcademyTheme] = useState<"ahly" | "aws">("ahly")

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      navigate("/login", { replace: true })
    }
  }, [isLoading, isAuthenticated, navigate])

  useEffect(() => {
    const handler = () => {
      navigate("/login", { replace: true })
    }
    window.addEventListener("auth:logout", handler)
    return () => window.removeEventListener("auth:logout", handler)
  }, [navigate])

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
      </div>
    )
  }

  if (!user) return null

  const handleLogout = async () => {
    await logout()
    navigate("/login")
  }

  const toggleTheme = () => {
    setAcademyTheme((prev) => (prev === "ahly" ? "aws" : "ahly"))
  }

  const menuItems = [
    { name: "لوحة القيادة", path: "/", icon: LayoutDashboard },
    { name: "اللاعبين", path: "/athletes", icon: Users },
    { name: "الاشتراكات", path: "/memberships", icon: CreditCard },
    { name: "الفحص السريع", path: "/verify", icon: QrCode },
    { name: "التنبيهات", path: "/notifications", icon: Bell },
    { name: "التقارير", path: "/reports", icon: BarChart3 },
  ]

  return (
    <div className={`min-h-screen bg-background text-foreground flex flex-col transition-colors duration-300 relative ${academyTheme === "aws" ? "theme-aws" : "theme-ahly"}`}>
      {/* Decorative background */}
      <div className="fixed inset-0 pointer-events-none z-0">
        <div className="absolute inset-0 bg-dot-grid opacity-[0.3]" />
        <div className="absolute inset-0 bg-mesh-gradient" />
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-primary/5 rounded-full blur-3xl animate-float-slow" />
        <div className="absolute bottom-0 right-1/4 w-80 h-80 bg-secondary/5 rounded-full blur-3xl animate-float" style={{ animationDelay: "2s" }} />
      </div>

      <header className="fixed top-0 left-0 right-0 h-16 z-40 bg-white/70 dark:bg-card/70 backdrop-blur-md border-b border-border/40 flex justify-between items-center px-8 w-full pr-[288px] rtl">
        <div className="flex items-center gap-4">
          <div className="relative hidden sm:block">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
            <input
              className="bg-surface-container-low border-none rounded-full py-2 pr-9 pl-4 w-64 text-sm text-foreground placeholder:text-muted-foreground focus:ring-2 focus:ring-primary focus:bg-white transition-all outline-none"
              placeholder="بحث..."
              type="text"
            />
          </div>
        </div>

        <div className="flex items-center gap-6">
          <span className={`font-bold text-lg transition-colors ${academyTheme === 'aws' ? 'text-[#1E7A43]' : 'text-primary'}`}>
            إدارة الرياضة
          </span>
          <div className="flex items-center gap-3 border-r border-border/40 pr-6 mr-2">
            <button className="w-10 h-10 rounded-full flex items-center justify-center text-muted-foreground hover:bg-surface-container hover:text-foreground transition-colors relative">
              <Bell className="w-5 h-5" />
              <span className="absolute top-2.5 right-2.5 w-2 h-2 bg-error rounded-full animate-pulse-soft" />
            </button>
            <button className="w-10 h-10 rounded-full flex items-center justify-center text-muted-foreground hover:bg-surface-container hover:text-foreground transition-colors">
              <Grid className="w-5 h-5" />
            </button>
            <div className="w-10 h-10 rounded-full overflow-hidden border-2 border-primary-container shrink-0 relative bg-gradient-to-br from-primary/20 to-secondary/20 flex items-center justify-center text-primary font-bold text-sm shadow-sm">
              {user.full_name_ar?.charAt(0) || "م"}
            </div>
          </div>
        </div>
      </header>

      <nav className="h-screen w-72 fixed right-0 top-0 border-l border-border/40 bg-white/80 dark:bg-card/85 backdrop-blur-xl flex flex-col p-6 space-y-8 rtl z-50 shadow-lg">
        {/* Logo area with gradient accent */}
        <div className="relative">
          <div className="absolute -top-3 -right-3 w-20 h-20 bg-gradient-to-br from-primary/10 to-secondary/10 rounded-full blur-xl" />
          <div className="flex flex-col items-start gap-4 relative">
            <div className="w-16 h-16 rounded-xl bg-gradient-to-br from-primary to-primary-container text-white flex items-center justify-center shadow-lg shadow-primary/20 relative overflow-hidden">
              <div className="absolute inset-0 bg-white/10" />
              <img
                alt="شعار النادي"
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuDzd-Fz8J0E-KmHaxFHJtcTAs2IbV7LjcEWBB0VFr9qsMife67LAhnwqm0EUiJQf550FSNCPzLJapxFXxNc-m67jHNnqVpAeav8A0qExgnHtMdVPdP1_NgVXu0yXKlbLYfzoPAsPFCwOczVyS_MnYe9hN5JRjoavwDTRwaAvDICgjb_LgGjnZ4N9atlApWPKYZ5zZxe_H_3NcZpR3h1lRHTUF-ftHnSruOZJChFQVzddBoNWeVYijUDreEVARSbOH6Igx4h_32q1_0"
                width={48}
                height={48}
                className="object-contain relative z-10"
              />
            </div>
            <div>
              <h1 className="text-lg font-bold text-foreground">
                {academyTheme === "aws" ? "أكاديمية العوز" : "الأهلي للياقة البدنية"}
              </h1>
              <p className="text-xs text-muted-foreground mt-1">نظام إدارة الأداء الرياضي</p>
            </div>
            <button
              onClick={toggleTheme}
              className="w-full py-2.5 px-4 mt-1 bg-gradient-to-r from-primary/5 to-secondary/5 border border-primary/10 rounded-xl text-primary hover:from-primary/10 hover:to-secondary/10 transition-all flex items-center justify-center gap-2 text-xs font-semibold"
            >
              <TrendingUp className="w-4 h-4" />
              تبديل الأكاديمية
            </button>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto space-y-1">
          {menuItems.map((item, i) => {
            const isActive = location.pathname === item.path
            const Icon = item.icon
            return (
              <motion.div
                key={item.path}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.05, duration: 0.3 }}
              >
                <Link
                  to={item.path}
                  className={`flex items-center justify-between px-4 py-3 rounded-xl transition-all duration-200 group hover:translate-x-[-2px] ${
                    isActive
                      ? "bg-gradient-to-r from-primary to-primary/90 text-primary-foreground font-semibold shadow-md shadow-primary/20"
                      : "text-muted-foreground hover:bg-surface-container hover:text-foreground"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icon className="w-5 h-5" />
                    <span className="text-sm">{item.name}</span>
                  </div>
                  {isActive && <div className="w-1.5 h-1.5 rounded-full bg-white animate-pulse-soft" />}
                </Link>
              </motion.div>
            )
          })}
        </div>

        <div className="pt-4 border-t border-border/40 space-y-1">
          <Link
            to="/settings"
            className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${
              location.pathname === "/settings"
                ? "bg-gradient-to-r from-primary to-primary/90 text-primary-foreground font-semibold shadow-md shadow-primary/20"
                : "text-muted-foreground hover:bg-surface-container hover:text-foreground"
            }`}
          >
            <Settings className="w-5 h-5" />
            <span className="text-sm">الإعدادات</span>
          </Link>
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-4 py-3 text-error hover:bg-error/10 transition-colors rounded-xl text-right"
          >
            <LogOut className="w-5 h-5" />
            <span className="text-sm">تسجيل الخروج</span>
          </button>
        </div>
      </nav>

      <main className="relative z-10 pt-24 pr-[288px] pb-10 pl-8 min-h-screen">
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
  )
}
