import { useState, useEffect } from "react"
import { useNavigate, Link } from "react-router-dom"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { api } from "@/lib/api"
import CameraCapture from "@/components/ui/camera-capture"
import { validateLibyanPhone } from "@/lib/utils"
import { extractResults } from "@/lib/response"
import { Trophy, Dumbbell, ArrowRight, CheckCircle, Building2, User, Phone, MapPin, HeartPulse, Sparkles, Loader2 } from "lucide-react"
import type { Department, Sport } from "@/lib/types"

export default function RegisterAthlete() {
  const navigate = useNavigate()
  const [step, setStep] = useState<1 | 2 | 3>(1)
  const [selectedAcademy, setSelectedAcademy] = useState<Department | null>(null)
  const [sports, setSports] = useState<Sport[]>([])
  const [selectedSport, setSelectedSport] = useState<Sport | null>(null)
  const [loadingSports, setLoadingSports] = useState(false)

  const HARDCODED_DEPARTMENTS: Department[] = [
    {
      id: 4,
      name: "Al Ahli Sports Center",
      name_ar: "مركز الأهلي الرياضي",
      color: "#0F4C81",
      logo: null,
      bank_account_number: "",
      iban: "",
      is_active: true,
      created_at: "",
    },
    {
      id: 5,
      name: "Al Aws Academy",
      name_ar: "أكاديمية الأوس",
      color: "#136F63",
      logo: null,
      bank_account_number: "",
      iban: "",
      is_active: true,
      created_at: "",
    },
  ]

  const [departments, setDepartments] = useState<Department[]>(HARDCODED_DEPARTMENTS)
  
  const [form, setForm] = useState({
    full_name: "",
    phone: "",
    parent_name: "",
    parent_phone: "",
    whatsapp_phone: "",
    residence: "",
    health_status: "",
    birth_day: "",
    birth_month: "",
    birth_year: "",
  })
  
  const [photo, setPhoto] = useState<string | null>(null)
  const [error, setError] = useState("")
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)

  const handleSelectAcademy = async (academy: Department) => {
    setSelectedAcademy(academy)
    setSelectedSport(null)
    setLoadingSports(true)
    try {
      const res = await api.get<{ results: Sport[] } | Sport[]>("/sports/", { department: String(academy.id) })
      const list = extractResults(res)
      setSports(list)
      if (list.length > 0) {
        setStep(2)
      } else {
        setStep(3)
      }
    } catch {
      setStep(3)
    } finally {
      setLoadingSports(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

    if (!selectedAcademy) {
      setError("يرجى اختيار الأكاديمية أولاً")
      setStep(1)
      return
    }

    const isParent = selectedAcademy.id === 5

    if (!isParent && !photo) {
      setError("صورة السيلفي أو الصورة الشخصية مطلوبة لإتمام التسجيل")
      return
    }

    const phoneErr = validateLibyanPhone(form.phone)
    if (phoneErr) {
      setError(phoneErr)
      return
    }

    setLoading(true)
    try {
      const body: Record<string, any> = {
        role: isParent ? "parent" : "athlete",
        full_name: form.full_name,
        phone: form.phone.trim(),
        residence: form.residence,
        department: selectedAcademy.id,
        ...(selectedSport ? { sport: selectedSport.id } : {}),
      }

      if (isParent) {
        body.whatsapp_phone = form.phone.trim()
      } else {
        body.photo = photo
        body.health_status = form.health_status
        body.birth_day = parseInt(form.birth_day)
        body.birth_month = parseInt(form.birth_month)
        body.birth_year = parseInt(form.birth_year)
      }

      await api.post("/auth/register/", body)
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
          <CheckCircle className="w-16 h-16 text-[#1A7A42] mx-auto mb-4" />
          <h1 className="text-2xl font-black text-[#102033] mb-2">تم تقديم طلب التسجيل بنجاح!</h1>
          <p className="text-muted-foreground text-sm leading-relaxed mb-6">
            تم تسجيل معلوماتك بـ <span className="font-bold text-[#0F4C81]">{selectedAcademy?.name_ar}</span>. الطلب قيد المراجعة حالياً من قبل الإدارة وسيتم تفعيل حسابك فور الموافقة.
          </p>
          <Button className="w-full h-11 rounded-xl bg-[#0F4C81] font-bold" onClick={() => navigate("/login")}>
            الذهاب لتسجيل الدخول
          </Button>
        </motion.div>
      </div>
    )
  }

  const isParent = selectedAcademy?.id === 5

  return (
    <div className="min-h-screen bg-[#f4f7fb] py-8 px-4" dir="rtl">
      <div className="mx-auto max-w-xl">
        <div className="text-center mb-6">
          <div className="w-14 h-14 rounded-2xl bg-[#0F4C81]/10 text-[#0F4C81] flex items-center justify-center mx-auto mb-3 shadow-inner">
            <Dumbbell className="w-7 h-7" />
          </div>
          <h1 className="text-2xl font-black text-[#102033]">
            {isParent ? "تسجيل ولي أمر جديد" : "تسجيل رياضي جديد"}
          </h1>
          <p className="text-muted-foreground text-xs mt-1">اختر الأكاديمية ثم أدخل بياناتك الشخصية</p>
        </div>

        {/* Step Indicator */}
        <div className="flex items-center justify-center gap-2 sm:gap-3 mb-6 text-xs font-bold flex-wrap">
          <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full ${step === 1 ? "bg-[#0F4C81] text-white" : "bg-white text-muted-foreground border"}`}>
            <Building2 className="w-3.5 h-3.5" /> 1. اختيار الأكاديمية
          </div>
          <span className="text-muted-foreground">←</span>
          <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full ${step === 2 ? "bg-[#0F4C81] text-white" : "bg-white text-muted-foreground border"}`}>
            <Trophy className="w-3.5 h-3.5" /> 2. اختيار الرياضة
          </div>
          <span className="text-muted-foreground">←</span>
          <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full ${step === 3 ? "bg-[#0F4C81] text-white" : "bg-white text-muted-foreground border"}`}>
            <User className="w-3.5 h-3.5" /> 3. البيانات الشخصية
          </div>
        </div>

        {/* STEP 1: SELECT ACADEMY */}
        {step === 1 && (
          <motion.div initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} className="space-y-4">
            <h2 className="text-center text-sm font-extrabold text-[#102033] mb-4">يرجى اختيار الأكاديمية أولاً</h2>
            
            <div className="grid gap-4 sm:grid-cols-2">
              {departments.map((dept) => (
                <button
                  key={dept.id}
                  type="button"
                  onClick={() => handleSelectAcademy(dept)}
                  disabled={loadingSports}
                  className={`p-6 rounded-2xl border-2 text-right transition-all cursor-pointer bg-white hover:shadow-xl hover:-translate-y-1 flex flex-col justify-between ${
                    dept.name_ar.includes("الأهلي") ? "border-[#00204F]/30 hover:border-[#00204F]" : "border-[#1A7A42]/30 hover:border-[#1A7A42]"
                  }`}
                >
                  <div className="flex items-center justify-between mb-3">
                    <span className="p-2.5 rounded-xl text-white font-bold" style={{ backgroundColor: dept.color || (dept.name_ar.includes("الأهلي") ? "#00204F" : "#1A7A42") }}>
                      <Building2 className="w-5 h-5" />
                    </span>
                    <Sparkles className="w-4 h-4 text-amber-500" />
                  </div>
                  <div>
                    <h3 className="text-lg font-black text-[#102033]">{dept.name_ar}</h3>
                    <p className="text-xs text-muted-foreground mt-1">اضغط للاختيار والتسجيل في هذه الأكاديمية</p>
                  </div>
                </button>
              ))}
            </div>
          </motion.div>
        )}

        {/* STEP 2: SELECT SPORT */}
        {step === 2 && (
          <motion.div initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} className="space-y-4">
            <div className="flex items-center justify-between bg-white px-4 py-3 rounded-2xl border border-border/50 mb-4">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full" style={{ backgroundColor: selectedAcademy?.color || "#0F4C81" }} />
                <span className="text-xs font-black text-[#102033]">الأكاديمية المختارة: {selectedAcademy?.name_ar}</span>
              </div>
              <button type="button" onClick={() => setStep(1)} className="text-xs text-[#0F4C81] hover:underline font-bold">
                تغيير
              </button>
            </div>

            <h2 className="text-center text-sm font-extrabold text-[#102033] mb-4">اختر الرياضة أو التخصص المطلوبة</h2>

            <div className="grid gap-4 sm:grid-cols-2">
              {sports.map((sp) => (
                <button
                  key={sp.id}
                  type="button"
                  onClick={() => { setSelectedSport(sp); setStep(3) }}
                  className="p-6 rounded-2xl border-2 border-primary/20 hover:border-primary text-right transition-all cursor-pointer bg-white hover:shadow-xl hover:-translate-y-1 flex flex-col justify-between"
                >
                  <div className="flex items-center justify-between mb-3">
                    <span className="p-2.5 rounded-xl bg-primary/10 text-primary font-bold">
                      <Trophy className="w-5 h-5" />
                    </span>
                  </div>
                  <div>
                    <h3 className="text-lg font-black text-[#102033]">{sp.name_ar}</h3>
                    <p className="text-xs text-muted-foreground mt-1">انقر لاختيار رياضة {sp.name_ar}</p>
                  </div>
                </button>
              ))}
            </div>
            {sports.length === 0 && (
              <div className="text-center py-6">
                <Button onClick={() => setStep(3)} variant="outline">متابعة بدون تحديد رياضة</Button>
              </div>
            )}
          </motion.div>
        )}

        {/* STEP 3: PERSONAL DATA */}
        {step === 3 && (
          <motion.div initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }}>
            <div className="flex items-center justify-between bg-white px-4 py-3 rounded-2xl border border-border/50 mb-4">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full" style={{ backgroundColor: selectedAcademy?.color || "#0F4C81" }} />
                <span className="text-xs font-black text-[#102033]">
                  {selectedAcademy?.name_ar} {selectedSport ? `← ${selectedSport.name_ar}` : ""}
                </span>
              </div>
              <button type="button" onClick={() => setStep(sports.length > 0 ? 2 : 1)} className="text-xs text-[#0F4C81] hover:underline font-bold">
                تغيير
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4 bg-white border border-border/60 rounded-3xl p-6 shadow-sm">
              {!isParent && (
                <div>
                  <label className="block text-xs font-bold text-[#102033] mb-1.5">صورة شخصية / سيلفي (إلزامية)</label>
                  <CameraCapture onCapture={setPhoto} preview={photo || undefined} />
                </div>
              )}

              <div>
                <label className="block text-xs font-bold text-[#102033] mb-1">
                  {isParent ? "اسم ولي الأمر بالكامل" : "اسم الرياضي بالكامل"}
                </label>
                <input
                  className="w-full bg-[#f8fafc] border border-border/70 rounded-xl px-3.5 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0F4C81]/30"
                  value={form.full_name}
                  onChange={(e) => setForm({ ...form, full_name: e.target.value })}
                  placeholder={isParent ? "أدخل اسم ولي الأمر ثلاثي" : "أدخل الاسم الرباعي للرياضي"}
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#102033] mb-1">
                  {isParent ? "رقم هاتف ولي الأمر (الواتساب)" : "رقم هاتف الرياضي"}
                </label>
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
                <label className="block text-xs font-bold text-[#102033] mb-1">السكن / العنوان</label>
                <input
                  className="w-full bg-[#f8fafc] border border-border/70 rounded-xl px-3.5 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0F4C81]/30"
                  value={form.residence}
                  onChange={(e) => setForm({ ...form, residence: e.target.value })}
                  placeholder="مثال: مصراتة - بالقرب من..."
                />
              </div>

              {!isParent && (
                <>
                  <div>
                    <label className="block text-xs font-bold text-[#102033] mb-1">الحالة الصحية / ملاحظات طبية</label>
                    <textarea
                      rows={2}
                      className="w-full bg-[#f8fafc] border border-border/70 rounded-xl px-3.5 py-2 text-sm outline-none focus:ring-2 focus:ring-[#0F4C81]/30"
                      value={form.health_status}
                      onChange={(e) => setForm({ ...form, health_status: e.target.value })}
                      placeholder="أدخل أي حالة صحية أو ملاحظات طبية خاصة..."
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
                </>
              )}

              {error && <p className="text-destructive text-xs font-bold bg-destructive/10 p-2.5 rounded-xl">{error}</p>}

              <Button type="submit" className="w-full h-11 rounded-xl bg-[#0F4C81] text-white font-bold" disabled={loading}>
                {loading ? "جاري التقديم..." : "تأكيد وإرسال طلب التسجيل"}
                <ArrowRight className="w-4 h-4 mr-2" />
              </Button>
            </form>
          </motion.div>
        )}


        <p className="text-center text-xs text-muted-foreground mt-4">
          لديك حساب بالفعل؟ <Link to="/login" className="text-[#0F4C81] font-bold">تسجيل الدخول</Link>
        </p>
      </div>
    </div>
  )
}
