import { useState } from "react"
import { Link, useNavigate } from "react-router-dom"
import { motion } from "framer-motion"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { useAuth } from "@/lib/auth"
import { validateLibyanPhone } from "@/lib/utils"
import {
  AlertCircle,
  Eye,
  EyeOff,
  Lock,
  Phone,
  UserPlus,
  Users,
  Dumbbell,
} from "lucide-react"

export default function Landing() {
  const navigate = useNavigate()
  const { login } = useAuth()

  const [phone, setPhone] = useState(() => {
    try {
      return localStorage.getItem("remembered_phone") || ""
    } catch {
      return ""
    }
  })
  const [password, setPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [rememberMe, setRememberMe] = useState(() => {
    try {
      return localStorage.getItem("remember_me") === "true"
    } catch {
      return false
    }
  })
  const [isLoading, setIsLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!phone.trim() || !password.trim()) {
      setErrorMessage("يرجى إدخال رقم الهاتف وكلمة المرور")
      return
    }

    const phoneErr = validateLibyanPhone(phone)
    if (phoneErr) {
      setErrorMessage(phoneErr)
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

      const loggedInUser = await login(phone.trim(), password)
      if (loggedInUser.role === "athlete" || loggedInUser.role === "parent") {
        navigate("/user")
      } else {
        navigate("/dashboard")
      }
    } catch (err: any) {
      setErrorMessage(err.message || "فشل تسجيل الدخول")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-[#fafafb] text-[#102033] flex flex-col justify-between" dir="rtl">
      {/* Decorative ambient blurs with Al Ahly branding colors (Theme primary / Dark Gray) */}
      <div className="fixed inset-0 pointer-events-none -z-10 overflow-hidden">
        <div className="absolute -top-40 right-[-10%] h-[45vw] w-[45vw] rounded-full bg-primary/8 blur-[130px]" />
        <div className="absolute -bottom-40 left-[-12%] h-[50vw] w-[50vw] rounded-full bg-[#102033]/8 blur-[140px]" />
      </div>

      {/* Header */}
      <header className="border-b border-white/70 bg-white/80 backdrop-blur-xl">
        <div className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between px-4 md:px-6">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-md shadow-primary/20">
              <Dumbbell className="h-5 w-5 animate-pulse-soft" />
            </div>
            <div>
              <p className="text-sm font-black leading-none text-[#102033]">أكاديمية النادي الأهلي الرياضي</p>
              <p className="mt-1 text-[10px] font-medium text-[#5f7288]">بوابة الإدارة والتسجيل الإلكتروني</p>
            </div>
          </div>
          <div className="text-xs font-bold text-primary bg-primary/5 px-3 py-1.5 rounded-full border border-primary/10">
            المنصة الرسمية
          </div>
        </div>
      </header>

      {/* Main Portal Container */}
      <main className="flex-1 flex items-center justify-center px-4 py-8 md:py-16">
        <div className="mx-auto grid w-full max-w-5xl items-center gap-8 lg:grid-cols-12">
          
          {/* Welcome and Action Side */}
          <div className="space-y-6 lg:col-span-7">
            <div className="space-y-4">
              <h1 className="text-3xl font-black leading-tight text-[#102033] md:text-5xl tracking-tight">
                أهلاً بك في أكاديمية
                <span className="block text-primary mt-2 font-black">النادي الأهلي الرياضي</span>
              </h1>
              <p className="max-w-lg text-sm leading-7 text-[#5f7288] md:text-base font-medium">
                بوابتك الرقمية المتكاملة للاشتراك في الأنشطة الرياضية، إدارة الحسابات، ومتابعة الحضور والتقييمات بكل سهولة.
              </p>
            </div>

            {/* Registration Portal Cards */}
            <div className="grid gap-4 sm:grid-cols-2 max-w-xl">
              {/* Athlete Registration */}
              <Link to="/register/athlete" className="group">
                <Card className="p-5 border border-white/90 bg-white/70 backdrop-blur-md transition-all duration-300 hover:-translate-y-1 hover:border-primary/35 hover:shadow-lg hover:shadow-primary/5 cursor-pointer">
                  <div className="mb-3.5 flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary group-hover:scale-110 transition-transform">
                    <UserPlus className="h-5 w-5" />
                  </div>
                  <h3 className="text-sm font-extrabold text-[#102033] group-hover:text-primary transition-colors">تسجيل رياضي جديد</h3>
                  <p className="mt-2 text-xs leading-5 text-[#5f7288]">سجل حسابك كلاعب في الأكاديمية والتحق بالمجموعات والتمارين مباشرة.</p>
                </Card>
              </Link>

              {/* Parent Registration */}
              <Link to="/register/parent" className="group">
                <Card className="p-5 border border-white/90 bg-white/70 backdrop-blur-md transition-all duration-300 hover:-translate-y-1 hover:border-[#102033]/35 hover:shadow-lg hover:shadow-[#102033]/5 cursor-pointer">
                  <div className="mb-3.5 flex h-10 w-10 items-center justify-center rounded-xl bg-[#102033]/10 text-[#102033] group-hover:scale-110 transition-transform">
                    <Users className="h-5 w-5" />
                  </div>
                  <h3 className="text-sm font-extrabold text-[#102033] group-hover:text-[#102033] transition-colors">تسجيل ولي أمر</h3>
                  <p className="mt-2 text-xs leading-5 text-[#5f7288]">سجل حسابك كولي أمر لإضافة وإدارة لاعبيك ودفع اشتراكاتهم دفعة واحدة.</p>
                </Card>
              </Link>
            </div>
          </div>

          {/* Login Form Side */}
          <div className="lg:col-span-5">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
            >
              <Card
                variant="spotlight"
                className="p-6 md:p-8 border border-white/80 shadow-[0_20px_50px_-24px_rgba(16,32,51,0.25)] bg-white/90 backdrop-blur-md"
              >
                <h2 className="text-xl font-black text-[#102033]">تسجيل الدخول</h2>
                <p className="mt-1 text-xs text-[#5f7288] font-medium">أدخل رقم الهاتف وكلمة المرور للوصول للحساب</p>

                {errorMessage && (
                  <div className="mt-4 flex items-center gap-2 rounded-xl border border-[#A63F3F]/25 bg-[#A63F3F]/8 px-3 py-2.5 text-xs text-[#A63F3F] font-bold">
                    <AlertCircle className="h-4.5 w-4.5 flex-shrink-0" /> {errorMessage}
                  </div>
                )}

                <form className="mt-5 space-y-4" onSubmit={handleSubmit}>
                  <div>
                    <label className="mb-1.5 block text-xs font-bold text-[#102033]" htmlFor="phone">رقم الهاتف</label>
                    <Input
                      id="phone"
                      autoComplete="username"
                      dir="ltr"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="0910000000"
                      icon={<Phone className="h-4 w-4 text-muted-foreground" />}
                      className="rounded-xl"
                    />
                  </div>

                  <div>
                    <label className="mb-1.5 block text-xs font-bold text-[#102033]" htmlFor="password">كلمة المرور</label>
                    <div className="relative">
                      <Input
                        id="password"
                        autoComplete="current-password"
                        type={showPassword ? "text" : "password"}
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        icon={<Lock className="h-4 w-4 text-muted-foreground" />}
                        className="pl-10 rounded-xl"
                      />
                      <button
                        className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
                        type="button"
                        onClick={() => setShowPassword((v) => !v)}
                      >
                        {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                      </button>
                    </div>
                  </div>

                  <div className="flex items-center justify-between">
                    <label className="flex cursor-pointer items-center gap-2 text-xs font-bold text-[#102033] select-none">
                      <input
                        type="checkbox"
                        checked={rememberMe}
                        onChange={(e) => setRememberMe(e.target.checked)}
                        className="w-4.5 h-4.5 rounded border-border text-primary focus:ring-primary/30"
                      />
                      تذكرني في المرة القادمة
                    </label>
                  </div>

                  <Button className="h-11 w-full rounded-xl text-sm font-extrabold mt-3 bg-primary hover:bg-primary/90 text-primary-foreground shadow-lg shadow-primary/15 transition-all" disabled={isLoading} type="submit">
                    {isLoading ? "جاري تسجيل الدخول..." : "دخول"}
                  </Button>
                </form>
              </Card>
            </motion.div>
          </div>

        </div>
      </main>

      {/* Footer */}
      <footer className="py-6 border-t border-white/60 bg-white/40 backdrop-blur-md">
        <div className="mx-auto w-full max-w-6xl px-4 md:px-6 flex flex-col sm:flex-row items-center justify-between gap-3 text-[11px] font-semibold text-[#5f7288]">
          <p>© {new Date().getFullYear()} أكاديمية النادي الأهلي الرياضي. جميع الحقوق محفوظة.</p>
          <div className="flex items-center gap-4">
            <span className="cursor-pointer hover:text-primary">الدعم الفني</span>
            <span>•</span>
            <span className="cursor-pointer hover:text-primary">الشروط والأحكام</span>
          </div>
        </div>
      </footer>
    </div>
  )
}
