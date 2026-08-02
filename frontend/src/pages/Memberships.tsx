import React, { useEffect, useState, type FormEvent } from "react"
import { useQueryClient } from "@tanstack/react-query"
import { motion, type Variants } from "framer-motion"
import {
  CalendarDays,
  CalendarRange,
  Crown,
  CheckCircle2,
  Eye,
  FileText,
  Search,
  Filter,
  MoreVertical,
  PlusCircle,
  RefreshCw,
  X,
  ChevronLeft,
  ChevronRight,
} from "lucide-react"
import { useRenewSubscription, useSubscriptions, useUpdateSubscription } from "@/lib/hooks/useSubscriptions"
import { usePackages } from "@/lib/hooks/usePackages"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Link, useSearchParams } from "react-router-dom"
import { api } from "@/lib/api"
import { toAbsoluteMediaUrl } from "@/lib/media"
import { Can } from "@/components/ui/can"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.12 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.45, ease: [0.22, 1, 0.36, 1] } },
}

const cardVariants: Variants = {
  hidden: { opacity: 0, y: 30, scale: 0.95 },
  visible: (i: number) => ({
    opacity: 1,
    y: 0,
    scale: 1,
    transition: { duration: 0.5, delay: i * 0.08, ease: [0.22, 1, 0.36, 1] },
  }),
}

const statusMap: Record<string, { label: string; cls: string; dot: string }> = {
  active: { label: "نشط", cls: "bg-secondary/10 text-secondary border border-secondary/10", dot: "bg-secondary" },
  expired: { label: "منتهي", cls: "bg-error/10 text-error border border-error/10", dot: "bg-error" },
  pending: { label: "قيد الانتظار", cls: "bg-amber-500/10 text-amber-600 border border-amber-500/10", dot: "bg-amber-500" },
  rejected: { label: "مرفوض", cls: "bg-error/10 text-error border border-error/10", dot: "bg-error" },
}

type FlashMessage = {
  type: "success" | "error" | "info"
  text: string
}

type QuickRenewPackage = {
  id: number
  title: string
  amount: number
  durationType: "days" | "weeks" | "months"
  durationValue: number
}

