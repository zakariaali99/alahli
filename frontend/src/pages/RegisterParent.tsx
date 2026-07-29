import { useState } from "react"
import { useNavigate, Link } from "react-router-dom"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { api } from "@/lib/api"
import { validateLibyanPhone } from "@/lib/utils"
import { Users, ArrowRight, CheckCircle } from "lucide-react"

export default function RegisterParent() {
  const navigate = useNavigate()
  const [form, setForm] = useState({
    full_name: "",
    phone: "",
    whatsapp_phone: "",
    residence: "",
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

    const phoneErr = validateLibyanPhone(form.phone)
    if (phoneErr) { setError(phoneErr); return }

    setLoading(true)
    try {
      await api.post("/auth/register/", {
        role: "parent",
        full_name: form.full_name,
        phone: form.phone.trim(),
        whatsapp_phone: form.whatsapp_phone || form.phone.trim(),
        residence: form.residence,
        birth_day: parseInt(form.birth_day),
        birth_month: parseInt(form.birth_month),
        birth_year: parseInt(form.birth_year),
      })
      setSuccess(true)
    } catch (err: any) {
      setError(api.getErrorMessage(err, "حدث خطأ أثناء التسجيل"))
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="min-h-screen bg-[#f4f7fb] flex items-center justify-center p-4" dir="rtl">
        <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="text-center max-w-md bg-white p-8 rounded-3xl shadow-xl border border-border/40">
          <CheckCircle className="w-16 h-16 text-[#0F4C81] mx-auto mb-4" />
          <h1 className="text-2xl font-black text-[#102033] mb-2">تم تقديم طلب حساب ولي الأمر!</h1>
          <p className="text-muted-foreground text-sm leading-relaxed mb-6">
            تم استلام بياناتك بنجاح. الطلب قيد المراجعة حالياً من قبل الإدارة وسيمكنك إضافة وإدارة أطفالك فور الموافقة.
          </p>
          <Button className="w-full h-11 rounded-xl bg-[#0F4C81] font-bold" onClick={() => navigate("/login")}>
            الذهاب لتسجيل الدخول
          </Button>
        </motion.div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[#f4f7fb] flex items-center justify-center p-4" dir="rtl">
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="w-full max-w-md">
        <div className="text-center mb-6">
          <div className="w-14 h-14 rounded-2xl bg-[#0F4C81]/10 text-[#0F4C81] flex items-center justify-center mx-auto mb-3 shadow-inner">
            <Users className="w-7 h-7" />
          </div>
          <h1 className="text-2xl font-black text-[#102033]">تسجيل ولي أمر جديد</h1>
          <p className="text-muted-foreground text-xs mt-1">أنشئ حساب ولي أمر لإدارة أطفالك الرياضيين</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4 bg-white border border-border/60 rounded-3xl p-6 shadow-sm">
          <div>
            <label className="block text-xs font-bold text-[#102033] mb-1">اسم ولي الأمر بالكامل</label>
            <input
              className="w-full bg-[#f8fafc] border border-border/70 rounded-xl px-3.5 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0F4C81]/30"
              value={form.full_name}
              onChange={(e) => setForm({ ...form, full_name: e.target.value })}
              placeholder="أدخل الاسم الثلاثي أو الرباعي"
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-[#102033] mb-1">رقم الهاتف</label>
              <input
                className="w-full bg-[#f8fafc] border border-border/70 rounded-xl px-3.5 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0F4C81]/30"
                dir="ltr"
                value={form.phone}
                onChange={(e) => setForm({ ...form, phone: e.target.value })}
                placeholder="0910000000"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-[#102033] mb-1">رقم الواتساب</label>
              <input
                className="w-full bg-[#f8fafc] border border-border/70 rounded-xl px-3.5 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0F4C81]/30"
                dir="ltr"
                value={form.whatsapp_phone}
                onChange={(e) => setForm({ ...form, whatsapp_phone: e.target.value })}
                placeholder="0920000000"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-[#102033] mb-1">السكن / العنوان</label>
            <input
              className="w-full bg-[#f8fafc] border border-border/70 rounded-xl px-3.5 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0F4C81]/30"
              value={form.residence}
              onChange={(e) => setForm({ ...form, residence: e.target.value })}
              placeholder="مثال: مصراتة - بالقرب من..."
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-[#102033] mb-1">تاريخ الميلاد</label>
            <div className="grid grid-cols-3 gap-2">
              <input
                type="number" min={1} max={31} placeholder="اليوم"
                className="w-full bg-[#f8fafc] border border-border/70 rounded-xl px-3 py-2 text-sm text-center outline-none"
                value={form.birth_day}
                onChange={(e) => setForm({ ...form, birth_day: e.target.value })}
                required
              />
              <input
                type="number" min={1} max={12} placeholder="الشهر"
                className="w-full bg-[#f8fafc] border border-border/70 rounded-xl px-3 py-2 text-sm text-center outline-none"
                value={form.birth_month}
                onChange={(e) => setForm({ ...form, birth_month: e.target.value })}
                required
              />
              <input
                type="number" min={1900} max={2026} placeholder="السنة"
                className="w-full bg-[#f8fafc] border border-border/70 rounded-xl px-3 py-2 text-sm text-center outline-none"
                value={form.birth_year}
                onChange={(e) => setForm({ ...form, birth_year: e.target.value })}
                required
              />
            </div>
          </div>

          {error && <p className="text-destructive text-xs font-bold bg-destructive/10 p-2.5 rounded-xl">{error}</p>}

          <Button type="submit" className="w-full h-11 rounded-xl bg-[#0F4C81] text-white font-bold" disabled={loading}>
            {loading ? "جاري التسجيل..." : "تأكيد وإرسال طلب التسجيل"}
            <ArrowRight className="w-4 h-4 mr-2" />
          </Button>
        </form>

        <p className="text-center text-xs text-muted-foreground mt-4">
          لديك حساب بالفعل؟ <Link to="/login" className="text-[#0F4C81] font-bold">تسجيل الدخول</Link>
        </p>
      </motion.div>
    </div>
  )
}
