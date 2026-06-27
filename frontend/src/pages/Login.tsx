import React, { useState } from "react"
import { useNavigate } from "react-router-dom"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import {
  Eye,
  EyeOff,
  Lock,
  User,
  AlertCircle,
  ChevronLeft,
  Sparkles,
  GraduationCap,
  ShieldCheck,
} from "lucide-react"
import { useAuth } from "@/lib/auth"

export default function LoginPage() {
  const navigate = useNavigate()
  const { login } = useAuth()
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [phone, setPhone] = useState(() => {
    try { return localStorage.getItem("remembered_phone") || "" } catch { return "" }
  })
  const [password, setPassword] = useState("")
  const [rememberMe, setRememberMe] = useState(() => {
    try { return localStorage.getItem("remember_me") === "true" } catch { return false }
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!phone.trim() || !password.trim()) {
      setErrorMessage("الرجاء إدخال رقم الهاتف وكلمة المرور")
      return
    }
    setIsLoading(true)
    setErrorMessage(null)
    try {
      if (rememberMe) {
        localStorage.setItem("remembered_phone", phone.trim())
        localStorage.setItem("remember_me", "true")
      } else {
        localStorage.removeItem("remembered_phone")
        localStorage.setItem("remember_me", "false")
      }
      await login(phone.trim(), password)
      navigate("/dashboard")
    } catch (err: any) {
      setErrorMessage(err.message || "فشل تسجيل الدخول. تحقق من البيانات")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="relative min-h-screen w-full flex overflow-hidden bg-background">
      {/* ── Fullscreen Background Image with Overlay ── */}
      <div className="absolute inset-0 z-0">
        <div
          className="absolute inset-0 bg-cover bg-center bg-no-repeat"
          style={{
            backgroundImage: `url(https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070&auto=format&fit=crop)`,
          }}
        />
        <div className="absolute inset-0 bg-gradient-to-br from-[#001453]/80 via-[#00288e]/70 to-[#001453]/90" />
        <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Y2lyY2xlIGN4PSIyIiBjeT0iMiIgcj0iMSIgZmlsbD0icmdiYSgyNTUsMjU1LDI1NSwwLjA0KSIvPjwvc3ZnPg==')] opacity-40" />
      </div>

      {/* ── Animated Orbs ── */}
      <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none">
        <motion.div
          className="absolute -top-48 -right-24 w-[600px] h-[600px] rounded-full bg-amber-500/10 blur-3xl"
          animate={{ x: [0, 30, -20, 0], y: [0, -25, 20, 0] }}
          transition={{ duration: 12, repeat: Infinity, ease: "easeInOut" }}
        />
        <motion.div
          className="absolute -bottom-32 -left-20 w-[500px] h-[500px] rounded-full bg-blue-400/10 blur-3xl"
          animate={{ x: [0, -20, 30, 0], y: [0, 25, -20, 0] }}
          transition={{ duration: 15, repeat: Infinity, ease: "easeInOut" }}
        />
        <motion.div
          className="absolute top-1/3 -left-16 w-[400px] h-[400px] rounded-full bg-emerald-400/8 blur-3xl"
          animate={{ x: [0, 40, -30, 0], y: [0, -20, 40, 0] }}
          transition={{ duration: 18, repeat: Infinity, ease: "easeInOut" }}
        />
      </div>

      {/* ── Centered Content ── */}
      <div className="relative z-10 w-full min-h-screen flex items-center justify-center p-4">
        <motion.div
          initial={{ opacity: 0, y: 30, scale: 0.97 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
          className="w-full max-w-[420px]"
        >
          {/* ── Glass Panel ── */}
          <div className="glass-card-premium rounded-3xl p-1">
            <div className="rounded-3xl p-8 sm:p-10 bg-white/80 dark:bg-[#111b2e]/80 backdrop-blur-xl">
              <motion.div
                initial="hidden"
                animate="visible"
                className="space-y-7"
              >
                {/* ── Logo ── */}
                <motion.div
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ duration: 0.5, delay: 0.1 }}
                  className="flex justify-center"
                >
                  <div className="w-20 h-20 rounded-2xl bg-white shadow-lg p-2 ring-1 ring-black/5">
                    <div className="w-full h-full rounded-xl bg-gradient-to-br from-primary to-primary-container flex items-center justify-center text-white font-bold text-2xl">
                      أ
                    </div>
                  </div>
                </motion.div>

                {/* ── Heading ── */}
                <motion.div
                  initial={{ opacity: 0, y: 15 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.5, delay: 0.2 }}
                  className="text-center"
                >
                  <h2 className="text-2xl sm:text-3xl font-extrabold gradient-text">
                    تسجيل الدخول
                  </h2>
                  <p className="text-sm text-muted-foreground mt-2">
                    أدخل بياناتك للوصول إلى لوحة التحكم
                  </p>
                </motion.div>

                {/* Feature chips */}
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ duration: 0.5, delay: 0.3 }}
                  className="flex flex-wrap justify-center gap-2"
                >
                  {[
                    { icon: GraduationCap, text: "تدريب احترافي" },
                    { icon: ShieldCheck, text: "منشآت متطورة" },
                    { icon: Sparkles, text: "برامج متميزة" },
                  ].map(({ icon: Icon, text }, idx) => (
                    <span
                      key={idx}
                      className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-primary/5 text-primary/70 text-[11px] border border-primary/10"
                    >
                      <Icon className="w-3 h-3" />
                      {text}
                    </span>
                  ))}
                </motion.div>

                {/* ── Error ── */}
                {errorMessage && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: "auto" }}
                    className="p-3 rounded-2xl bg-destructive/8 border border-destructive/15 text-destructive text-sm flex items-center gap-2.5"
                  >
                    <span className="w-7 h-7 rounded-full bg-destructive/12 flex items-center justify-center shrink-0">
                      <AlertCircle className="w-4 h-4" />
                    </span>
                    <span>{errorMessage}</span>
                  </motion.div>
                )}

                {/* ── Form ── */}
                <form onSubmit={handleSubmit} className="space-y-5">
                  {/* Phone */}
                  <motion.div
                    initial={{ opacity: 0, y: 15 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.4, delay: 0.35 }}
                  >
                    <label
                      htmlFor="phone"
                      className="block text-sm font-semibold text-foreground mb-1.5"
                    >
                      رقم الهاتف
                    </label>
                    <div className="relative">
                      <div className="absolute inset-y-0 right-0 flex items-center pr-3.5 pointer-events-none text-muted-foreground">
                        <User className="w-5 h-5" />
                      </div>
                      <input
                        id="phone"
                        type="text"
                        dir="ltr"
                        placeholder="أدخل رقم الهاتف"
                        value={phone}
                        onChange={(e) => setPhone(e.target.value)}
                        className="block w-full pr-11 pl-4 py-3 rounded-xl border-2 border-border/60 bg-surface-container-low text-foreground placeholder:text-muted-foreground/50 focus:outline-none focus:border-primary focus:bg-white/90 focus:shadow-[0_0_0_4px_rgba(0,40,142,0.08)] transition-all duration-300"
                      />
                    </div>
                  </motion.div>

                  {/* Password */}
                  <motion.div
                    initial={{ opacity: 0, y: 15 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.4, delay: 0.4 }}
                  >
                    <label
                      htmlFor="password"
                      className="block text-sm font-semibold text-foreground mb-1.5"
                    >
                      كلمة المرور
                    </label>
                    <div className="relative">
                      <div className="absolute inset-y-0 right-0 flex items-center pr-3.5 pointer-events-none text-muted-foreground">
                        <Lock className="w-5 h-5" />
                      </div>
                      <input
                        id="password"
                        type={showPassword ? "text" : "password"}
                        placeholder="أدخل كلمة المرور"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        className="block w-full pr-11 pl-12 py-3 rounded-xl border-2 border-border/60 bg-surface-container-low text-foreground placeholder:text-muted-foreground/50 focus:outline-none focus:border-primary focus:bg-white/90 focus:shadow-[0_0_0_4px_rgba(0,40,142,0.08)] transition-all duration-300"
                      />
                      <Button
                        type="button"
                        variant="ghost"
                        className="absolute inset-y-0 left-0 pl-3 text-muted-foreground hover:text-foreground"
                        onClick={() => setShowPassword(!showPassword)}
                      >
                        {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                      </Button>
                    </div>
                  </motion.div>

                  {/* Remember me + Forgot password */}
                  <motion.div
                    initial={{ opacity: 0, y: 15 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.4, delay: 0.45 }}
                    className="flex items-center justify-between"
                  >
                    <label className="flex items-center gap-2 cursor-pointer group" htmlFor="remember-me">
                      <div className="relative">
                        <input
                          id="remember-me"
                          type="checkbox"
                          checked={rememberMe}
                          onChange={(e) => setRememberMe(e.target.checked)}
                          className="peer sr-only"
                        />
                        <div className="w-5 h-5 rounded-md border-2 border-border/70 bg-surface-container-low transition-all duration-200 peer-checked:border-primary peer-checked:bg-primary peer-focus-visible:ring-2 peer-focus-visible:ring-primary/30 group-hover:border-primary/50" />
                        <svg
                          className="absolute inset-0 w-5 h-5 text-white opacity-0 peer-checked:opacity-100 transition-opacity duration-200 pointer-events-none"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="3"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        >
                          <polyline points="20 6 9 17 4 12" />
                        </svg>
                      </div>
                      <span className="text-sm text-muted-foreground group-hover:text-foreground transition-colors">
                        تذكرني
                      </span>
                    </label>
                    <a
                      href="#"
                      className="text-sm font-semibold text-primary hover:text-primary/70 transition-colors"
                    >
                      نسيت كلمة المرور؟
                    </a>
                  </motion.div>

                  {/* Submit */}
                  <motion.div
                    initial={{ opacity: 0, y: 15 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.4, delay: 0.5 }}
                  >
                    <Button
                      size="lg"
                      type="submit"
                      disabled={isLoading}
                      className="relative w-full h-auto py-4 px-6 rounded-xl text-sm font-bold text-white bg-gradient-to-r from-primary via-primary-container to-primary bg-[length:200%_100%] hover:from-primary/95 hover:via-primary-container/95 hover:to-primary/95 shadow-lg shadow-primary/25 hover:shadow-xl hover:shadow-primary/30 transition-all duration-500 overflow-hidden group"
                    >
                      <span className="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-white/10 to-transparent -skew-x-12 translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-1000" />
                      {isLoading ? (
                        <span className="flex items-center gap-2.5">
                          <span className="w-4 h-4 border-[2.5px] border-white/30 border-t-white rounded-full animate-spin" />
                          جاري تسجيل الدخول...
                        </span>
                      ) : (
                        <span className="flex items-center gap-2.5">
                          تسجيل الدخول
                          <ChevronLeft className="w-4 h-4" />
                        </span>
                      )}
                    </Button>
                  </motion.div>
                </form>
              </motion.div>
            </div>
          </div>

          {/* ── Footer ── */}
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.8 }}
            className="text-center text-xs text-white/50 mt-6"
          >
            جميع الحقوق محفوظة &copy; {new Date().getFullYear()} — مركز الأهلي الرياضي
          </motion.p>
        </motion.div>
      </div>
    </div>
  )
}
