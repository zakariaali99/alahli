import { useState } from "react"
import { Link, useNavigate } from "react-router-dom"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card } from "@/components/ui/card"
import { useAuth } from "@/lib/auth"
import { AlertCircle, Eye, EyeOff, Lock, Phone, ShieldCheck } from "lucide-react"
import { validateLibyanPhone } from "@/lib/utils"

export default function LoginPage() {
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
    if (phoneErr) { setErrorMessage(phoneErr); return }

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
    <div className="min-h-screen bg-[#f4f7fb] px-4 py-8" dir="rtl">
      <div className="fixed inset-0 pointer-events-none -z-10 overflow-hidden">
        <div className="absolute -top-24 right-[-10%] h-[40vw] w-[40vw] rounded-full bg-[#0F4C81]/12 blur-[120px]" />
        <div className="absolute -bottom-24 left-[-12%] h-[45vw] w-[45vw] rounded-full bg-[#136F63]/12 blur-[130px]" />
      </div>

      <div className="mx-auto grid min-h-[calc(100vh-4rem)] w-full max-w-5xl items-center gap-6 lg:grid-cols-2">
        <Card variant="glass" className="space-y-5 p-6 md:p-8">
          <div className="inline-flex h-11 w-11 items-center justify-center rounded-xl bg-[#0F4C81] text-white shadow-lg shadow-[#0F4C81]/20">
            <ShieldCheck className="h-5 w-5" />
          </div>
          <h1 className="text-3xl font-black leading-tight text-[#102033]">
            منصة إدارة الأكاديمية
            <span className="block text-[#0F4C81] mt-1">تسجيل دخول آمن</span>
          </h1>
          <p className="text-sm leading-7 text-[#4d6178]">
            سجّل الدخول للوصول إلى لوحة الإدارة أو لوحة المستخدم حسب صلاحية الحساب.
          </p>
          <div className="space-y-2 text-xs text-[#4d6178] border-t border-border/20 pt-4">
            <p>• تسجيل ذاتي للرياضي وولي الأمر</p>
            <p>• مسار اشتراك متعدد الخطوات</p>
            <p>• مراجعة واعتماد الطلبات عبر الإدارة</p>
          </div>
        </Card>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
        >
          <Card
            variant="spotlight"
            className="p-6 md:p-8 border border-white/80 shadow-[0_20px_60px_-28px_rgba(16,32,51,0.45)] backdrop-blur-md"
          >
            <h2 className="text-xl font-extrabold text-[#102033]">تسجيل الدخول</h2>
            <p className="mt-1 text-xs text-[#5f7288]">أدخل بياناتك للوصول إلى حسابك</p>

            {errorMessage && (
              <div className="mt-4 flex items-center gap-2 rounded-xl border border-[#A63F3F]/25 bg-[#A63F3F]/8 px-3 py-2 text-xs text-[#A63F3F]">
                <AlertCircle className="h-4 w-4" /> {errorMessage}
              </div>
            )}

            <form className="mt-5 space-y-4" onSubmit={handleSubmit}>
              <div>
                <label className="mb-1.5 block text-xs font-bold text-[#102033]" htmlFor="phone">رقم الهاتف</label>
                <Input
                  id="phone"
                  dir="ltr"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="0910000000"
                  icon={<Phone className="h-4 w-4 text-muted-foreground" />}
                />
              </div>

              <div>
                <label className="mb-1.5 block text-xs font-bold text-[#102033]" htmlFor="password">كلمة المرور</label>
                <div className="relative">
                  <Input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    icon={<Lock className="h-4 w-4 text-muted-foreground" />}
                    className="pl-10"
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

              <label className="flex cursor-pointer items-center gap-2 text-xs text-[#102033] select-none">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="w-4 h-4 rounded border-border text-primary focus:ring-primary/30"
                />
                تذكرني
              </label>

              <Button className="h-10 w-full rounded-xl text-sm font-bold mt-2" disabled={isLoading} type="submit">
                {isLoading ? "جاري تسجيل الدخول..." : "دخول"}
              </Button>
            </form>

            <div className="mt-5 flex flex-wrap items-center gap-3 text-xs text-[#5f7288] border-t border-border/10 pt-4">
              <Link className="text-[#0F4C81] underline-offset-2 hover:underline font-medium" to="/register/athlete">تسجيل رياضي</Link>
              <span>•</span>
              <Link className="text-[#0F4C81] underline-offset-2 hover:underline font-medium" to="/register/parent">تسجيل ولي أمر</Link>
            </div>
          </Card>
        </motion.div>
      </div>
    </div>
  )
}