export default function MembershipsPage() {
  const queryClient = useQueryClient()
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("")
  const [page, setPage] = useState(1)
  const [flash, setFlash] = useState<FlashMessage | null>(null)
  const [detailsSub, setDetailsSub] = useState<any | null>(null)
  const [rejectTarget, setRejectTarget] = useState<{ id: number; name: string } | null>(null)
  const [rejectReason, setRejectReason] = useState("")
  const [showCreateSubModal, setShowCreateSubModal] = useState(false)
  const [createSubLoading, setCreateSubLoading] = useState(false)
  const [createSubError, setCreateSubError] = useState<string | null>(null)
  const [athleteOptions, setAthleteOptions] = useState<Array<{ id: number; full_name: string; membership_number: string }>>([])
  const [manualSubForm, setManualSubForm] = useState({
    athlete: "",
    start_date: "",
    end_date: "",
    amount: "",
    package_name: "",
    package_id: "",
    payment_method: "cash" as "cash" | "bank_transfer",
    status: "active" as "active" | "pending",
  })
  const [manualInvoice, setManualInvoice] = useState<File | null>(null)
  const [quickRenewPackage, setQuickRenewPackage] = useState<QuickRenewPackage | null>(null)
  const [quickRenewAthlete, setQuickRenewAthlete] = useState("")
  const [quickRenewSubId, setQuickRenewSubId] = useState("")
  const [quickRenewSubs, setQuickRenewSubs] = useState<any[]>([])
  const [quickRenewLoadingSubs, setQuickRenewLoadingSubs] = useState(false)
  const [quickRenewError, setQuickRenewError] = useState<string | null>(null)
  const [quickRenewPreset, setQuickRenewPreset] = useState<{ athlete: string; sub: string } | null>(null)
  const [quickRenewPaymentMethod, setQuickRenewPaymentMethod] = useState<"cash" | "bank_transfer">("cash")
  const [quickRenewInvoice, setQuickRenewInvoice] = useState<File | null>(null)
  const [departments, setDepartments] = useState<Array<{ id: number; name_ar: string }>>([])

  useEffect(() => {
    if (!flash) return
    const timer = window.setTimeout(() => setFlash(null), 3200)
    return () => window.clearTimeout(timer)
  }, [flash])

  useEffect(() => {
    api.get<{ results: Array<{ id: number; name_ar: string }> } | Array<{ id: number; name_ar: string }>>("/departments/")
      .then((res) => {
        const items = (res as any).results || res
        setDepartments(Array.isArray(items) ? items : [])
      })
      .catch((err) => console.warn("Failed to load departments:", err))
  }, [])

  const [searchParams] = useSearchParams()
  const deptParam = searchParams.get("department")
  const sportParam = searchParams.get("sport")
  const renewMode = searchParams.get("renew") === "1"

  useEffect(() => {
    if (renewMode) setStatusFilter("")
  }, [renewMode])

  useEffect(() => {
    const athleteId = searchParams.get("athlete_id")
    if (!athleteId || isNaN(Number(athleteId))) return
    const init = async () => {
      setCreateSubError(null)
      await loadAthletes()
      const today = new Date()
      const nextMonth = new Date(today)
      nextMonth.setMonth(nextMonth.getMonth() + 1)
      setManualSubForm({
        athlete: athleteId,
        start_date: today.toISOString().slice(0, 10),
        end_date: nextMonth.toISOString().slice(0, 10),
        amount: "",
        package_name: "",
        package_id: "",
        payment_method: "cash",
        status: "active",
      })
      setManualInvoice(null)
      setShowCreateSubModal(true)
    }
    init()
  }, [searchParams])

  const { data, isLoading } = useSubscriptions({
    page,
    page_size: 20,
    search: search || undefined,
    status: statusFilter || undefined,
    athlete__department: deptParam || undefined,
    athlete__sport: sportParam || undefined,
  })

  const { data: packagesData } = usePackages(deptParam ?? undefined)
  const packages = packagesData?.results ?? []

  useEffect(() => {
    const athleteId = manualSubForm.athlete
    const pkgId = manualSubForm.package_id
    if (!athleteId || !pkgId) return

    const pkg = packages.find((p) => p.id === Number(pkgId))
    if (!pkg) return

    const updateAmount = async () => {
      try {
        const res = await api.get<{ count: number }>(`/subscriptions/?athlete=${athleteId}`)
        const raw = res as any
        const hasPrev = raw && (Array.isArray(raw) ? raw.length > 0 : raw.count > 0)
        
        const newPrice = pkg.new_price || pkg.price
        const renewalPrice = pkg.renewal_price || pkg.price
        const finalPrice = hasPrev && Number(renewalPrice) > 0 ? renewalPrice : newPrice
        
        setManualSubForm((prev) => ({
          ...prev,
          amount: finalPrice,
        }))
      } catch {
        setManualSubForm((prev) => ({
          ...prev,
          amount: pkg.new_price || pkg.price,
        }))
      }
    }

    void updateAmount()
  }, [manualSubForm.athlete, manualSubForm.package_id, packages])

  const updateSubscriptionMut = useUpdateSubscription()
  const renewSubscriptionMut = useRenewSubscription()

  const normalizeRenewMonths = (durationType: "days" | "weeks" | "months", durationValue: number) => {
    const estimated =
      durationType === "days"
        ? Math.max(1, Math.ceil(durationValue / 30))
        : durationType === "weeks"
          ? Math.max(1, Math.ceil(durationValue / 4))
          : Math.max(1, durationValue)
    const allowed = [1, 3, 6, 12]
    const match = allowed.find((m) => m >= estimated)
    return match ?? 12
  }

  const openQuickRenew = async (pkg: QuickRenewPackage) => {
    setQuickRenewPackage(pkg)
    setQuickRenewAthlete("")
    setQuickRenewSubId("")
    setQuickRenewSubs([])
    setQuickRenewPreset(null)
    setQuickRenewError(null)
    setQuickRenewPaymentMethod("cash")
    setQuickRenewInvoice(null)
    await loadAthletes()
  }

  const openQuickRenewFromRow = async (sub: any) => {
    setQuickRenewPackage(null)
    setQuickRenewPreset({ athlete: String(sub.athlete), sub: String(sub.id) })
    setQuickRenewAthlete(String(sub.athlete))
    setQuickRenewSubId(String(sub.id))
    setQuickRenewSubs([sub])
    setQuickRenewError(null)
    setQuickRenewPaymentMethod("cash")
    setQuickRenewInvoice(null)
    await loadAthletes()
  }

  const closeQuickRenew = () => {
    if (renewSubscriptionMut.isPending) return
    setQuickRenewPackage(null)
    setQuickRenewAthlete("")
    setQuickRenewSubId("")
    setQuickRenewSubs([])
    setQuickRenewPreset(null)
    setQuickRenewError(null)
    setQuickRenewPaymentMethod("cash")
    setQuickRenewInvoice(null)
  }

  const loadAthleteSubscriptions = async (athleteId: string) => {
    if (!athleteId) {
      setQuickRenewSubs([])
      setQuickRenewSubId("")
      return
    }

    try {
      setQuickRenewLoadingSubs(true)
      setQuickRenewError(null)
      const subsRes = await api.get<{ results: any[] } | any[]>("/subscriptions/", {
        athlete: athleteId,
        page_size: "100",
      })
      const items = (subsRes as any).results || subsRes
      const subs = Array.isArray(items) ? items : []
      setQuickRenewSubs(subs)

      const preferred = subs.find((s: any) => s.status === "active") || subs[0]
      setQuickRenewSubId(preferred ? String(preferred.id) : "")

      if (!preferred) {
        setQuickRenewError("لا توجد اشتراكات سابقة لهذا الرياضي لتجديدها")
      }
    } catch (err: any) {
      setQuickRenewSubs([])
      setQuickRenewSubId("")
      setQuickRenewError(err?.message || "تعذر تحميل اشتراكات الرياضي")
    } finally {
      setQuickRenewLoadingSubs(false)
    }
  }

  const submitQuickRenew = async (e: FormEvent) => {
    e.preventDefault()
    if (!quickRenewPackage && !quickRenewPreset) return
    if (!quickRenewAthlete) {
      setQuickRenewError("يرجى اختيار الرياضي")
      return
    }
    if (!quickRenewSubId) {
      setQuickRenewError("يرجى اختيار الاشتراك المراد تجديده")
      return
    }

    try {
      setQuickRenewError(null)
      const presetSub = quickRenewSubs.find((s) => String(s.id) === quickRenewSubId)
      const presetPkg = quickRenewPreset
        ? packages.find((p) => p.name === presetSub?.package_name)
        : undefined
      const amount =
        quickRenewPackage?.amount ??
        Number(presetPkg?.renewal_price || presetPkg?.price || presetSub?.amount || 0)
      const months = quickRenewPackage
        ? normalizeRenewMonths(quickRenewPackage.durationType, quickRenewPackage.durationValue)
        : presetPkg
          ? normalizeRenewMonths(presetPkg.duration_type, presetPkg.duration_value)
          : 1

      await renewSubscriptionMut.mutateAsync({
        id: Number(quickRenewSubId),
        months,
        amount: amount.toString(),
        payment_method: quickRenewPaymentMethod,
        invoice_pdf: quickRenewInvoice,
      })

      await queryClient.invalidateQueries({ queryKey: ["subscriptions"] })
      setFlash({ type: "success", text: `تم تجديد الاشتراك بنجاح لمدة ${months} شهر` })
      closeQuickRenew()
    } catch (err: any) {
      setQuickRenewError(err?.message || "تعذر تنفيذ التجديد السريع")
    }
  }

  const loadAthletes = async () => {
    try {
      const athletesRes = await api.get<{ results: Array<{ id: number; full_name: string; membership_number: string }> } | Array<{ id: number; full_name: string; membership_number: string }>>("/athletes/", {
        page_size: "300",
        ordering: "-created_at",
        ...(deptParam ? { department: deptParam } : {}),
      })
      const items = (athletesRes as any).results || athletesRes
      setAthleteOptions(Array.isArray(items) ? items : [])
    } catch {
      setAthleteOptions([])
    }
  }

  const openCreateSubscriptionModal = async () => {
    setCreateSubError(null)
    const today = new Date()
    const nextMonth = new Date(today)
    nextMonth.setMonth(nextMonth.getMonth() + 1)
    setManualSubForm({
      athlete: "",
      start_date: today.toISOString().slice(0, 10),
      end_date: nextMonth.toISOString().slice(0, 10),
      amount: "",
      package_name: "",
      package_id: "",
      payment_method: "cash",
      status: "active",
    })
    setManualInvoice(null)
    setShowCreateSubModal(true)

    await loadAthletes()
  }

  const submitManualSubscription = async (e: FormEvent) => {
    e.preventDefault()
    setCreateSubError(null)

    if (!manualSubForm.athlete || !manualSubForm.start_date || !manualSubForm.end_date || !manualSubForm.amount) {
      setCreateSubError("يرجى استكمال بيانات الاشتراك")
      return
    }



    try {
      setCreateSubLoading(true)
      const payload = new FormData()
      payload.append("athlete", manualSubForm.athlete)
      payload.append("start_date", manualSubForm.start_date)
      payload.append("end_date", manualSubForm.end_date)
      payload.append("amount", manualSubForm.amount)
      payload.append("package_name", manualSubForm.package_name)
      payload.append("payment_method", manualSubForm.payment_method)
      payload.append("status", manualSubForm.status)
      if (manualSubForm.package_id) payload.append("package_id", String(manualSubForm.package_id))
      if (manualInvoice) payload.append("invoice_pdf", manualInvoice)

      await api.post("/subscriptions/", payload, { formData: true })
      await queryClient.invalidateQueries({ queryKey: ["subscriptions"] })
      setShowCreateSubModal(false)
      setFlash({ type: "success", text: "تم إنشاء الاشتراك يدوياً بنجاح" })
    } catch (err: any) {
      setCreateSubError(err?.message || "تعذر إنشاء الاشتراك")
    } finally {
      setCreateSubLoading(false)
    }
  }

  const handleApprove = async (id: number) => {
    try {
      await updateSubscriptionMut.mutateAsync({ id, status: "active" })
      setFlash({ type: "success", text: "تم تفعيل الاشتراك بنجاح." })
    } catch (err: any) {
      setFlash({ type: "error", text: err?.message || "فشل تفعيل الاشتراك." })
    }
  }

  const handleReject = async (id: number, reason: string) => {
    try {
      await updateSubscriptionMut.mutateAsync({ id, status: "rejected", rejection_reason: reason || undefined })
      setFlash({ type: "success", text: "تم رفض الاشتراك." })
    } catch (err: any) {
      setFlash({ type: "error", text: err?.message || "فشل رفض الاشتراك." })
    }
  }

  const subscriptions = data?.results || []
  const totalPages = data ? Math.ceil(data.count / 20) : 0

  const formatDate = (d: string) =>
    new Date(d).toLocaleDateString("ar-SA-u-nu-latn", { year: "numeric", month: "numeric", day: "numeric" })

  const iconMap: Record<string, React.ElementType> = {
    CalendarDays, CalendarRange, Crown,
  }

  const pkgList = (packages || []).map((pkg) => {
    const Icon = iconMap[pkg.icon_name || "CalendarDays"] || CalendarDays
    const newPriceNum = Number(pkg.new_price || pkg.price)
    const renewalPriceNum = Number(pkg.renewal_price || pkg.price)
    const durationDays =
      pkg.duration_type === "days"
        ? pkg.duration_value
        : pkg.duration_type === "weeks"
          ? pkg.duration_value * 7
          : pkg.duration_value * 30
    const isFeatured = pkg.color_class?.includes("featured") || pkg.id === 2
    
    let typeLabel = "شهري"
    if (pkg.package_type === "multi_month") typeLabel = "متعدد الأشهر"
    else if (pkg.package_type === "single_session") typeLabel = "حصة واحدة"

    return {
      id: pkg.id,
      title: pkg.name,
      newPrice: newPriceNum.toLocaleString("ar-SA-u-nu-latn"),
      renewalPrice: renewalPriceNum.toLocaleString("ar-SA-u-nu-latn"),
      typeLabel,
      icon: Icon,
      badge: isFeatured ? "الأكثر طلباً" : "شائع",
      badgeCls: isFeatured
        ? "bg-primary/10 text-primary border border-primary/10"
        : "bg-secondary/10 text-secondary border border-secondary/10",
      features: pkg.features?.length ? pkg.features : ["دخول يومي للمرافق"],
      featured: isFeatured,
      raw: pkg,
    }
  })

  const getPageNumbers = () => {
    const pages: (number | string)[] = []
    const delta = 1
    const left = Math.max(2, page - delta)
    const right = Math.min(totalPages - 1, page + delta)
    pages.push(1)
    if (left > 2) pages.push("...")
    for (let i = left; i <= right; i++) pages.push(i)
    if (right < totalPages - 1) pages.push("...")
    if (totalPages > 1) pages.push(totalPages)
    return pages
  }

  const renewRows = (renewMode ? [...subscriptions] : []).sort(
    (a: any, b: any) => new Date(a.end_date).getTime() - new Date(b.end_date).getTime(),
  )

  const quickRenewPresetSub = quickRenewPreset ? quickRenewSubs.find((s) => String(s.id) === quickRenewSubId) ?? quickRenewSubs[0] : undefined
  const quickRenewPresetPkg = quickRenewPresetSub ? packages.find((p) => p.name === quickRenewPresetSub.package_name) : undefined
  const quickRenewAmount =
    quickRenewPackage?.amount ??
    Number(quickRenewPresetPkg?.renewal_price || quickRenewPresetPkg?.price || quickRenewPresetSub?.amount || 0)
  const quickRenewMonths = quickRenewPackage
    ? normalizeRenewMonths(quickRenewPackage.durationType, quickRenewPackage.durationValue)
    : quickRenewPresetPkg
      ? normalizeRenewMonths(quickRenewPresetPkg.duration_type, quickRenewPresetPkg.duration_value)
      : 1
  const quickRenewAthleteName =
    quickRenewAthlete && !quickRenewPreset
      ? athleteOptions.find((a) => a.id === Number(quickRenewAthlete))?.full_name || ""
      : ""

  return (
    <motion.div className="space-y-8 overflow-hidden" dir="rtl" variants={containerVariants} initial="hidden" animate="visible">
      {flash && (
        <div className="fixed z-[70] top-4 right-4 left-4 md:left-auto md:max-w-sm">
          <div
            className={`rounded-xl border px-4 py-3 text-sm shadow-lg backdrop-blur ${
              flash.type === "success"
                ? "bg-secondary/15 text-secondary border-secondary/30"
                : flash.type === "error"
                  ? "bg-error/15 text-error border-error/30"
                  : "bg-primary/15 text-primary border-primary/30"
            }`}
          >
            {flash.text}
          </div>
        </div>
      )}

      {/* ── Ambient Background ── */}
      <div className="fixed top-[-20%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-primary-container/10 blur-[120px] -z-10 pointer-events-none" />
      <div className="fixed bottom-[-15%] left-[-10%] w-[40vw] h-[40vw] rounded-full bg-secondary/5 blur-[100px] -z-10 pointer-events-none" />

      <motion.div variants={itemVariants} className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold gradient-text">إدارة الاشتراكات</h1>
          <p className="text-muted-foreground mt-1 text-sm">تجديد، متابعة، وإدارة الباقات المالية للرياضيين.</p>
        </div>
        <div className="flex items-center gap-3 w-full md:w-auto">
          {renewMode && (
            <div className="rounded-2xl border border-primary/25 bg-primary/5 px-4 py-3 text-sm font-bold text-primary">
              وضع التجديد — اختر اشتراكاً ثم اضغط "تجديد" لتمديد المدة. الباقات المعتمدة للتجديد أدناه.
            </div>
          )}
          <Can action="packages:create">
            <Link
              to={`/dashboard/plans${deptParam ? `?department=${deptParam}` : ""}`}
              className="inline-flex items-center justify-center gap-2 rounded-xl border border-primary text-primary hover:bg-primary/5 px-4 py-2.5 text-sm font-bold"
            >
              <PlusCircle className="w-5 h-5" />
              إدارة الباقات
            </Link>
          </Can>
          <Can action="subscriptions:create">
            <Button
              size="lg"
              className="w-full md:w-auto bg-primary text-primary-foreground hover:bg-primary/90 shadow-lg shadow-primary/20 hover:shadow-xl hover:shadow-primary/25 rounded-xl font-bold"
              onClick={() => void openCreateSubscriptionModal()}
            >
              <PlusCircle className="w-5 h-5" />
              اشتراك جديد
            </Button>
          </Can>
        </div>
      </motion.div>

      {/* ── Quick Renewal Packages ── */}
      <section>
        <motion.div variants={itemVariants} className="section-header mb-6">
          الباقات الحالية
        </motion.div>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
          {pkgList.map((pkg, index) => {
            const Icon = pkg.icon
            return (
              <motion.div
                key={pkg.id}
                custom={index}
                variants={cardVariants}
                initial="hidden"
                whileInView="visible"
                viewport={{ once: true, margin: "-50px" }}
                whileHover={{ y: -4, transition: { duration: 0.2, ease: "easeOut" } }}
                className={`relative rounded-2xl overflow-hidden transition-all duration-300 border flex flex-col justify-between h-[280px] p-5 ${
                  pkg.featured
                    ? "glass-card shadow-md shadow-primary/10 border-primary/40 bg-gradient-to-br from-primary/[0.03] to-transparent"
                    : "glass-card border-border/40"
                }`}
              >
                {pkg.featured && (
                  <div className="absolute -right-10 -top-10 w-24 h-24 bg-primary-container/10 rounded-full blur-xl pointer-events-none" />
                )}

                <div className="flex flex-col h-full justify-between">
                  <div>
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <div className={`p-1.5 rounded-lg shrink-0 ${pkg.featured ? "bg-primary/10 text-primary" : "bg-surface-container-high text-primary"}`}>
                          <Icon className="w-4 h-4" />
                        </div>
                        <h4 className={`text-base font-bold truncate ${pkg.featured ? "text-primary" : "text-foreground"}`}>
                          {pkg.title}
                        </h4>
                      </div>
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full shrink-0 ${pkg.badgeCls}`}>
                        {pkg.badge}
                      </span>
                    </div>

                    <div className="flex items-center gap-2 text-xs text-muted-foreground mt-1.5">
                      <span>{pkg.raw.duration_value} {pkg.raw.duration_type === "days" ? (pkg.raw.duration_value === 1 ? "يوم" : "أيام") : pkg.raw.duration_type === "weeks" ? (pkg.raw.duration_value === 1 ? "أسبوع" : "أسابيع") : pkg.raw.duration_value === 1 ? "شهر" : "أشهر"}</span>
                      <span>•</span>
                      <span>{pkg.raw.max_athletes} رياضي</span>
                    </div>

                    <div className="grid grid-cols-2 gap-2 my-2 py-1.5 border-y border-border/10">
                      <div>
                        <span className="text-[10px] text-muted-foreground block">اشتراك جديد</span>
                        <span className="text-base font-extrabold text-foreground">{pkg.newPrice} <span className="text-[10px] font-normal">د.ل</span></span>
                      </div>
                      <div>
                        <span className="text-[10px] text-muted-foreground block">سعر التجديد</span>
                        <span className="text-base font-extrabold text-foreground">{pkg.renewalPrice} <span className="text-[10px] font-normal">د.ل</span></span>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-2 mt-auto">
                    <Can action="subscriptions:renew">
                      <button
                        onClick={() => openQuickRenew({
                          id: pkg.id,
                          title: pkg.title,
                          amount: Number(pkg.raw.renewal_price || pkg.raw.price || 0),
                          durationType: pkg.raw.duration_type,
                          durationValue: pkg.raw.duration_value,
                        })}
                        className={`w-full py-1.5 rounded-lg text-xs font-bold transition-all active:scale-[0.97] ${
                          pkg.featured
                            ? "bg-primary text-primary-foreground shadow-sm shadow-primary/20 hover:bg-primary/95"
                            : "bg-surface-container-highest text-primary border border-primary/10 hover:bg-primary hover:text-primary-foreground"
                        }`}
                      >
                        تجديد سريع
                      </button>
                    </Can>
                  </div>
                </div>
              </motion.div>
            )
          })}

          <Can action="packages:create">
            <Link
              to={`/dashboard/plans${deptParam ? `?department=${deptParam}` : ""}`}
              className="rounded-2xl border-2 border-dashed border-primary/30 bg-primary/5 hover:bg-primary/10 transition-all duration-300 h-[280px] flex flex-col items-center justify-center gap-2 p-5"
            >
              <div className="w-10 h-10 rounded-full bg-primary/10 text-primary flex items-center justify-center">
                <PlusCircle className="w-5 h-5" />
              </div>
              <p className="font-bold text-sm text-primary">إدارة الباقات</p>
              <p className="text-[11px] text-muted-foreground text-center">إنشاء وتعديل الباقات والأسعار من صفحة الباقات</p>
            </Link>
          </Can>
        </div>
      </section>

      {/* ── Subscriptions Table ── */}
      <section>
        <motion.div variants={itemVariants} className="section-header mb-6">
          سجل الاشتراكات
        </motion.div>

        <motion.div variants={itemVariants} className="glass-card rounded-3xl p-4 mb-6">
          <div className="flex flex-col lg:flex-row gap-3">
            <div className="flex-1">
              <Input
                type="text"
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(1) }}
                icon={<Search className="w-4 h-4 text-muted-foreground" />}
                placeholder="بحث باسم الرياضي أو رقم الهوية..."
              />
            </div>
            <div className="relative w-full lg:w-auto">
              <Filter className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 pointer-events-none" />
              <select
                value={statusFilter}
                onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
                className="bg-surface-container-low border border-outline-variant/30 text-foreground text-sm rounded-xl focus:ring-2 focus:ring-primary focus:border-primary block w-full pr-10 p-2.5 outline-none transition-all appearance-none cursor-pointer"
              >
                <option value="">جميع الحالات</option>
                <option value="active">نشط</option>
                <option value="expired">منتهي</option>
                <option value="pending">قيد الانتظار</option>
              </select>
            </div>
          </div>
        </motion.div>

        <motion.div variants={itemVariants} className="glass-card rounded-2xl overflow-x-auto">
          <div>
            <table className="w-full min-w-[680px] text-right text-sm">
              <thead>
                <tr className="bg-surface-container-high/50 border-b border-outline-variant/30 text-muted-foreground text-xs font-bold">
                  <th scope="col" className="px-6 py-4">اسم الرياضي</th>
                  <th scope="col" className="px-6 py-4">تاريخ البدء</th>
                  <th scope="col" className="px-6 py-4">تاريخ الانتهاء</th>
                  <th scope="col" className="px-6 py-4">المبلغ</th>
                  <th scope="col" className="px-6 py-4">الحالة</th>
                  <th scope="col" className="px-6 py-4 text-center">إجراءات</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-16 text-center text-muted-foreground">
                      <div className="flex flex-col items-center gap-3">
                        <div className="w-8 h-8 border-[3px] border-primary border-t-transparent rounded-full animate-spin" />
                        <span className="text-sm">جاري التحميل...</span>
                      </div>
                    </td>
                  </tr>
                ) : subscriptions.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-16 text-center text-muted-foreground">
                      <div className="flex flex-col items-center gap-2">
                        <Search className="w-6 h-6 text-muted-foreground/40" />
                        <span className="text-sm">لا توجد نتائج</span>
                      </div>
                    </td>
                  </tr>
                ) : (
                  subscriptions.map((sub) => (
                    <motion.tr
                      key={sub.id}
                      variants={itemVariants}
                      onClick={() => setDetailsSub(sub)}
                      className="bg-transparent border-b border-outline-variant/20 hover:bg-surface-container-lowest/50 transition-colors group cursor-pointer"
                    >
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-surface-variant flex items-center justify-center text-primary font-bold text-xs shrink-0">
                            {sub.athlete_name.charAt(0)}
                          </div>
                          <span className="font-semibold text-foreground">{sub.athlete_name}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-muted-foreground text-xs">{formatDate(sub.start_date)}</td>
                      <td className={`px-6 py-4 text-xs font-semibold ${
                        sub.status === "expired" ? "text-error" : sub.status === "pending" ? "text-amber-600" : "text-muted-foreground"
                      }`}>
                        {formatDate(sub.end_date)}
                      </td>
                      <td className="px-6 py-4 font-bold text-foreground">
                        {Number(sub.amount).toLocaleString("ar-SA-u-nu-latn")}
                        <span className="text-xs text-muted-foreground mr-0.5 font-normal"> د.ل</span>
                      </td>
                      <td className="px-6 py-4">
                        <Badge
                          variant={sub.status === "active" ? "success" : (sub.status === "expired" || sub.status === "rejected") ? "error" : "warning"}
                          dot
                        >
                          {statusMap[sub.status]?.label || sub.status}
                        </Badge>
                      </td>
                      <td className="px-6 py-4 text-center">
                        {sub.status === "pending" ? (
                          <div className="flex items-center justify-center gap-1.5">
                            <Can action="subscriptions:update">
                              <Button
                                size="sm"
                                variant="ghost"
                                className="text-secondary hover:text-secondary hover:bg-secondary/10 px-2.5 py-1 h-7 text-xs font-bold rounded-lg flex items-center gap-1"
                                onClick={(e) => { e.stopPropagation(); void handleApprove(sub.id) }}
                              >
                                <CheckCircle2 className="w-3.5 h-3.5" />
                                تأكيد
                              </Button>
                            </Can>
                            <Can action="subscriptions:update">
                              <Button
                                size="sm"
                                variant="ghost"
                                className="text-error hover:text-error hover:bg-error/10 px-2.5 py-1 h-7 text-xs font-bold rounded-lg flex items-center gap-1"
                                onClick={(e) => { e.stopPropagation(); setRejectTarget({ id: sub.id, name: sub.athlete_name }); setRejectReason("") }}
                              >
                                <X className="w-3.5 h-3.5" />
                                رفض
                              </Button>
                            </Can>
                          </div>
                        ) : renewMode ? (
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation()
                              void openQuickRenewFromRow(sub)
                            }}
                            className="inline-flex items-center gap-1 rounded-lg bg-secondary/10 text-secondary border border-secondary/15 px-3 py-1.5 text-xs font-bold hover:bg-secondary/20 transition-colors"
                          >
                            <RefreshCw className="w-3.5 h-3.5" />
                            تجديد
                          </button>
                        ) : (
                          <button
                            className="p-1.5 text-muted-foreground hover:text-primary transition-colors rounded-lg hover:bg-surface-container"
                            onClick={(e) => {
                              e.stopPropagation()
                              setDetailsSub(sub)
                            }}
                            type="button"
                          >
                            <MoreVertical className="w-4 h-4" />
                          </button>
                        )}
                      </td>
                    </motion.tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* ── Pagination ── */}
          <div className="px-4 sm:px-6 py-4 flex flex-col sm:flex-row items-center justify-between gap-4 border-t border-outline-variant/20 bg-surface/50">
            <span className="text-xs text-muted-foreground">
              عرض {subscriptions.length} من أصل {data?.count || 0} اشتراك
            </span>
            <div className="inline-flex items-center gap-1">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="w-8 h-8 rounded-lg p-0"
              >
                <ChevronRight className="w-4 h-4" />
              </Button>
              {getPageNumbers().map((p, i) =>
                p === "..." ? (
                  <span key={`ellipsis-${i}`} className="px-2 text-xs text-muted-foreground">
                    ...
                  </span>
                ) : (
                  <button
                    key={p}
                    onClick={() => setPage(p as number)}
                    className={`min-w-[2rem] h-8 rounded-lg text-sm font-semibold transition-all ${
                      p === page
                        ? "bg-primary text-primary-foreground shadow-sm"
                        : "text-muted-foreground hover:bg-surface-container-high hover:text-foreground"
                    }`}
                  >
                    {p}
                  </button>
                )
              )}
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setPage((p) => p + 1)}
                disabled={page >= totalPages}
                className="w-8 h-8 rounded-lg p-0"
              >
                <ChevronLeft className="w-4 h-4" />
              </Button>
            </div>
          </div>
        </motion.div>
      </section>

      {rejectTarget && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 flex items-center justify-center" onClick={() => setRejectTarget(null)}>
          <div className="w-full max-w-md rounded-2xl border border-border bg-card p-5 space-y-4" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-bold">رفض الاشتراك</h3>
            <p className="text-sm text-muted-foreground">
              سيتم رفض اشتراك <span className="font-semibold text-foreground">{rejectTarget.name}</span>.
            </p>
            <div>
              <label className="mb-1 block text-xs text-muted-foreground">
                سبب الرفض <span className="text-destructive">*</span>
              </label>
              <textarea
                rows={3}
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                className="w-full rounded-xl border border-border bg-surface-container-low px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary"
                placeholder="اكتب سبب الرفض..."
              />
            </div>
            <div className="flex justify-end gap-2">
              <Button type="button" variant="ghost" onClick={() => setRejectTarget(null)}>إلغاء</Button>
              <Button
                type="button"
                variant="destructive"
                disabled={!rejectReason.trim()}
                onClick={() => {
                  void handleReject(rejectTarget.id, rejectReason)
                  setRejectTarget(null)
                }}
              >
                تأكيد الرفض
              </Button>
            </div>
          </div>
        </div>
      )}

      {detailsSub && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 flex items-center justify-center" onClick={() => setDetailsSub(null)}>
          <div className="w-full max-w-xl rounded-2xl border border-border bg-card p-5 space-y-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold">تفاصيل الاشتراك</h3>
              <button type="button" onClick={() => setDetailsSub(null)}><X className="w-5 h-5 text-muted-foreground" /></button>
            </div>
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div><p className="text-muted-foreground">الرياضي</p><p className="font-semibold">{detailsSub.athlete_name}</p></div>
              <div><p className="text-muted-foreground">رقم العضوية</p><p className="font-semibold">{detailsSub.membership_number}</p></div>
              <div><p className="text-muted-foreground">الباقة</p><p className="font-semibold">{detailsSub.package_name}</p></div>
              <div><p className="text-muted-foreground">طريقة الدفع</p><p className="font-semibold">{detailsSub.payment_method === "bank_transfer" ? "تحويل بنكي" : "نقدي"}</p></div>
              <div><p className="text-muted-foreground">البداية</p><p className="font-semibold">{formatDate(detailsSub.start_date)}</p></div>
              <div><p className="text-muted-foreground">النهاية</p><p className="font-semibold">{formatDate(detailsSub.end_date)}</p></div>
              <div><p className="text-muted-foreground">المبلغ</p><p className="font-semibold">{Number(detailsSub.amount).toLocaleString("ar-SA-u-nu-latn")} د.ل</p></div>
              <div><p className="text-muted-foreground">الحالة</p><p className="font-semibold">{statusMap[detailsSub.status]?.label || detailsSub.status}</p></div>
              {detailsSub.status === "rejected" && detailsSub.rejection_reason && (
                <div className="col-span-2 rounded-xl border border-error/30 bg-error/10 p-3 text-xs">
                  <p className="text-muted-foreground mb-0.5">سبب الرفض</p>
                  <p className="font-semibold text-error">{detailsSub.rejection_reason}</p>
                </div>
              )}
            </div>
            <div className="flex flex-wrap justify-end gap-2">
              {detailsSub.invoice_pdf_url && (
                <a
                  href={toAbsoluteMediaUrl(detailsSub.invoice_pdf_url) || "#"}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center gap-2 rounded-lg border border-primary/25 bg-primary/8 px-3 py-2 text-xs font-semibold text-primary hover:bg-primary/12"
                >
                  <FileText className="w-4 h-4" /> عرض الإيصال
                </a>
              )}
              <Link
                to={`/dashboard/athletes/${detailsSub.athlete}`}
                className="inline-flex items-center gap-2 rounded-lg border border-border px-3 py-2 text-xs font-semibold text-foreground hover:bg-surface-container"
              >
                <Eye className="w-4 h-4" /> فتح ملف الرياضي
              </Link>
            </div>
          </div>
        </div>
      )}

      {showCreateSubModal && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 flex items-center justify-center" onClick={() => setShowCreateSubModal(false)}>
          <form className="w-full max-w-2xl rounded-2xl border border-border bg-card p-5 space-y-4" onClick={(e) => e.stopPropagation()} onSubmit={submitManualSubscription}>
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold">إضافة اشتراك يدوي</h3>
              <button type="button" onClick={() => setShowCreateSubModal(false)}><X className="w-5 h-5 text-muted-foreground" /></button>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label className="mb-1 block text-xs text-muted-foreground">الرياضي</label>
                <select
                  className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm"
                  value={manualSubForm.athlete}
                  onChange={(e) => setManualSubForm((p) => ({ ...p, athlete: e.target.value }))}
                  required
                >
                  <option value="">اختر رياضي</option>
                  {athleteOptions.map((athlete) => (
                    <option key={athlete.id} value={String(athlete.id)}>{athlete.full_name} ({athlete.membership_number})</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs text-muted-foreground">اختر الباقة</label>
                <select
                  className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm"
                  value={manualSubForm.package_id}
                  onChange={(e) => {
                    const id = e.target.value
                    const pkg = packages.find((p) => p.id === Number(id))
                    if (id && pkg) {
                      const start = manualSubForm.start_date || new Date().toISOString().slice(0, 10)
                      const date = new Date(start)
                      if (pkg.duration_type === "days") {
                        date.setDate(date.getDate() + pkg.duration_value)
                      } else if (pkg.duration_type === "weeks") {
                        date.setDate(date.getDate() + pkg.duration_value * 7)
                      } else {
                        date.setMonth(date.getMonth() + pkg.duration_value)
                      }
                      setManualSubForm((prev) => ({
                        ...prev,
                        package_id: id,
                        package_name: pkg.name,
                        amount: pkg.price,
                        end_date: date.toISOString().slice(0, 10),
                      }))
                    } else {
                      setManualSubForm((prev) => ({ ...prev, package_id: id, package_name: "", amount: "" }))
                    }
                  }}
                >
                  <option value="">بدون باقة (إدخال يدوي)</option>
                  {packages.map((pkg) => (
                    <option key={pkg.id} value={String(pkg.id)}>
                      {pkg.name} - {Number(pkg.price).toLocaleString("ar-SA-u-nu-latn")} د.ل
                    </option>
                  ))}
                </select>
              </div>
              {!manualSubForm.package_id && (
                <div>
                  <label className="mb-1 block text-xs text-muted-foreground">اسم الباقة</label>
                  <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm" value={manualSubForm.package_name} onChange={(e) => setManualSubForm((p) => ({ ...p, package_name: e.target.value }))} placeholder="أدخل اسم الباقة" />
                </div>
              )}
              <div>
                <label className="mb-1 block text-xs text-muted-foreground">تاريخ البداية</label>
                <input type="date" className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm" value={manualSubForm.start_date} onChange={(e) => {
                  const start = e.target.value
                  const id = manualSubForm.package_id
                  let end = ""
                  if (id) {
                    const pkg = packages.find((p) => p.id === Number(id))
                    if (pkg) {
                      const date = new Date(start)
                      if (pkg.duration_type === "days") {
                        date.setDate(date.getDate() + pkg.duration_value)
                      } else if (pkg.duration_type === "weeks") {
                        date.setDate(date.getDate() + pkg.duration_value * 7)
                      } else {
                        date.setMonth(date.getMonth() + pkg.duration_value)
                      }
                      end = date.toISOString().slice(0, 10)
                    }
                  }
                  setManualSubForm((p) => ({ ...p, start_date: start, end_date: end || p.end_date }))
                }} required />
              </div>
              <div>
                <label className="mb-1 block text-xs text-muted-foreground">تاريخ النهاية</label>
                <input type="date" className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm" value={manualSubForm.end_date} onChange={(e) => setManualSubForm((p) => ({ ...p, end_date: e.target.value }))} required />
              </div>
              <div>
                <label className="mb-1 block text-xs text-muted-foreground">المبلغ</label>
                <input type="number" step="0.01" min="0" className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm" value={manualSubForm.amount} onChange={(e) => setManualSubForm((p) => ({ ...p, amount: e.target.value }))} required />
              </div>
              <div>
                <label className="mb-1 block text-xs text-muted-foreground">الحالة</label>
                <select className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm" value={manualSubForm.status} onChange={(e) => setManualSubForm((p) => ({ ...p, status: e.target.value as "active" | "pending" }))}>
                  <option value="active">نشط</option>
                  <option value="pending">قيد الانتظار</option>
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs text-muted-foreground">طريقة الدفع</label>
                <select className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm" value={manualSubForm.payment_method} onChange={(e) => setManualSubForm((p) => ({ ...p, payment_method: e.target.value as "cash" | "bank_transfer" }))}>
                  <option value="cash">نقدي</option>
                  <option value="bank_transfer">تحويل مصرفي</option>
                </select>
              </div>
              {manualSubForm.payment_method === "bank_transfer" && (
                <div>
                  <label className="mb-1 block text-xs text-muted-foreground">إيصال PDF</label>
                  <input type="file" accept="application/pdf,.pdf" className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm" onChange={(e) => setManualInvoice(e.target.files?.[0] || null)} />
                </div>
              )}
            </div>
            {createSubError && <p className="text-xs text-error">{createSubError}</p>}
            <div className="flex justify-end gap-2">
              <Button type="button" variant="ghost" onClick={() => setShowCreateSubModal(false)}>إلغاء</Button>
              <Button type="submit" disabled={createSubLoading}>{createSubLoading ? "جارٍ الحفظ..." : "حفظ الاشتراك"}</Button>
            </div>
          </form>
        </div>
      )}

      {(quickRenewPackage || quickRenewPreset) && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 flex items-center justify-center" onClick={closeQuickRenew}>
          <form
            className="w-full max-w-xl rounded-2xl border border-border bg-card p-5 space-y-4"
            onClick={(e) => e.stopPropagation()}
            onSubmit={submitQuickRenew}
          >
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold">
                {quickRenewPackage ? `تجديد سريع - ${quickRenewPackage.title}` : "تجديد الاشتراك"}
              </h3>
              <button type="button" onClick={closeQuickRenew}><X className="w-5 h-5 text-muted-foreground" /></button>
            </div>

            <div className="rounded-xl border border-border bg-surface-container-low p-3 text-sm">
              <p>القيمة: <span className="font-semibold">{quickRenewAmount.toLocaleString("ar-SA-u-nu-latn")} د.ل</span></p>
              <p className="text-muted-foreground text-xs mt-1">
                مدة التجديد المعتمدة: {quickRenewMonths} شهر
              </p>
            </div>

            <div>
              <label className="mb-1 block text-xs text-muted-foreground">طريقة الدفع</label>
              <select
                className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm"
                value={quickRenewPaymentMethod}
                onChange={(e) => setQuickRenewPaymentMethod(e.target.value as "cash" | "bank_transfer")}
              >
                <option value="cash">نقدي</option>
                <option value="bank_transfer">تحويل مصرفي</option>
              </select>
            </div>

            {quickRenewPaymentMethod === "bank_transfer" && (
              <div>
                <label className="mb-1 block text-xs text-muted-foreground">إيصال التحويل (PDF اختياري)</label>
                <input
                  type="file"
                  accept="application/pdf,.pdf"
                  className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm"
                  onChange={(e) => setQuickRenewInvoice(e.target.files?.[0] || null)}
                />
              </div>
            )}

            {quickRenewPreset ? (
              <div className="rounded-xl border border-border bg-surface-container-low p-3 text-sm space-y-1.5">
                <p className="flex items-center justify-between">
                  <span className="text-muted-foreground text-xs">الرياضي</span>
                  <span className="font-semibold">{quickRenewPresetSub?.athlete_name || quickRenewAthleteName || quickRenewAthlete}</span>
                </p>
                <p className="flex items-center justify-between">
                  <span className="text-muted-foreground text-xs">الاشتراك المراد تجديده</span>
                  <span className="font-semibold">
                    {quickRenewPresetSub?.package_name || "بدون باقة"} {quickRenewPresetSub ? `- ينتهي ${formatDate(quickRenewPresetSub.end_date)}` : ""}
                  </span>
                </p>
              </div>
            ) : (
              <>
                <div>
                  <label className="mb-1 block text-xs text-muted-foreground">اختر الرياضي</label>
                  <select
                    className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm"
                    value={quickRenewAthlete}
                    onChange={(e) => {
                      setQuickRenewAthlete(e.target.value)
                      void loadAthleteSubscriptions(e.target.value)
                    }}
                    required
                  >
                    <option value="">اختر رياضي</option>
                    {athleteOptions.map((athlete) => (
                      <option key={athlete.id} value={String(athlete.id)}>
                        {athlete.full_name} ({athlete.membership_number})
                      </option>
                    ))}
                  </select>
                </div>

                {quickRenewAthlete && (
                  <div>
                    <label className="mb-1 block text-xs text-muted-foreground">الاشتراك المستهدف</label>
                    {quickRenewLoadingSubs ? (
                      <div className="rounded-xl border border-border bg-surface-container-low p-3 text-xs text-muted-foreground">جاري تحميل الاشتراكات...</div>
                    ) : (
                      <select
                        className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm"
                        value={quickRenewSubId}
                        onChange={(e) => setQuickRenewSubId(e.target.value)}
                        required
                      >
                        <option value="">اختر اشتراك</option>
                        {quickRenewSubs.map((sub) => (
                          <option key={sub.id} value={String(sub.id)}>
                            {sub.package_name} - {statusMap[sub.status]?.label || sub.status} - ينتهي {formatDate(sub.end_date)}
                          </option>
                        ))}
                      </select>
                    )}
                  </div>
                )}
              </>
            )}

            {quickRenewError && <p className="text-xs text-error">{quickRenewError}</p>}

            <div className="flex justify-end gap-2">
              <Button type="button" variant="ghost" onClick={closeQuickRenew}>إلغاء</Button>
              <Button type="submit" disabled={renewSubscriptionMut.isPending || quickRenewLoadingSubs}>
                {renewSubscriptionMut.isPending ? "جاري التجديد..." : "تنفيذ التجديد"}
              </Button>
            </div>
          </form>
        </div>
      )}
    </motion.div>
  )
}
