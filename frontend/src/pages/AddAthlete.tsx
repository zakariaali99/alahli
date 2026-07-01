import { useEffect, useRef, useState, type FormEvent } from "react"
import { Link, useNavigate, useSearchParams } from "react-router-dom"
import { motion, AnimatePresence } from "framer-motion"
import { ArrowRight, Dumbbell, Users, Camera, X, CheckCircle, AlertCircle, Loader2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { api } from "@/lib/api"
import { useToast } from "@/lib/toast"
import { extractResults } from "@/lib/response"
import type { Department, RegistrationRequest } from "@/lib/types"
import { validateLibyanPhone } from "@/lib/utils"
import CameraCapture from "@/components/ui/camera-capture"

type Scenario = "choose" | "athlete" | "parent"

type AthleteForm = {
  full_name: string
  phone: string
  password: string
  gender: "male" | "female"
  department: string
  birth_day: string
  birth_month: string
  birth_year: string
  weight: string
  height: string
}

type ParentForm = {
  full_name: string
  phone: string
  password: string
  birth_day: string
  birth_month: string
  birth_year: string
}

const defaultAthleteForm: AthleteForm = {
  full_name: "", phone: "", password: "",
  gender: "male", department: "",
  birth_day: "", birth_month: "", birth_year: "",
  weight: "", height: "",
}

const defaultParentForm: ParentForm = {
  full_name: "", phone: "", password: "",
  birth_day: "", birth_month: "", birth_year: "",
}

export default function AddAthletePage() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const registrationId = searchParams.get("registration")
  const toast = useToast()

  const [scenario, setScenario] = useState<Scenario>("choose")
  const [registration, setRegistration] = useState<RegistrationRequest | null>(null)
  const [loadingRegistration, setLoadingRegistration] = useState(false)
  const [departments, setDepartments] = useState<Department[]>([])
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState("")
  const [success, setSuccess] = useState(false)

  const [athleteForm, setAthleteForm] = useState<AthleteForm>(defaultAthleteForm)
  const [parentForm, setParentForm] = useState<ParentForm>(defaultParentForm)
  const [photo, setPhoto] = useState<string | null>(null)

  useEffect(() => {
    const fetchDepartments = async () => {
      try {
        const res = await api.get<{ results: Department[] } | Department[]>("/departments/")
        setDepartments(extractResults(res))
      } catch {
        setDepartments([])
      }
    }

    void fetchDepartments()
  }, [])

  useEffect(() => {
    if (!registrationId) return
    const fetchRegistration = async () => {
      try {
        setLoadingRegistration(true)
        const data = await api.get<RegistrationRequest>(`/athletes/registrations/${registrationId}/`)
        setRegistration(data)
        if (data.user_name) {
          setAthleteForm((prev) => ({ ...prev, full_name: data.user_name, phone: data.user_phone }))
        }
      } catch (err: any) {
        setError(err?.message || "تعذر تحميل طلب التسجيل")
      } finally {
        setLoadingRegistration(false)
      }
    }
    void fetchRegistration()
  }, [registrationId])

  const handleSubmitAthlete = async (e: FormEvent) => {
    e.preventDefault()
    setError("")

    if (!athleteForm.full_name.trim() || !athleteForm.phone.trim()) {
      setError("يرجى تعبئة الاسم ورقم الهاتف")
      return
    }

    const phoneErr = validateLibyanPhone(athleteForm.phone)
    if (phoneErr) { setError(phoneErr); return }

    if (!registrationId && !athleteForm.password.trim()) {
      setError("يرجى تعبئة كلمة المرور")
      return
    }
    if (!athleteForm.birth_day || !athleteForm.birth_month || !athleteForm.birth_year) {
      setError("يرجى تعبئة تاريخ الميلاد")
      return
    }
    if (!photo && !registration?.athlete_photo) {
      setError("يرجى التقاط أو رفع صورة شخصية للرياضي")
      return
    }

    try {
      setSubmitting(true)

      if (registrationId) {
        const fd = new FormData()
        fd.append("full_name", athleteForm.full_name.trim())
        fd.append("phone", athleteForm.phone.trim())
        fd.append("gender", athleteForm.gender)
        if (athleteForm.department) {
          fd.append("department", athleteForm.department)
        }
        fd.append("birth_date", `${athleteForm.birth_year}-${athleteForm.birth_month.padStart(2, "0")}-${athleteForm.birth_day.padStart(2, "0")}`)
        const created = await api.post<{ id: number }>(
          `/athletes/registrations/${registrationId}/create-athlete/`,
          fd,
          { formData: true },
        )
        toast.success("تم إنشاء ملف الرياضي بنجاح")
        navigate(`/dashboard/athletes/${created.id}`)
        return
      }

      const fd = new FormData()
      fd.append("full_name", athleteForm.full_name.trim())
      fd.append("phone", athleteForm.phone.trim())
      fd.append("password", athleteForm.password.trim())
      fd.append("gender", athleteForm.gender)
      if (athleteForm.department) {
        fd.append("department", athleteForm.department)
      }
      fd.append("is_active", "true")
      fd.append("birth_date", `${athleteForm.birth_year}-${athleteForm.birth_month.padStart(2, "0")}-${athleteForm.birth_day.padStart(2, "0")}`)

      const weight = parseFloat(athleteForm.weight)
      const height = parseFloat(athleteForm.height)
      if (!Number.isNaN(weight) || !Number.isNaN(height)) {
        fd.append("notes", `Weight: ${Number.isNaN(weight) ? "" : weight} | Height: ${Number.isNaN(height) ? "" : height}`)
      }

      const createdAthlete = await api.post<{ id: number }>("/athletes/", fd, { formData: true })
      toast.success("تم إنشاء الرياضي وربطه بحسابه بنجاح")
      navigate(`/dashboard/athletes/${createdAthlete.id}`)
    } catch (err: any) {
      setError(err?.message || "حدث خطأ أثناء التسجيل")
    } finally {
      setSubmitting(false)
    }
  }

  const handleSubmitParent = async (e: FormEvent) => {
    e.preventDefault()
    setError("")

    if (!parentForm.full_name.trim() || !parentForm.phone.trim() || !parentForm.password.trim()) {
      setError("يرجى تعبئة الاسم ورقم الهاتف وكلمة المرور")
      return
    }

    const parentPhoneErr = validateLibyanPhone(parentForm.phone)
    if (parentPhoneErr) { setError(parentPhoneErr); return }

    try {
      setSubmitting(true)
      await api.post("/auth/register/", {
        role: "parent",
        full_name: parentForm.full_name.trim(),
        phone: parentForm.phone.trim(),
        password: parentForm.password,
        birth_day: parseInt(parentForm.birth_day),
        birth_month: parseInt(parentForm.birth_month),
        birth_year: parseInt(parentForm.birth_year),
      })
      setSuccess(true)
      toast.success("تم تسجيل ولي الأمر بنجاح")
    } catch (err: any) {
      setError(err?.message || "حدث خطأ أثناء التسجيل")
    } finally {
      setSubmitting(false)
    }
  }

  if (success) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="text-center">
          <CheckCircle className="mx-auto mb-4 h-16 w-16 text-primary" />
          <h2 className="mb-2 text-2xl font-bold">تم التسجيل بنجاح</h2>
          <p className="mb-6 text-muted-foreground">
            {registrationId
              ? "تم إنشاء ملف الرياضي وربطه بالطلب. يمكنك الآن مراجعته واعتماده."
              : "تم إنشاء الحساب. يمكن للمستخدم الآن تسجيل الدخول."}
          </p>
          <div className="flex justify-center gap-3">
            <Button onClick={() => navigate("/dashboard/registrations")}>الطلبات الجديدة</Button>
            <Button variant="outline" onClick={() => navigate("/dashboard/athletes")}>قائمة الرياضيين</Button>
          </div>
        </motion.div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-extrabold gradient-text">إضافة مستخدم جديد</h1>
        <p className="mt-1 text-xs text-muted-foreground">
          {registrationId
            ? `إنشاء ملف رياضي لطلب التسجيل: ${registration?.user_name || "..."}`
            : "أنشئ حساب رياضي أو ولي أمر مباشرة من لوحة الإدارة."}
        </p>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-error/30 bg-error/10 p-3 text-sm text-error">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      <AnimatePresence mode="wait">
        {scenario === "choose" && (
          <motion.div
            key="choose"
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            className="grid gap-4 sm:grid-cols-2"
          >
            <button
              onClick={() => setScenario("athlete")}
              className="group rounded-2xl border-2 border-border bg-card p-8 text-center transition hover:border-primary hover:bg-primary/5"
            >
              <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10 transition group-hover:scale-110">
                <Dumbbell className="h-8 w-8 text-primary" />
              </div>
              <h3 className="text-lg font-bold">تسجيل رياضي</h3>
              <p className="mt-1 text-xs text-muted-foreground">أنشئ حساب رياضي مع صورة وبيانات بدنية</p>
            </button>

            <button
              onClick={() => setScenario("parent")}
              className="group rounded-2xl border-2 border-border bg-card p-8 text-center transition hover:border-primary hover:bg-primary/5"
            >
              <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-secondary/10 transition group-hover:scale-110">
                <Users className="h-8 w-8 text-secondary" />
              </div>
              <h3 className="text-lg font-bold">تسجيل ولي أمر</h3>
              <p className="mt-1 text-xs text-muted-foreground">أنشئ حساب ولي أمر لإدارة الرياضيين</p>
            </button>
          </motion.div>
        )}

        {scenario === "athlete" && (
          <motion.div
            key="athlete"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            <form onSubmit={handleSubmitAthlete} className="mx-auto max-w-md space-y-4 rounded-2xl border border-border bg-card p-6">
              <div className="text-center">
                <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10">
                  <Dumbbell className="h-6 w-6 text-primary" />
                </div>
                <h2 className="text-lg font-bold">تسجيل رياضي جديد</h2>
              </div>

              <CameraCapture onCapture={setPhoto} preview={photo || registration?.athlete_photo || undefined} />

              <FormField label="الاسم الكامل" required>
                <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={athleteForm.full_name} onChange={(e) => setAthleteForm((p) => ({ ...p, full_name: e.target.value }))} required />
              </FormField>

              <FormField label="رقم الهاتف" required>
                <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" dir="ltr" value={athleteForm.phone} onChange={(e) => setAthleteForm((p) => ({ ...p, phone: e.target.value }))} required />
              </FormField>

              {!registrationId && (
                <FormField label="كلمة المرور" required>
                  <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="password" value={athleteForm.password} onChange={(e) => setAthleteForm((p) => ({ ...p, password: e.target.value }))} required />
                </FormField>
              )}

              {!registrationId && (
                <div className="grid grid-cols-2 gap-3">
                  <FormField label="الجنس" required>
                    <select
                      className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
                      value={athleteForm.gender}
                      onChange={(e) => setAthleteForm((p) => ({ ...p, gender: e.target.value as "male" | "female" }))}
                    >
                      <option value="male">ذكر</option>
                      <option value="female">أنثى</option>
                    </select>
                  </FormField>
                  <FormField label="الأكاديمية/القسم">
                    <select
                      className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
                      value={athleteForm.department}
                      onChange={(e) => setAthleteForm((p) => ({ ...p, department: e.target.value }))}
                    >
                      <option value="">بدون قسم</option>
                      {departments.map((dept) => (
                        <option key={dept.id} value={String(dept.id)}>{dept.name_ar}</option>
                      ))}
                    </select>
                  </FormField>
                </div>
              )}

              {registrationId && (
                <FormField label="الأكاديمية/القسم" required>
                  <select
                    className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
                    value={athleteForm.department}
                    onChange={(e) => setAthleteForm((p) => ({ ...p, department: e.target.value }))}
                    required
                  >
                    <option value="">اختر القسم</option>
                    {departments.map((dept) => (
                      <option key={dept.id} value={String(dept.id)}>{dept.name_ar}</option>
                    ))}
                  </select>
                </FormField>
              )}

              <FormField label="تاريخ الميلاد" required>
                <div className="grid grid-cols-3 gap-2">
                  <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="number" min={1} max={31} placeholder="DD" value={athleteForm.birth_day} onChange={(e) => setAthleteForm((p) => ({ ...p, birth_day: e.target.value }))} required />
                  <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="number" min={1} max={12} placeholder="MM" value={athleteForm.birth_month} onChange={(e) => setAthleteForm((p) => ({ ...p, birth_month: e.target.value }))} required />
                  <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="number" min={1900} max={2026} placeholder="YY" value={athleteForm.birth_year} onChange={(e) => setAthleteForm((p) => ({ ...p, birth_year: e.target.value }))} required />
                </div>
              </FormField>

              <div className="grid grid-cols-2 gap-3">
                <FormField label="الوزن (كجم)">
                  <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="number" step="0.1" value={athleteForm.weight} onChange={(e) => setAthleteForm((p) => ({ ...p, weight: e.target.value }))} />
                </FormField>
                <FormField label="الطول (سم)">
                  <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="number" step="0.1" value={athleteForm.height} onChange={(e) => setAthleteForm((p) => ({ ...p, height: e.target.value }))} />
                </FormField>
              </div>

              <div className="flex justify-between gap-2 pt-2">
                <Button type="button" variant="ghost" onClick={() => setScenario("choose")}>رجوع</Button>
                <Button type="submit" disabled={submitting || loadingRegistration}>
                  {submitting ? <span className="flex items-center gap-2"><Loader2 className="h-4 w-4 animate-spin" /> جاري...</span> : <>{registrationId ? "إنشاء الملف الرياضي" : "إنشاء الرياضي"} <ArrowRight className="mr-1 h-4 w-4" /></>}
                </Button>
              </div>
            </form>
          </motion.div>
        )}

        {scenario === "parent" && (
          <motion.div
            key="parent"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            <form onSubmit={handleSubmitParent} className="mx-auto max-w-md space-y-4 rounded-2xl border border-border bg-card p-6">
              <div className="text-center">
                <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-xl bg-secondary/10">
                  <Users className="h-6 w-6 text-secondary" />
                </div>
                <h2 className="text-lg font-bold">تسجيل ولي أمر</h2>
              </div>

              <FormField label="الاسم الكامل" required>
                <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={parentForm.full_name} onChange={(e) => setParentForm((p) => ({ ...p, full_name: e.target.value }))} required />
              </FormField>

              <FormField label="رقم الهاتف" required>
                <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" dir="ltr" value={parentForm.phone} onChange={(e) => setParentForm((p) => ({ ...p, phone: e.target.value }))} required />
              </FormField>

              <FormField label="كلمة المرور" required>
                <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="password" value={parentForm.password} onChange={(e) => setParentForm((p) => ({ ...p, password: e.target.value }))} required />
              </FormField>

              <FormField label="تاريخ الميلاد" required>
                <div className="grid grid-cols-3 gap-2">
                  <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="number" min={1} max={31} placeholder="DD" value={parentForm.birth_day} onChange={(e) => setParentForm((p) => ({ ...p, birth_day: e.target.value }))} required />
                  <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="number" min={1} max={12} placeholder="MM" value={parentForm.birth_month} onChange={(e) => setParentForm((p) => ({ ...p, birth_month: e.target.value }))} required />
                  <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="number" min={1900} max={2026} placeholder="YY" value={parentForm.birth_year} onChange={(e) => setParentForm((p) => ({ ...p, birth_year: e.target.value }))} required />
                </div>
              </FormField>

              <div className="flex justify-between gap-2 pt-2">
                <Button type="button" variant="ghost" onClick={() => setScenario("choose")}>رجوع</Button>
                <Button type="submit" disabled={submitting}>
                  {submitting ? <span className="flex items-center gap-2"><Loader2 className="h-4 w-4 animate-spin" /> جاري...</span> : <>تسجيل <ArrowRight className="mr-1 h-4 w-4" /></>}
                </Button>
              </div>
            </form>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

function FormField({ label, required, children }: { label: string; required?: boolean; children: React.ReactNode }) {
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
