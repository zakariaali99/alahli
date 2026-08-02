import { useState, useEffect, useMemo, useRef, type ChangeEvent, type ReactNode } from "react"
import { useNavigate, useSearchParams } from "react-router-dom"
import { motion, AnimatePresence } from "framer-motion"
import { ArrowRight, Dumbbell, Users, CheckCircle, AlertCircle, Loader2, Building2, Sparkles, Trophy, RefreshCw, AlertTriangle, ImagePlus, CreditCard, Landmark, Banknote } from "lucide-react"
import { Button } from "@/components/ui/button"
import { api } from "@/lib/api"
import { useToast } from "@/lib/toast"
import { validateLibyanPhone } from "@/lib/utils"
import { extractResults } from "@/lib/response"
import { useDepartments } from "@/lib/hooks/useDepartments"
import { usePackages } from "@/lib/hooks/usePackages"
import type { Department, Sport } from "@/lib/types"
import { isParentAcademy, getAcademyLogo } from "@/lib/departments"

type Step = "choose" | "sport" | "form" | "pay"

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

const defaultSubForm = {
  package_id: "",
  start_date: "",
  end_date: "",
  amount: "",
  payment_method: "cash" as "cash" | "bank_transfer",
}

export default function AddAthletePage() {
  const navigate = useNavigate()
  const toast = useToast()
  const photoInputRef = useRef<HTMLInputElement>(null)
  const invoiceInputRef = useRef<HTMLInputElement>(null)

  const [step, setStep] = useState<Step>("choose")
  const [selectedAcademy, setSelectedAcademy] = useState<Department | null>(null)
  const [sports, setSports] = useState<Sport[]>([])
  const [selectedSport, setSelectedSport] = useState<Sport | null>(null)
  const [loadingSports, setLoadingSports] = useState(false)
  const [sportsError, setSportsError] = useState(false)

  const { data: deptsData } = useDepartments()
  const departments = useMemo(() => {
    const list = extractResults<Department>(deptsData)
    return list.length > 0 ? list : ACADEMIES
  }, [deptsData])

  const [form, setForm] = useState(defaultForm)
  const [photo, setPhoto] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState("")
  const [success, setSuccess] = useState(false)

  const [athleteId, setAthleteId] = useState<number | null>(null)
  const [subForm, setSubForm] = useState(defaultSubForm)
  const [invoicePdf, setInvoicePdf] = useState<File | null>(null)

  const [searchParams] = useSearchParams()
  const deptParam = searchParams.get("department")
  const sportParam = searchParams.get("sport")
  const isParent = isParentAcademy(selectedAcademy)

  const { data: packagesData } = usePackages(deptParam ?? undefined)
  const packages = packagesData?.results ?? []

  const handleSelectAcademy = async (academy: Department) => {
    setSelectedAcademy(academy)
    setSelectedSport(null)
    setForm(defaultForm)
    setPhoto(null)
    setError("")
    setSportsError(false)

    if (isParentAcademy(academy)) {
      setStep("form")
      return
    }

    setLoadingSports(true)
    try {
      const res = await api.get<{ results: Sport[] } | Sport[]>("/sports/", { department: String(academy.id) })
      const list = extractResults(res)
      setSports(list)
      setStep(sportParam && list.some((s) => s.id === Number(sportParam)) ? "form" : list.length > 0 ? "sport" : "form")
    } catch {
      setSports([])
      setSportsError(true)
      setStep("sport")
    } finally {
      setLoadingSports(false)
    }
  }

  useEffect(() => {
    if (!deptParam) return
    const deptId = Number(deptParam)
    if (selectedAcademy?.id === deptId) return
    const match = departments.find((a) => a.id === deptId)
    if (match) {
      void handleSelectAcademy(match)
    }
  }, [deptParam, departments, selectedAcademy])

  useEffect(() => {
    if (!sportParam || sports.length === 0) return
    const match = sports.find((s) => s.id === Number(sportParam))
    if (match) {
      setSelectedSport(match)
    }
  }, [sportParam, sports])

  const onPhotoFile = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = () => {
      const result = reader.result
      if (typeof result === "string") setPhoto(result)
    }
    reader.readAsDataURL(file)
    event.target.value = ""
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

    if (!selectedAcademy) { setStep("choose"); return }

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
      body.whatsapp_phone = form.phone.trim()
    } else {
      if (photo) body.photo = photo
      body.health_status = form.health_status
      body.birth_day = parseInt(form.birth_day)
      body.birth_month = parseInt(form.birth_month)
      body.birth_year = parseInt(form.birth_year)
    }

    try {
      setSubmitting(true)
      const res = await api.post<{ athlete_id?: number; user_id?: number }>("/auth/register/", body)
      toast.success("تم إنشاء الحساب بنجاح")
      if (isParent) {
        if (res?.user_id) {
          const sportQuery = selectedSport ? `&sport=${selectedSport.id}` : ""
          navigate(`/dashboard/parents/${res.user_id}?department=${selectedAcademy.id}${sportQuery}`)
        } else {
          setSuccess(true)
        }
      } else if (res?.athlete_id) {
        setAthleteId(res.athlete_id)
        setSubForm({
          ...defaultSubForm,
          start_date: new Date().toISOString().slice(0, 10),
        })
        setInvoicePdf(null)
        setStep("pay")
      } else {
        setSuccess(true)
      }
    } catch (err: any) {
      setError(api.getErrorMessage(err, "حدث خطأ أثناء التسجيل"))
    } finally {
      setSubmitting(false)
    }
  }

  const onPackageChange = (id: string) => {
    if (!id) {
      setSubForm((prev) => ({ ...prev, package_id: "", amount: "", end_date: "" }))
      return
    }
    const pkg = packages.find((p) => p.id === Number(id))
    if (!pkg) return
    const start = subForm.start_date || new Date().toISOString().slice(0, 10)
    const date = new Date(start)
    if (pkg.duration_type === "weeks") {
      date.setDate(date.getDate() + pkg.duration_value * 7)
    } else {
      date.setMonth(date.getMonth() + pkg.duration_value)
    }
    setSubForm((prev) => ({
      ...prev,
      package_id: id,
      amount: pkg.new_price || pkg.price,
      end_date: date.toISOString().slice(0, 10),
    }))
  }

  const submitSubscription = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")
    if (!athleteId || !selectedAcademy) return
    if (!subForm.start_date || !subForm.end_date || !subForm.amount) {
      setError("يرجى استكمال بيانات الدفع (المبلغ وتواريخ الاشتراك)")
      return
    }

    try {
      setSubmitting(true)
      const payload = new FormData()
      payload.append("athlete", String(athleteId))
      if (subForm.package_id) payload.append("package_id", subForm.package_id)
      payload.append("start_date", subForm.start_date)
      payload.append("end_date", subForm.end_date)
      payload.append("amount", subForm.amount)
      payload.append("payment_method", subForm.payment_method)
      payload.append("status", "active")
      if (invoicePdf) payload.append("invoice_pdf", invoicePdf)

      await api.post("/subscriptions/", payload, { formData: true })
      toast.success("تم إنشاء الاشتراك وتفعيله بنجاح")
      const sportQuery = selectedSport ? `&sport=${selectedSport.id}` : ""
      navigate(`/dashboard/athletes?department=${selectedAcademy.id}${sportQuery}`)
    } catch (err: any) {
      setError(api.getErrorMessage(err, "تعذر إنشاء الاشتراك"))
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

  const stepChips: Array<{ key: Step; label: string; icon: ReactNode }> = [
    { key: "choose", label: "اختيار الأكاديمية", icon: <Building2 className="w-3.5 h-3.5" /> },
    ...(!isParent && !sportParam
      ? [{ key: "sport" as Step, label: "اختيار الرياضة", icon: <Trophy className="w-3.5 h-3.5" /> }]
      : []),
    { key: "form", label: "البيانات الشخصية", icon: isParent ? <Users className="w-3.5 h-3.5" /> : <Dumbbell className="w-3.5 h-3.5" /> },
    ...(!isParent
      ? [{ key: "pay" as Step, label: "الدفع والاشتراك", icon: <CreditCard className="w-3.5 h-3.5" /> }]
      : []),
  ]

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
        {stepChips.map((chip, i) => (
          <span key={chip.key} className="flex items-center gap-2">
            {i > 0 && <span className="text-muted-foreground">←</span>}
            <span className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full transition-colors ${step === chip.key ? "bg-primary text-primary-foreground" : "bg-card border border-border text-muted-foreground"}`}>
              {chip.icon} {i + 1}. {chip.label}
            </span>
          </span>
        ))}
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
                    {isParentAcademy(academy) ? "حساب ولي أمر — إدارة الأبناء الرياضيين" : "حساب رياضي — الالتحاق بالتمارين والمجموعات"}
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
              {sports.map((sp) => {
                const isSelected = selectedSport?.id === sp.id
                return (
                  <button
                    key={sp.id}
                    type="button"
                    onClick={() => { setSelectedSport(sp); setStep("form") }}
                    className={`group rounded-2xl border-2 bg-card p-6 text-right transition-all hover:border-primary hover:shadow-lg hover:-translate-y-0.5 flex flex-col justify-between ${
                      isSelected ? "border-primary shadow-lg" : "border-border"
                    }`}
                  >
                    <div className="flex items-center justify-between mb-3">
                      <span className={`p-2 rounded-xl font-bold ${isSelected ? "bg-primary text-white" : "bg-primary/10 text-primary"}`}>
                        <Trophy className="w-5 h-5" />
                      </span>
                      {isSelected && <CheckCircle className="w-5 h-5 text-primary" />}
                    </div>
                    <div>
                      <h3 className="text-base font-black">{sp.name_ar}</h3>
                      <p className="text-xs text-muted-foreground mt-1">اختيار التخصص {sp.name_ar}</p>
                    </div>
                  </button>
                )
              })}
            </div>
            {loadingSports && (
              <div className="flex items-center justify-center gap-2 py-6 text-muted-foreground text-sm">
                <Loader2 className="w-4 h-4 animate-spin" />
                جاري تحميل الرياضات...
              </div>
            )}
            {sportsError && (
              <div className="text-center py-4 space-y-3">
                <div className="flex items-center justify-center gap-2 text-error text-sm font-bold">
                  <AlertTriangle className="w-4 h-4" />
                  تعذر تحميل الرياضات. يرجى المحاولة مرة أخرى.
                </div>
                <Button
                  onClick={() => { if (selectedAcademy) void handleSelectAcademy(selectedAcademy) }}
                  variant="outline"
                >
                  <RefreshCw className="w-4 h-4 ml-1" />
                  إعادة المحاولة
                </Button>
              </div>
            )}
            {!loadingSports && !sportsError && sports.length === 0 && (
              <div className="text-center py-4 space-y-2">
                <p className="text-sm text-muted-foreground font-semibold">لا توجد رياضات مسجلة في هذه الأكاديمية</p>
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
                  onClick={() => setStep("choose")}
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

              {/* Photo — optional, library only */}
              {!isParent && (
                <Field label="صورة شخصية (اختياري)">
                  <div className="flex items-center gap-3">
                    {photo ? (
                      <div className="w-16 h-16 rounded-full overflow-hidden border-2 border-primary shrink-0">
                        <img src={photo} alt="" className="w-full h-full object-cover" />
                      </div>
                    ) : (
                      <div className="w-16 h-16 rounded-full bg-surface-container-high flex items-center justify-center border-2 border-dashed border-border shrink-0">
                        <ImagePlus className="w-6 h-6 text-muted-foreground" />
                      </div>
                    )}
                    <div className="space-y-1">
                      <Button type="button" variant="outline" size="sm" onClick={() => photoInputRef.current?.click()}>
                        <ImagePlus className="w-4 h-4 ml-1" />
                        اختيار صورة من الجهاز
                      </Button>
                      {photo && (
                        <button type="button" className="block text-xs text-error font-semibold hover:underline" onClick={() => setPhoto(null)}>
                          إزالة الصورة
                        </button>
                      )}
                    </div>
                  </div>
                  <input ref={photoInputRef} type="file" accept="image/*" className="hidden" onChange={onPhotoFile} />
                </Field>
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

              {/* Phone — single number for parents */}
              {isParent ? (
                <Field label="رقم الهاتف (الواتساب)" required>
                  <input
                    className={inputCls}
                    dir="ltr"
                    value={form.phone}
                    onChange={(e) => setForm({ ...form, phone: e.target.value })}
                    placeholder="0910000000"
                    required
                  />
                </Field>
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
                    : <>{isParent ? "إنشاء حساب ولي الأمر" : "متابعة إلى الدفع"} <ArrowRight className="mr-1 h-4 w-4" /></>
                  }
                </Button>
              </div>
            </form>
          </motion.div>
        )}

        {step === "pay" && athleteId && selectedAcademy && (
          <motion.div
            key="pay"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            <div className="flex items-center justify-between bg-card px-4 py-3 rounded-2xl border border-border mb-4 max-w-md mx-auto">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full" style={{ backgroundColor: selectedAcademy.color ?? "#0F4C81" }} />
                <span className="text-xs font-black">
                  {form.full_name} {selectedSport ? `← ${selectedSport.name_ar}` : ""}
                </span>
              </div>
              <CheckCircle className="w-4 h-4 text-secondary" />
            </div>

            <form onSubmit={submitSubscription} className="space-y-4 rounded-2xl border border-border bg-card p-6 max-w-md mx-auto">
              <div className="text-center mb-2">
                <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10 text-primary">
                  <CreditCard className="h-6 w-6" />
                </div>
                <h2 className="text-lg font-bold">الدفع واشتراك العضوية</h2>
                <p className="text-xs text-muted-foreground mt-1">اختر الباقة المناسبة لتفعيل اشتراك الرياضي</p>
              </div>

              <Field label="الباقة">
                <select
                  className={inputCls + " cursor-pointer"}
                  value={subForm.package_id}
                  onChange={(e) => onPackageChange(e.target.value)}
                >
                  <option value="">بدون باقة (إدخال يدوي)</option>
                  {packages.map((pkg) => (
                    <option key={pkg.id} value={String(pkg.id)}>
                      {pkg.name} — جديد {Number(pkg.new_price || pkg.price).toLocaleString("ar-SA-u-nu-latn")} د.ل
                      {Number(pkg.renewal_price) > 0 ? ` / تجديد ${Number(pkg.renewal_price).toLocaleString("ar-SA-u-nu-latn")} د.ل` : ""}
                    </option>
                  ))}
                </select>
                {packages.length === 0 && (
                  <p className="mt-1 text-[11px] text-muted-foreground">لا توجد باقات مسجلة لهذه الأكاديمية — أدخل المبلغ والفترة يدوياً.</p>
                )}
              </Field>

              <div className="grid grid-cols-2 gap-3">
                <Field label="المبلغ (د.ل)" required>
                  <input
                    type="number" min="0" step="0.01"
                    className={inputCls}
                    value={subForm.amount}
                    onChange={(e) => setSubForm((prev) => ({ ...prev, amount: e.target.value }))}
                    placeholder="0.00"
                    required
                  />
                </Field>
                <Field label="تاريخ البدء" required>
                  <input
                    type="date"
                    className={inputCls}
                    value={subForm.start_date}
                    onChange={(e) => {
                      const start = e.target.value
                      const pkg = packages.find((p) => p.id === Number(subForm.package_id))
                      let end = ""
                      if (pkg) {
                        const date = new Date(start)
                        if (pkg.duration_type === "weeks") date.setDate(date.getDate() + pkg.duration_value * 7)
                        else date.setMonth(date.getMonth() + pkg.duration_value)
                        end = date.toISOString().slice(0, 10)
                      }
                      setSubForm((prev) => ({ ...prev, start_date: start, end_date: end || prev.end_date }))
                    }}
                    required
                  />
                </Field>
                <Field label="تاريخ الانتهاء" required>
                  <input
                    type="date"
                    className={inputCls}
                    value={subForm.end_date}
                    onChange={(e) => setSubForm((prev) => ({ ...prev, end_date: e.target.value }))}
                    required
                  />
                </Field>
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium">طريقة الدفع <span className="mr-0.5 text-error">*</span></label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => setSubForm((prev) => ({ ...prev, payment_method: "cash" }))}
                    className={`flex items-center gap-2 rounded-xl border-2 px-3 py-2.5 text-sm font-bold transition-all ${
                      subForm.payment_method === "cash" ? "border-primary bg-primary/5 text-primary" : "border-border bg-surface-container-low text-muted-foreground hover:border-primary/40"
                    }`}
                  >
                    <Banknote className="w-4 h-4" /> نقدي
                  </button>
                  <button
                    type="button"
                    onClick={() => setSubForm((prev) => ({ ...prev, payment_method: "bank_transfer" }))}
                    className={`flex items-center gap-2 rounded-xl border-2 px-3 py-2.5 text-sm font-bold transition-all ${
                      subForm.payment_method === "bank_transfer" ? "border-primary bg-primary/5 text-primary" : "border-border bg-surface-container-low text-muted-foreground hover:border-primary/40"
                    }`}
                  >
                    <Landmark className="w-4 h-4" /> تحويل مصرفي
                  </button>
                </div>
              </div>

              {subForm.payment_method === "bank_transfer" && (
                <Field label="إيصال التحويل (PDF — اختياري)">
                  <div className="flex items-center gap-2">
                    <input
                      ref={invoiceInputRef}
                      type="file"
                      accept="application/pdf,.pdf"
                      className="hidden"
                      onChange={(e) => setInvoicePdf(e.target.files?.[0] || null)}
                    />
                    <Button type="button" variant="outline" size="sm" onClick={() => invoiceInputRef.current?.click()}>
                      <ImagePlus className="w-4 h-4 ml-1" />
                      {invoicePdf ? invoicePdf.name : "إرفاق الإيصال"}
                    </Button>
                    {invoicePdf && (
                      <button type="button" className="text-xs text-error font-semibold hover:underline" onClick={() => setInvoicePdf(null)}>
                        إزالة
                      </button>
                    )}
                  </div>
                </Field>
              )}

              <div className="flex justify-between gap-2 pt-2">
                <Button type="button" variant="ghost" onClick={() => setStep("form")}>رجوع</Button>
                <Button type="submit" disabled={submitting}>
                  {submitting
                    ? <span className="flex items-center gap-2"><Loader2 className="h-4 w-4 animate-spin" /> جاري...</span>
                    : <>تأكيد الدفع وتفعيل الاشتراك <ArrowRight className="mr-1 h-4 w-4" /></>
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
