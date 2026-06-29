import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { api } from "@/lib/api"
import { extractResults } from "@/lib/response"
import type { Department, Sport, Group, Package, ParentAthlete } from "@/lib/types"
import { CreditCard, Building, CheckCircle, Copy, ChevronLeft, ChevronRight, Upload, User } from "lucide-react"
import { useAuth } from "@/lib/auth"

const WEEKDAY_MAP: Record<string, string> = {
  saturday: "السبت", sunday: "الأحد", monday: "الإثنين",
  tuesday: "الثلاثاء", wednesday: "الأربعاء", thursday: "الخميس", friday: "الجمعة",
}

type StepData = {
  athleteId: number | null
  academy: Department | null
  sport: Sport | null
  group: Group | null
  pkg: Package | null
  paymentMethod: "cash" | "bank_transfer" | null
}

const latinNumber = (value: number | string) =>
  Number(value).toLocaleString("ar-SA-u-nu-latn")

const formatDate = (value: string) =>
  new Date(value).toLocaleDateString("ar-SA-u-nu-latn", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  })

export default function SubscriptionPage() {
  const { user } = useAuth()
  const isParent = user?.role === "parent"

  const [step, setStep] = useState(0)
  const [data, setData] = useState<StepData>({
    athleteId: null,
    academy: null,
    sport: null,
    group: null,
    pkg: null,
    paymentMethod: null,
  })

  const [athletes, setAthletes] = useState<ParentAthlete[]>([])
  const [academies, setAcademies] = useState<Department[]>([])
  const [sports, setSports] = useState<Sport[]>([])
  const [groups, setGroups] = useState<Group[]>([])
  const [packages, setPackages] = useState<Package[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")
  const [pdfFile, setPdfFile] = useState<File | null>(null)
  const [copied, setCopied] = useState("")
  const [success, setSuccess] = useState(false)
  const [bankInfo, setBankInfo] = useState<{ account_number?: string; iban?: string } | null>(null)
  const [bankLoading, setBankLoading] = useState(false)

  useEffect(() => {
    setError("")
    if (isParent) {
      fetchAthletes()
    } else {
      setData((prev) => ({ ...prev, athleteId: user?.id ?? null }))
      fetchAcademies()
    }
  }, [isParent, user?.id])

  const fetchAthletes = async () => {
    setLoading(true)
    setError("")
    try {
      const res = await api.get<{ results: ParentAthlete[] } | ParentAthlete[]>("/athletes/parent/athletes/")
      setAthletes(extractResults(res))
    } catch {
      setError("فشل تحميل الرياضيين")
    } finally {
      setLoading(false)
    }
  }

  const fetchAcademies = async () => {
    setLoading(true)
    setError("")
    try {
      const res = await api.get<{ results: Department[] } | Department[]>("/departments/")
      setAcademies(extractResults(res))
    } catch {
      setError("فشل تحميل الأكاديميات")
    } finally {
      setLoading(false)
    }
  }

  const fetchSports = async (deptId: number) => {
    setLoading(true)
    setError("")
    try {
      const res = await api.get<{ results: Sport[] } | Sport[]>(`/sports/?department=${deptId}`)
      setSports(extractResults(res))
    } catch {
      setError("فشل تحميل الرياضات")
    } finally {
      setLoading(false)
    }
  }

  const fetchGroups = async (sportId: number) => {
    setLoading(true)
    setError("")
    try {
      const res = await api.get<{ results: Group[] } | Group[]>(`/groups/?sport=${sportId}`)
      setGroups(extractResults(res))
    } catch {
      setError("فشل تحميل المجموعات")
    } finally {
      setLoading(false)
    }
  }

  const fetchPackages = async () => {
    setLoading(true)
    setError("")
    try {
      const res = await api.get<{ results: Package[] } | Package[]>("/packages/")
      const tagRank: Record<Package["tag"], number> = { discount: 0, special: 1, normal: 2 }
      const sorted = [...extractResults(res)].sort((a, b) => {
        const rankDiff = tagRank[a.tag] - tagRank[b.tag]
        if (rankDiff !== 0) return rankDiff
        return a.order - b.order
      })
      setPackages(sorted)
    } catch {
      setError("فشل تحميل الباقات")
    } finally {
      setLoading(false)
    }
  }

  const selectAthlete = (athleteId: number) => {
    setError("")
    setData((prev) => ({ ...prev, athleteId, academy: null, sport: null, group: null, pkg: null }))
    fetchAcademies()
    setStep(1)
  }

  const selectAcademy = (a: Department) => {
    setError("")
    setData((prev) => ({ ...prev, academy: a, sport: null, group: null, pkg: null }))
    fetchSports(a.id)
    setStep(isParent ? 2 : 1)
  }

  const selectSport = (s: Sport) => {
    setError("")
    setData((prev) => ({ ...prev, sport: s, group: null }))
    fetchGroups(s.id)
    setStep(isParent ? 3 : 2)
  }

  const selectGroup = (g: Group) => {
    setError("")
    setData((prev) => ({ ...prev, group: g }))
    fetchPackages()
    setStep(isParent ? 4 : 3)
  }

  const selectPackage = (p: Package) => {
    setError("")
    setData((prev) => ({ ...prev, pkg: p }))
    setStep(isParent ? 5 : 4)
  }

  const submitCheckout = async () => {
    const checkoutAthleteId = isParent ? data.athleteId : (data.athleteId ?? user?.id ?? null)
    if (!checkoutAthleteId) {
      setError("تعذر تحديد الرياضي لهذا الاشتراك")
      return
    }

    if (data.paymentMethod === "bank_transfer" && !pdfFile) {
      setError("يرجى رفع إيصال التحويل بصيغة PDF قبل التأكيد")
      return
    }

    setLoading(true)
    setError("")
    try {
      const formData = new FormData()
      formData.append("sport_id", String(data.sport!.id))
      formData.append("group_id", String(data.group!.id))
      formData.append("package_id", String(data.pkg!.id))
      formData.append("payment_method", data.paymentMethod!)
      formData.append("athlete_id", String(checkoutAthleteId))
      if (pdfFile) {
        formData.append("invoice_pdf", pdfFile)
      }

      const json = await api.post<{
        status: string
        subscription_id: number
        message: string
        account_number?: string
        iban?: string
      }>("/subscriptions/checkout/", formData, { formData: true })

      if (json.account_number) setBankInfo(json)
      setSuccess(true)
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const fetchBankDetails = async (groupId: number) => {
    setBankLoading(true)
    try {
      const res = await api.get<{ account_number: string; iban: string }>(`/subscriptions/bank_details/?group_id=${groupId}`)
      setBankInfo(res)
    } catch {
      setBankInfo(null)
    } finally {
      setBankLoading(false)
    }
  }

  useEffect(() => {
    if (data.paymentMethod === "bank_transfer" && data.group && !success) {
      void fetchBankDetails(data.group.id)
    }
  }, [data.paymentMethod, data.group?.id, success])

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text)
    setCopied(label)
    setTimeout(() => setCopied(""), 2000)
  }

  const totalSteps = isParent ? 6 : 5
  const safeAthletes = Array.isArray(athletes) ? athletes : []
  const safeAcademies = Array.isArray(academies) ? academies : []
  const safeSports = Array.isArray(sports) ? sports : []
  const safeGroups = Array.isArray(groups) ? groups : []
  const safePackages = Array.isArray(packages) ? packages : []

  const retryCurrentStep = () => {
    setError("")

    if (isParent) {
      if (step === 0) return void fetchAthletes()
      if (step === 1) return void fetchAcademies()
      if (step === 2 && data.academy) return void fetchSports(data.academy.id)
      if (step === 3 && data.sport) return void fetchGroups(data.sport.id)
      if (step === 4) return void fetchPackages()
      return
    }

    if (step === 0) return void fetchAcademies()
    if (step === 1 && data.academy) return void fetchSports(data.academy.id)
    if (step === 2 && data.sport) return void fetchGroups(data.sport.id)
    if (step === 3) return void fetchPackages()
  }

  if (success) {
    return (
      <div className="py-10 text-center">
        <CheckCircle className="w-16 h-16 text-primary mx-auto mb-4" />
        <h2 className="text-xl font-bold mb-2">تم إرسال طلب الاشتراك</h2>
        {bankInfo ? (
          <div className="mt-4 space-y-3 rounded-2xl border border-border bg-card p-4 text-right">
            <p className="text-sm font-medium">رقم الحساب:</p>
            <div className="flex items-center justify-between gap-2 rounded-xl bg-surface-container-low p-3">
              <span dir="ltr" className="break-all text-sm font-mono">{bankInfo.account_number}</span>
              <Button variant="ghost" size="icon-xs" onClick={() => copyToClipboard(bankInfo.account_number || "", "account")}>
                <Copy className="w-4 h-4" />
              </Button>
            </div>
            {copied === "account" && <p className="text-xs text-green-600">تم النسخ!</p>}

            <p className="text-sm font-medium">الآيبان (IBAN):</p>
            <div className="flex items-center justify-between gap-2 rounded-xl bg-surface-container-low p-3">
              <span dir="ltr" className="break-all text-sm font-mono">{bankInfo.iban}</span>
              <Button variant="ghost" size="icon-xs" onClick={() => copyToClipboard(bankInfo.iban || "", "iban")}>
                <Copy className="w-4 h-4" />
              </Button>
            </div>
            {copied === "iban" && <p className="text-xs text-green-600">تم النسخ!</p>}

            <p className="text-xs text-muted-foreground mt-2">تم إرسال اشتراكك وهو الآن بحالة انتظار حتى مراجعة الإدارة.</p>
          </div>
        ) : (
          <p className="text-muted-foreground">تم إرسال طلب الاشتراك، يرجى انتظار التأكيد على هاتفك.</p>
        )}
      </div>
    )
  }

  return (
    <div className="overflow-hidden">
      <div className="flex items-center gap-2 mb-6">
        {Array.from({ length: totalSteps }).map((_, idx) => (
          <div key={idx} className={`flex-1 h-1.5 rounded-full ${idx <= step ? "bg-primary" : "bg-border"}`} />
        ))}
      </div>

      <AnimatePresence mode="wait">
        <motion.div key={step} initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
          {/* STEP: SELECT ATHLETE (Parent Only) */}
          {isParent && step === 0 && (
            <div>
              <h2 className="text-lg font-bold mb-4">اختر الرياضي البطل</h2>
              {loading ? <LoadingSpinner /> : (
                <div className="space-y-3">
                  {safeAthletes.length === 0 ? (
                    <p className="text-sm text-muted-foreground text-center">يرجى إضافة لاعب أولاً في صفحة "الرياضيون".</p>
                  ) : (
                    safeAthletes.map((a) => (
                      <button key={a.id} onClick={() => selectAthlete(a.athlete)}
                        className="w-full text-right bg-card border border-border rounded-2xl p-4 hover:border-primary transition-colors flex items-center gap-3"
                      >
                        <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                          <User className="w-5 h-5 text-primary" />
                        </div>
                        <div>
                          <p className="font-semibold">{a.athlete_name}</p>
                          <p className="text-xs text-muted-foreground">{a.athlete_membership}</p>
                        </div>
                        <ChevronLeft className="w-5 h-5 mr-auto text-muted-foreground" />
                      </button>
                    ))
                  )}
                </div>
              )}
            </div>
          )}

          {/* STEP: SELECT ACADEMY */}
          {((isParent && step === 1) || (!isParent && step === 0)) && (
            <div>
              <h2 className="text-lg font-bold mb-4">اختر الأكاديمية</h2>
              {loading ? <LoadingSpinner /> : (
                <div className="space-y-3">
                  {safeAcademies.map((a) => (
                    <button key={a.id} onClick={() => selectAcademy(a)}
                      className="w-full text-right bg-card border border-border rounded-2xl p-4 hover:border-primary transition-colors flex items-center gap-3"
                    >
                      <div className="w-10 h-10 rounded-xl flex items-center justify-center text-white font-bold text-sm" style={{ backgroundColor: a.color }}>
                        {(a.name_ar || a.name || "?").charAt(0)}
                      </div>
                      <div>
                        <p className="font-semibold">{a.name_ar}</p>
                        <p className="text-xs text-muted-foreground">{a.name}</p>
                      </div>
                      <ChevronLeft className="w-5 h-5 mr-auto text-muted-foreground" />
                    </button>
                  ))}
                </div>
              )}
              {isParent && (
                <Button variant="ghost" className="mt-4" onClick={() => { setError(""); setStep(0) }}>
                  <ChevronRight className="w-4 h-4 ml-1" /> السابق
                </Button>
              )}
            </div>
          )}

          {/* STEP: SELECT SPORT */}
          {((isParent && step === 2) || (!isParent && step === 1)) && (
            <div>
              <h2 className="text-lg font-bold mb-4">اختر الرياضة</h2>
              {loading ? <LoadingSpinner /> : (
                <div className="space-y-3">
                  {safeSports.map((s) => (
                    <button key={s.id} onClick={() => selectSport(s)}
                      className="w-full text-right bg-card border border-border rounded-2xl p-4 hover:border-primary transition-colors flex items-center gap-3"
                    >
                      <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary font-bold">
                        {(s.name_ar || s.name || "?").charAt(0)}
                      </div>
                      <div>
                        <p className="font-semibold">{s.name_ar}</p>
                      </div>
                      <ChevronLeft className="w-5 h-5 mr-auto text-muted-foreground" />
                    </button>
                  ))}
                </div>
              )}
              <Button variant="ghost" className="mt-4" onClick={() => { setError(""); setStep(isParent ? 1 : 0) }}>
                <ChevronRight className="w-4 h-4 ml-1" /> السابق
              </Button>
            </div>
          )}

          {/* STEP: SELECT GROUP */}
          {((isParent && step === 3) || (!isParent && step === 2)) && (
            <div>
              <h2 className="text-lg font-bold mb-4">اختر المجموعة</h2>
              {loading ? <LoadingSpinner /> : (
                <div className="space-y-3">
                  {safeGroups.map((g) => (
                    <button key={g.id} onClick={() => selectGroup(g)}
                      className="w-full text-right bg-card border border-border rounded-2xl p-4 hover:border-primary transition-colors"
                    >
                      <p className="font-semibold">{g.name_ar}</p>
                      <p className="text-xs text-muted-foreground">المدرب: {g.coach_name}</p>
                      <div className="flex flex-wrap gap-1 mt-2">
                        {(Array.isArray(g.days) ? g.days : []).map((d) => (
                          <span key={d} className="px-2 py-0.5 bg-primary/10 text-primary rounded-full text-xs">
                            {WEEKDAY_MAP[String(d).toLowerCase()] || d}
                          </span>
                        ))}
                      </div>
                      <p className="text-xs text-muted-foreground mt-1">{g.start_time} - {g.end_time}</p>
                    </button>
                  ))}
                </div>
              )}
              <Button variant="ghost" className="mt-4" onClick={() => { setError(""); setStep(isParent ? 2 : 1) }}>
                <ChevronRight className="w-4 h-4 ml-1" /> السابق
              </Button>
            </div>
          )}

          {/* STEP: SELECT PACKAGE */}
          {((isParent && step === 4) || (!isParent && step === 3)) && (
            <div>
              <h2 className="text-lg font-bold mb-4">اختر الباقة</h2>
              {loading ? <LoadingSpinner /> : (
                <div className="space-y-3">
                  {safePackages.map((p) => {
                    const tagColors: Record<string, string> = { discount: "border-green-500 bg-green-50", special: "border-amber-500 bg-amber-50", normal: "border-border" }
                    const tagLabels: Record<string, string> = { discount: "خصم", special: "خاص", normal: "" }
                    return (
                      <button key={p.id} onClick={() => selectPackage(p)}
                        className={`w-full text-right bg-card border-2 rounded-2xl p-4 hover:border-primary transition-colors ${tagColors[p.tag] || "border-border"}`}
                      >
                        <div className="flex items-center justify-between mb-2">
                          <p className="font-bold text-lg">{p.name}</p>
                          {tagLabels[p.tag] && <span className="px-2 py-0.5 bg-primary text-white text-xs rounded-full">{tagLabels[p.tag]}</span>}
                        </div>
                        <p className="text-2xl font-bold text-primary mb-2">{latinNumber(p.price)} د.ل</p>
                        <p className="text-xs text-muted-foreground">{latinNumber(p.duration_value)} {p.duration_type === "months" ? "شهر" : "أسبوع"}</p>
                        <p className="text-xs text-muted-foreground">الحد الأقصى للرياضيين: {latinNumber(p.max_athletes)}</p>
                      </button>
                    )
                  })}
                </div>
              )}
              <Button variant="ghost" className="mt-4" onClick={() => { setError(""); setStep(isParent ? 3 : 2) }}>
                <ChevronRight className="w-4 h-4 ml-1" /> السابق
              </Button>
            </div>
          )}

          {/* STEP: PAYMENT METHOD */}
          {((isParent && step === 5) || (!isParent && step === 4)) && (
            <div>
              <h2 className="text-lg font-bold mb-4">طريقة الدفع</h2>
              <div className="space-y-3">
                <button onClick={() => { setError(""); setData((prev) => ({ ...prev, paymentMethod: "cash" })) }}
                  className={`w-full text-right bg-card border-2 rounded-2xl p-4 flex items-center gap-3 transition-colors ${data.paymentMethod === "cash" ? "border-primary" : "border-border"}`}
                >
                  <CreditCard className="w-6 h-6 text-primary" />
                  <div>
                    <p className="font-semibold">نقداً</p>
                    <p className="text-xs text-muted-foreground">الدفع في مقر النادي</p>
                  </div>
                </button>
                <button onClick={() => { setError(""); setData((prev) => ({ ...prev, paymentMethod: "bank_transfer" })) }}
                  className={`w-full text-right bg-card border-2 rounded-2xl p-4 flex items-center gap-3 transition-colors ${data.paymentMethod === "bank_transfer" ? "border-primary" : "border-border"}`}
                >
                  <Building className="w-6 h-6 text-primary" />
                  <div>
                    <p className="font-semibold">تحويل بنكي</p>
                    <p className="text-xs text-muted-foreground">إرفاق إيصال PDF</p>
                  </div>
                </button>
              </div>

              {data.paymentMethod === "bank_transfer" && (
                <div className="mt-4 space-y-4">
                  {bankLoading ? (
                    <div className="rounded-2xl border border-border bg-card p-4 text-center text-sm text-muted-foreground">جاري تحميل بيانات الحساب...</div>
                  ) : bankInfo ? (
                    <div className="rounded-2xl border border-border bg-card p-4 text-right space-y-3">
                      <p className="text-sm font-medium">حساب الأكاديمية المصرفي:</p>
                      <div className="flex items-center justify-between gap-2 rounded-xl bg-surface-container-low p-3">
                        <span dir="ltr" className="break-all text-sm font-mono">{bankInfo.account_number}</span>
                        <Button variant="ghost" size="icon-xs" onClick={() => copyToClipboard(bankInfo.account_number || "", "account")}>
                          <Copy className="w-4 h-4" />
                        </Button>
                      </div>
                      {copied === "account" && <p className="text-xs text-green-600">تم النسخ!</p>}
                      <p className="text-sm font-medium">الآيبان (IBAN):</p>
                      <div className="flex items-center justify-between gap-2 rounded-xl bg-surface-container-low p-3">
                        <span dir="ltr" className="break-all text-sm font-mono">{bankInfo.iban}</span>
                        <Button variant="ghost" size="icon-xs" onClick={() => copyToClipboard(bankInfo.iban || "", "iban")}>
                          <Copy className="w-4 h-4" />
                        </Button>
                      </div>
                      {copied === "iban" && <p className="text-xs text-green-600">تم النسخ!</p>}
                    </div>
                  ) : null}
                <div className="bg-card border border-border rounded-2xl p-4">
                  <label className="block text-sm font-medium mb-2">إرفاق إيصال التحويل (PDF فقط)</label>
                  <div className="border-2 border-dashed border-border rounded-xl p-6 text-center cursor-pointer hover:border-primary transition-colors"
                    onClick={() => document.getElementById("pdf-upload")?.click()}
                  >
                    <Upload className="w-8 h-8 mx-auto mb-2 text-muted-foreground" />
                    <p className="text-sm text-muted-foreground">{pdfFile ? pdfFile.name : "اضغط لرفع ملف PDF"}</p>
                    <input
                      id="pdf-upload"
                      type="file"
                      accept="application/pdf,.pdf"
                      className="hidden"
                      onChange={(e) => {
                        const file = e.target.files?.[0] || null
                        if (!file) {
                          setPdfFile(null)
                          return
                        }
                        if (file.type !== "application/pdf" && !file.name.toLowerCase().endsWith(".pdf")) {
                          setError("الملف يجب أن يكون بصيغة PDF فقط")
                          setPdfFile(null)
                          return
                        }
                        setError("")
                        setPdfFile(file)
                      }}
                    />
                  </div>
                </div>
                </div>
              )}

              {error && <p className="text-destructive text-sm mt-2">{error}</p>}

              <div className="mt-6 flex flex-col gap-3 sm:flex-row">
                <Button variant="ghost" onClick={() => { setError(""); setStep(isParent ? 4 : 3) }}>
                  <ChevronRight className="w-4 h-4 ml-1" /> السابق
                </Button>
                <Button className="flex-1" disabled={!data.paymentMethod || loading} onClick={submitCheckout}>
                  {loading ? "جاري..." : "تأكيد الاشتراك"}
                </Button>
              </div>
            </div>
          )}
        </motion.div>
      </AnimatePresence>

      {!!error && step !== (isParent ? 5 : 4) && (
        <div className="mt-4 rounded-xl border border-destructive/25 bg-destructive/5 p-3">
          <p className="text-sm text-destructive">{error}</p>
          <Button className="mt-2" onClick={retryCurrentStep} size="sm" variant="outline">
            إعادة المحاولة
          </Button>
        </div>
      )}
    </div>
  )
}
