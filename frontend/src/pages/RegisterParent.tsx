import { useState } from "react"
import { useNavigate, Link } from "react-router-dom"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { api } from "@/lib/api"
import { Users, ArrowRight, CheckCircle } from "lucide-react"

export default function RegisterParent() {
  const navigate = useNavigate()
  const [form, setForm] = useState({
    full_name: "",
    phone: "",
    password: "",
    birth_day: "",
    birth_month: "",
    birth_year: "",
  })
  const [error, setError] = useState("")
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")
    setLoading(true)
    try {
      await api.post("/auth/register/", {
        role: "parent",
        full_name: form.full_name,
        phone: form.phone,
        password: form.password,
        birth_day: parseInt(form.birth_day),
        birth_month: parseInt(form.birth_month),
        birth_year: parseInt(form.birth_year),
      })
      setSuccess(true)
    } catch (err: any) {
      setError(err.message || "حدث خطأ أثناء التسجيل")
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center p-4">
        <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="text-center max-w-sm">
          <CheckCircle className="w-16 h-16 text-primary mx-auto mb-4" />
          <h1 className="text-2xl font-bold mb-2">تم التسجيل بنجاح</h1>
          <p className="text-muted-foreground mb-6">يمكنك الآن تسجيل الدخول وإضافة الرياضيين الذين ترعاهم.</p>
          <Button onClick={() => navigate("/login")}>تسجيل الدخول</Button>
        </motion.div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-primary/10 flex items-center justify-center mx-auto mb-4">
            <Users className="w-8 h-8 text-primary" />
          </div>
          <h1 className="text-2xl font-bold">تسجيل ولي أمر</h1>
          <p className="text-muted-foreground text-sm mt-1">أنشئ حساب ولي أمر لإدارة الرياضيين</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4 bg-card border border-border rounded-2xl p-6">
          <div>
            <label className="block text-sm font-medium mb-1">الاسم الكامل</label>
            <input
              className="w-full bg-surface-container-low border border-border rounded-xl px-4 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              value={form.full_name}
              onChange={(e) => setForm({ ...form, full_name: e.target.value })}
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">رقم الهاتف</label>
            <input
              className="w-full bg-surface-container-low border border-border rounded-xl px-4 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              dir="ltr"
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">كلمة المرور</label>
            <input
              type="password"
              className="w-full bg-surface-container-low border border-border rounded-xl px-4 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
              required
              minLength={8}
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">تاريخ الميلاد</label>
            <div className="grid grid-cols-3 gap-3">
              <input type="number" min={1} max={31} placeholder="DD"
                className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-primary/30"
                value={form.birth_day}
                onChange={(e) => setForm({ ...form, birth_day: e.target.value })}
                required />
              <input type="number" min={1} max={12} placeholder="MM"
                className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-primary/30"
                value={form.birth_month}
                onChange={(e) => setForm({ ...form, birth_month: e.target.value })}
                required />
              <input type="number" min={1900} max={2026} placeholder="YY"
                className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-primary/30"
                value={form.birth_year}
                onChange={(e) => setForm({ ...form, birth_year: e.target.value })}
                required />
            </div>
          </div>

          {error && <p className="text-destructive text-sm">{error}</p>}

          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? "جاري التسجيل..." : "تسجيل"}
            <ArrowRight className="w-4 h-4 mr-2" />
          </Button>
        </form>

        <p className="text-center text-sm text-muted-foreground mt-4">
          لديك حساب بالفعل؟ <Link to="/login" className="text-primary font-medium">تسجيل الدخول</Link>
        </p>
      </motion.div>
    </div>
  )
}
