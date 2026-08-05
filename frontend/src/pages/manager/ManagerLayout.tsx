import React, { useEffect, useCallback } from "react"
import { Link, Outlet, useLocation, useNavigate, useParams } from "react-router-dom"
import { motion, AnimatePresence } from "framer-motion"
import { Button } from "@/components/ui/button"
import { LogOut, ArrowRight, Building } from "lucide-react"
import { useAuth } from "@/lib/auth"
import { ErrorBoundary } from "@/components/ui/error-boundary"
import { roleLabel } from "@/lib/permissions"
import { useDepartment } from "@/lib/hooks/useDepartments"
import { getAcademyLogo } from "@/lib/departments"

export default function ManagerLayout() {
  const location = useLocation()
  const navigate = useNavigate()
  const { user, logout, isLoading } = useAuth()
  const { academyId } = useParams<{ academyId: string }>()
  const numericId = academyId ? Number(academyId) : undefined
  const { data: department } = useDepartment(numericId)
  const academyLogo = getAcademyLogo(department)


  const handleForcedLogout = useCallback(() => {
    navigate("/login", { replace: true })
  }, [navigate])

  useEffect(() => {
    if (isLoading) return

    if (!user) {
      navigate("/login", { replace: true })
      return
    }

    if (user.role !== "special_manager") {
      navigate("/dashboard", { replace: true })
    }
  }, [isLoading, user, navigate])

  useEffect(() => {
    window.addEventListener("auth:logout", handleForcedLogout)
    return () => window.removeEventListener("auth:logout", handleForcedLogout)
  }, [handleForcedLogout])

  const handleLogout = async () => {
    await logout()
    navigate("/login", { replace: true })
  }

  if (isLoading || !user || user.role !== "special_manager") {
    return (
      <div className="flex h-screen items-center justify-center bg-background">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    )
  }

  // Check if we are inside a sub-route (e.g. /manager/4/dashboard)
  const isSubRoute = location.pathname !== "/manager" && location.pathname !== "/manager/"

  const themeColor = department?.color || "#0F4C81"

  return (
    <div className="min-h-screen bg-[#fafafb] text-[#0f2942] font-sans" dir="rtl">
      
      {/* ── Ambient Background Decorations with Dynamic Theme ── */}
      <div className="fixed inset-0 pointer-events-none -z-10 overflow-hidden">
        <div
          className="absolute -top-[20%] -right-[10%] w-[60vw] h-[60vw] rounded-full blur-[120px] transition-colors duration-500"
          style={{ backgroundColor: `${themeColor}12` }}
        />
        <div
          className="absolute -bottom-[15%] -left-[10%] w-[40vw] h-[40vw] rounded-full blur-[100px] transition-colors duration-500"
          style={{ backgroundColor: `${themeColor}08` }}
        />
      </div>

      {/* ── Top Header with Dynamic Theme Accent ── */}
      <header
        className="sticky top-0 z-30 bg-white/85 backdrop-blur-md border-b shadow-xs transition-colors duration-300"
        style={{ borderBottomColor: department ? `${themeColor}35` : "rgba(229, 231, 235, 0.8)" }}
      >
        <div className="mx-auto flex h-16 w-full max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          
          <div className="flex items-center gap-3">
            {isSubRoute && (
              <Button
                onClick={() => {
                  if (location.pathname.includes("/dashboard")) {
                    navigate(numericId ? `/manager/${numericId}/sports` : "/manager")
                  } else {
                    navigate("/manager")
                  }
                }}
                variant="outline"
                size="sm"
                className="gap-1.5 font-bold transition-all"
                style={{ borderColor: `${themeColor}30`, color: themeColor }}
              >
                <ArrowRight className="w-4 h-4" />
                <span>{location.pathname.includes("/dashboard") ? "الرجوع للرياضات" : "الرئيسية"}</span>
              </Button>
            )}
            <Link to="/manager" className="flex items-center gap-2">
              {academyId ? (
                <span
                  className="p-0.5 rounded-lg bg-white border shadow-xs flex items-center justify-center w-8 h-8 shrink-0 overflow-hidden"
                  style={{ borderColor: `${themeColor}40` }}
                >
                  <img 
                    src={academyLogo} 
                    alt="Logo" 
                    className="w-full h-full object-contain" 
                  />
                </span>
              ) : (
                <Building className="w-5 h-5" style={{ color: themeColor }} />
              )}
              <span className="text-base font-extrabold text-[#0f2942]">
                {department ? department.name_ar : "بوابة الإدارة العامة"}
              </span>
            </Link>
          </div>

          <div className="flex items-center gap-4">
            <div className="hidden text-left sm:block text-right">
              <p className="text-sm font-semibold text-foreground leading-tight">
                {user.full_name_ar || "المسؤول"}
              </p>
              <p className="text-[11px] text-muted-foreground font-medium">
                {roleLabel(user.role)} {department ? `— ${department.name_ar}` : ""}
              </p>
            </div>
            <div
              className="w-9 h-9 rounded-full flex items-center justify-center text-white font-bold text-sm shadow-md shrink-0 transition-colors duration-300"
              style={{ backgroundColor: themeColor }}
            >
              {user.full_name_ar?.charAt(0) || "م"}
            </div>
            <Button
              onClick={handleLogout}
              variant="ghost"
              size="sm"
              className="text-error hover:bg-error/10 hover:text-error gap-1.5"
            >
              <LogOut className="w-4 h-4 shrink-0" />
              <span className="hidden sm:inline">تسجيل الخروج</span>
            </Button>
          </div>

        </div>
      </header>

      {/* ── Main Workspace ── */}
      <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
        <AnimatePresence mode="wait" initial={false}>
          <motion.div
            key={location.pathname}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.15 }}
          >
            <ErrorBoundary>
              <Outlet />
            </ErrorBoundary>
          </motion.div>
        </AnimatePresence>
      </main>

    </div>
  )
}
