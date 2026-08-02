import { useState, useEffect } from "react"
import { Link, useNavigate, useSearchParams } from "react-router-dom"
import { motion, AnimatePresence } from "framer-motion"
import { ArrowRight, Dumbbell, Users, CheckCircle, AlertCircle, Loader2, Building2, Sparkles, Trophy } from "lucide-react"
import { Button } from "@/components/ui/button"
import { api } from "@/lib/api"
import { useToast } from "@/lib/toast"
import { validateLibyanPhone } from "@/lib/utils"
import { extractResults } from "@/lib/response"
import CameraCapture from "@/components/ui/camera-capture"
import type { Department, Sport } from "@/lib/types"
import { isParentAcademy, getAcademyLogo } from "@/lib/departments"

type Step = "choose" | "sport" | "form"

const ACADEMIES: Department[] = [
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

const defaultForm = {
  full_name: "",
  phone: "",
  whatsapp_phone: "",
  residence: "",
  health_status: "",
  birth_day: "",
  birth_month: "",
  birth_year: "",
}

export default function AddAthletePage() {
  const navigate = useNavigate()
  const toast = useToast()

  const [step, setStep] = useState<Step>("choose")
  const [selectedAcademy, setSelectedAcademy] = useState<Department | null>(null)
  const [sports, setSports] = useState<Sport[]>([])
  const [selectedSport, setSelectedSport] = useState<Sport | null>(null)
  const [loadingSports, setLoadingSports] = useState(false)

  const [departments, setDepartments] = useState<Department[]>(ACADEMIES)

  useEffect(() => {
    const loadDepts = async () => {
      try {
        const res = await api.get("/departments/")
        const list = extractResults<Department>(res)
        if (list.length > 0) {
          setDepartments(list)
        }
      } catch (err) {
        console.error("Failed to load departments:", err)
      }
    }
    loadDepts()
  }, [])

  const [form, setForm] = useState(defaultForm)
  const [photo, setPhoto] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState("")
  const [success, setSuccess] = useState(false)
  const [searchParams] = useSearchParams()
  const deptParam = searchParams.get("department")
  const isParent = isParentAcademy(selectedAcademy)

  const handleSelectAcademy = async (academy: Department) => {
    setSelectedAcademy(academy)
    setSelectedSport(null)
    setForm(defaultForm)
    setPhoto(null)
    setError("")
    setLoadingSports(true)
    try {
      const res = await api.get<{ results: Sport[] } | Sport[]>("/sports/", { department: String(academy.id) })
      const list = extractResults(res)
      setSports(list)
      if (list.length > 0) {
        setStep("sport")
      } else {
        setStep("form")
      }
    } catch {
      setStep("form")
    } finally {
      setLoadingSports(false)
    }
  }

  useEffect(() => {
    if (deptParam) {
      const match = departments.find((a) => a.id === Number(deptParam))
      if (match) {
        void handleSelectAcademy(match)
      }
    }
  }, [deptParam, departments])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

    if (!selectedAcademy) { setStep("choose"); return }

    if (!isParent && !photo) {
      setError("صورة السيلفي أو الصورة الشخصية مطلوبة لإتمام التسجيل")
      return
    }

    const phoneErr = validateLibyanPhone(form.phone)
    if (phoneErr) { setError(phoneErr); return }

    const body: Record<string, any> = {
      role: isParent ? "parent" : "athlete",
      full_name: form.full_name.trim(),
      phone: form.phone.trim(),
      residence: form.residence.trim(),
      department: selectedAcademy.id,
      ...(selectedSport ? { sport: selectedSport.id } : {}),
    }

    if (isParent) {
      body.whatsapp_phone = form.whatsapp_phone.trim() || form.phone.trim()
    } else {
      body.photo = photo
      body.health_status = form.health_status
      body.birth_day = parseInt(form.birth_day)
      body.birth_month = parseInt(form.birth_month)
      body.birth_year = parseInt(form.birth_year)
    }

    try {
      setSubmitting(true)
      const res = await api.post<{ athlete_id?: number }>("/auth/register/", body)
      toast.success("تم إنشاء الحساب بنجاح")
      if (res?.athlete_id) {
        navigate(`/dashboard/athletes/${res.athlete_id}`)
      } else {
        setSuccess(true)
      }
    } catch (err: any) {
      setError(api.getErrorMessage(err, "حدث خطأ أثناء التسجيل"))
    } finally {
      setSubmitting(false)
    }
  }

  if (success) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="text-center max-w-sm">
          <CheckCircle className="mx-auto mb-4 h-16 w-16 text-primary" />
          <h2 className="mb-2 text-2xl font-bold">تم إنشاء الحساب بنجاح</h2>
          <p className="mb-6 text-muted-foreground text-sm">
            تم تسجيل{" "}
            <span className="font-bold">{form.full_name}</span>{" "}
            في{" "}
            <span className="font-bold">{selectedAcademy?.name_ar}</span>.
            الحساب مفعّل ويمكن تسجيل الدخول مباشرة.
          </p>
          <div className="flex justify-center gap-3">
            <Button onClick={() => { setSuccess(false); setStep("choose"); setSelectedAcademy(null); setForm(defaultForm); setPhoto(null) }}>
              إضافة حساب آخر
            </Button>
            <Button variant="outline" onClick={() => navigate("/dashboard/athletes")}>
              قائمة الرياضيين
            </Button>
          </div>
        </motion.div>
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="text-center">
        <h1 className="text-2xl font-extrabold gradient-text">إضافة مستخدم جديد</h1>
        <p className="mt-1 text-xs text-muted-foreground">
          أنشئ حساب رياضي أو ولي أمر مباشرة من لوحة الإدارة. الحساب يُفعَّل تلقائياً.
        </p>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-error/30 bg-error/10 p-3 text-sm text-error">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      {/* Step indicators */}
      <div className="flex items-center justify-center gap-2 sm:gap-3 text-xs font-bold flex-wrap">
        <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full transition-colors ${step === "choose" ? "bg-primary text-primary-foreground" : "bg-card border border-border text-muted-foreground"}`}>
          <Building2 className="w-3.5 h-3.5" /> 1. اختيار الأكاديمية
        </div>
        <span className="text-muted-foreground">←</span>
        <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full transition-colors ${step === "sport" ? "bg-primary text-primary-foreground" : "bg-card border border-border text-muted-foreground"}`}>
          <Trophy className="w-3.5 h-3.5" /> 2. اختيار الرياضة
        </div>
        <span className="text-muted-foreground">←</span>
        <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full transition-colors ${step === "form" ? "bg-primary text-primary-foreground" : "bg-card border border-border text-muted-foreground"}`}>
          {isParent ? <Users className="w-3.5 h-3.5" /> : <Dumbbell className="w-3.5 h-3.5" />}
          3. البيانات الشخصية
        </div>
      </div>

      <AnimatePresence mode="wait">
        {step === "choose" && (
          <motion.div
            key="choose"
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            className="grid gap-4 sm:grid-cols-2"
          >
            {departments.map((academy) => (
              <button
                key={academy.id}
                type="button"
                onClick={() => handleSelectAcademy(academy)}
                disabled={loadingSports}
                className="group rounded-2xl border-2 border-border bg-card p-8 text-right transition-all hover:shadow-lg hover:-translate-y-0.5 flex flex-col justify-between"
                onMouseEnter={(e) => (e.currentTarget.style.borderColor = academy.color ?? "")}
                onMouseLeave={(e) => (e.currentTarget.style.borderColor = "")}
              >
                <div className="flex items-center justify-between mb-4">
                  <span className="p-1 rounded-xl bg-white border border-gray-100 shadow-sm flex items-center justify-center w-11 h-11 shrink-0 overflow-hidden">
                    <img src={getAcademyLogo(academy)} alt="Logo" className="w-full h-full object-contain" />
                  </span>
                  <Sparkles className="w-4 h-4 text-amber-500" />
                </div>
                <div>
                  <h3 className="text-lg font-black">{academy.name_ar}</h3>
                  <p className="text-xs text-muted-foreground mt-1">
                    {isParentAcademy(academy) ? "حساب ولي أمر — إدارة الأبناء الرياضيين" : "حساب رياضي — التحاق بالتمارين والمجموعات"}
                  </p>
                </div>
              </button>
            ))}
          </motion.div>
        )}

        {step === "sport" && (
          <motion.div
            key="sport"
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            className="space-y-4"
          >
            <div className="flex items-center justify-between bg-card px-4 py-3 rounded-2xl border border-border mb-4 max-w-md mx-auto">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full" style={{ backgroundColor: selectedAcademy?.color ?? "#0F4C81" }} />
                <span className="text-xs font-black">الأكاديمية: {selectedAcademy?.name_ar}</span>
              </div>
              {!deptParam && (
                <button
                  type="button"
                  onClick={() => setStep("choose")}
                  className="text-xs text-primary hover:underline font-bold"
                >
                  تغيير
                </button>
              )}
            </div>

            <div className="grid gap-4 sm:grid-cols-2 max-w-md mx-auto">
              {sports.map((sp) => (
                <button
                  key={sp.id}
                  type="button"
                  onClick={() => { setSelectedSport(sp); setStep("form") }}
                  className="group rounded-2xl border-2 border-border bg-card p-6 text-right transition-all hover:border-primary hover:shadow-lg hover:-translate-y-0.5 flex flex-col justify-between"
                >
                  <div className="flex items-center justify-between mb-3">
                    <span className="p-2 rounded-xl bg-primary/10 text-primary font-bold">
                      <Trophy className="w-5 h-5" />
                    </span>
                  </div>
                  <div>
                    <h3 className="text-base font-black">{sp.name_ar}</h3>
                    <p className="text-xs text-muted-foreground mt-1">اختيار التخصص {sp.name_ar}</p>
                  </div>
                </button>
              ))}
            </div>
            {sports.length === 0 && (
              <div className="text-center py-4">
                <Button onClick={() => setStep("form")} variant="outline">متابعة بدون تحديد رياضة</Button>
              </div>
            )}
          </motion.div>
        )}

        {step === "form" && selectedAcademy && (
          <motion.div
            key="form"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            {/* Selected academy badge */}
            <div className="flex items-center justify-between bg-card px-4 py-3 rounded-2xl border border-border mb-4 max-w-md mx-auto">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full" style={{ backgroundColor: selectedAcademy.color ?? "#0F4C81" }} />
                <span className="text-xs font-black">
                  {selectedAcademy.name_ar} {selectedSport ? `← ${selectedSport.name_ar}` : ""}
                </span>
              </div>
              {!deptParam && (
                <button
                  type="button"
                  onClick={() => setStep(sports.length > 0 ? "sport" : "choose")}
                  className="text-xs text-primary hover:underline font-bold"
                >
                  تغيير
                </button>
              )}
            </div>

            <form onSubmit={handleSubmit} className="space-y-4 rounded-2xl border border-border bg-card p-6 max-w-md mx-auto">
              <div className="text-center mb-2">
                <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-xl" style={{ backgroundColor: (selectedAcademy.color ?? "#0F4C81") + "1A" }}>
                  {isParent
                    ? <Users className="h-6 w-6" style={{ color: selectedAcademy.color ?? "#0F4C81" }} />
                    : <Dumbbell className="h-6 w-6" style={{ color: selectedAcademy.color ?? "#0F4C81" }} />
                  }
                </div>
                <h2 className="text-lg font-bold">
                  {isParent ? "تسجيل ولي أمر جديد" : "تسجيل رياضي جديد"}
                </h2>
              </div>

              {/* Selfie — athletes only */}
              {!isParent && (
                <div>
                  <label className="mb-1.5 block text-sm font-medium">
                    صورة شخصية / سيلفي <span className="text-error">*</span>
                  </label>
                  <CameraCapture onCapture={setPhoto} preview={photo || undefined} />
                </div>
              )}

              {/* Full name */}
              <Field label={isParent ? "اسم ولي الأمر بالكامل" : "اسم الرياضي بالكامل"} required>
                <input
                  className={inputCls}
                  value={form.full_name}
                  onChange={(e) => setForm({ ...form, full_name: e.target.value })}
                  placeholder={isParent ? "أدخل الاسم الثلاثي أو الرباعي" : "أدخل الاسم الرباعي للرياضي"}
                  required
                />
              </Field>

              {/* Phone */}
              {isParent ? (
                <div className="grid grid-cols-2 gap-3">
                  <Field label="رقم الهاتف" required>
                    <input
                      className={inputCls}
                      dir="ltr"
                      value={form.phone}
                      onChange={(e) => setForm({ ...form, phone: e.target.value })}
                      placeholder="0910000000"
                      required
                    />
                  </Field>
                  <Field label="رقم الواتساب">
                    <input
                      className={inputCls}
                      dir="ltr"
                      value={form.whatsapp_phone}
                      onChange={(e) => setForm({ ...form, whatsapp_phone: e.target.value })}
                      placeholder="0920000000"
                    />
                  </Field>
                </div>
              ) : (
                <Field label="رقم هاتف الرياضي" required>
                  <input
                    className={inputCls}
                    dir="ltr"
                    value={form.phone}
                    onChange={(e) => setForm({ ...form, phone: e.target.value })}
                    placeholder="0910000000"
                    required
                  />
                </Field>
              )}

              {/* Residence */}
              <Field label="السكن / العنوان">
                <input
                  className={inputCls}
                  value={form.residence}
                  onChange={(e) => setForm({ ...form, residence: e.target.value })}
                  placeholder="مثال: مصراتة - بالقرب من..."
                />
              </Field>

              {/* Athlete-only fields */}
              {!isParent && (
                <>
                  <Field label="الحالة الصحية / ملاحظات طبية">
                    <textarea
                      rows={2}
                      className={inputCls}
                      value={form.health_status}
                      onChange={(e) => setForm({ ...form, health_status: e.target.value })}
                      placeholder="أدخل أي حالة صحية أو ملاحظات طبية خاصة..."
                    />
                  </Field>

                  <Field label="تاريخ الميلاد" required>
                    <div className="grid grid-cols-3 gap-2">
                      <input
                        type="number" min={1} max={31} placeholder="اليوم"
                        className={inputCls + " text-center"}
                        value={form.birth_day}
                        onChange={(e) => setForm({ ...form, birth_day: e.target.value })}
                        required
                      />
                      <input
                        type="number" min={1} max={12} placeholder="الشهر"
                        className={inputCls + " text-center"}
                        value={form.birth_month}
                        onChange={(e) => setForm({ ...form, birth_month: e.target.value })}
                        required
                      />
                      <input
                        type="number" min={1900} max={2026} placeholder="السنة"
                        className={inputCls + " text-center"}
                        value={form.birth_year}
                        onChange={(e) => setForm({ ...form, birth_year: e.target.value })}
                        required
                      />
                    </div>
                  </Field>
                </>
              )}

              <div className="flex justify-between gap-2 pt-2">
                <Button type="button" variant="ghost" onClick={() => setStep("choose")}>رجوع</Button>
                <Button type="submit" disabled={submitting}>
                  {submitting
                    ? <span className="flex items-center gap-2"><Loader2 className="h-4 w-4 animate-spin" /> جاري...</span>
                    : <>{isParent ? "إنشاء حساب ولي الأمر" : "إنشاء حساب الرياضي"} <ArrowRight className="mr-1 h-4 w-4" /></>
                  }
                </Button>
              </div>
            </form>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

const inputCls = "w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"

function Field({ label, required, children }: { label: string; required?: boolean; children: React.ReactNode }) {
  return (
    <div>
      <label className="mb-1 block text-sm font-medium">
        {label}
        {required && <span className="mr-0.5 text-error">*</span>}
      </label>
      {children}
    </div>
  )
}
