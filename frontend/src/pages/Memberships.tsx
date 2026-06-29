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
  Pencil,
  Trash2,
  X,
  ChevronLeft,
  ChevronRight,
} from "lucide-react"
import { useRenewSubscription, useSubscriptions, useUpdateSubscription } from "@/lib/hooks/useSubscriptions"
import { usePackages, type SubscriptionPackage } from "@/lib/hooks/usePackages"
import { Button } from "@/components/ui/button"
import { Input, Select } from "@/components/ui/input"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Link } from "react-router-dom"
import { api } from "@/lib/api"
import { useAuth } from "@/lib/auth"
import { toAbsoluteMediaUrl } from "@/lib/media"

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

type PackageFormState = {
  name: string
  description: string
  price: string
  duration_type: "weeks" | "months"
  duration_value: number
  max_athletes: number
  tag: "discount" | "special" | "normal"
  icon_name: string
  color_class: string
  order: number
  is_active: boolean
  featuresText: string
}

type FlashMessage = {
  type: "success" | "error" | "info"
  text: string
}

type QuickRenewPackage = {
  id: number
  title: string
  amount: number
  durationType: "weeks" | "months"
  durationValue: number
}

const ICON_OPTIONS = [
  { value: "CalendarDays", label: "تقويم يومي" },
  { value: "CalendarRange", label: "تقويم زمني" },
  { value: "Crown", label: "باقة مميزة" },
]

const STYLE_OPTIONS = [
  { value: "", label: "افتراضي" },
  { value: "featured", label: "مميز" },
  { value: "promo", label: "ترويجي" },
]

const DEFAULT_PACKAGE_FORM: PackageFormState = {
  name: "",
  description: "",
  price: "",
  duration_type: "months",
  duration_value: 1,
  max_athletes: 1,
  tag: "normal",
  icon_name: "CalendarDays",
  color_class: "",
  order: 0,
  is_active: true,
  featuresText: "",
}

export default function MembershipsPage() {
  const queryClient = useQueryClient()
  const { user } = useAuth()
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("")
  const [page, setPage] = useState(1)
  const [packageModalOpen, setPackageModalOpen] = useState(false)
  const [editingPackageId, setEditingPackageId] = useState<number | null>(null)
  const [packageForm, setPackageForm] = useState<PackageFormState>(DEFAULT_PACKAGE_FORM)
  const [packageSubmitting, setPackageSubmitting] = useState(false)
  const [packageError, setPackageError] = useState<string | null>(null)
  const [packageFieldErrors, setPackageFieldErrors] = useState<Record<string, string>>({})
  const [flash, setFlash] = useState<FlashMessage | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<SubscriptionPackage | null>(null)
  const [detailsSub, setDetailsSub] = useState<any | null>(null)
  const [showCreateSubModal, setShowCreateSubModal] = useState(false)
  const [createSubLoading, setCreateSubLoading] = useState(false)
  const [createSubError, setCreateSubError] = useState<string | null>(null)
  const [athleteOptions, setAthleteOptions] = useState<Array<{ id: number; full_name: string; membership_number: string }>>([])
  const [manualSubForm, setManualSubForm] = useState({
    athlete: "",
    start_date: "",
    end_date: "",
    amount: "",
    package_name: "اشتراك إداري",
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

  const canManagePackages = user?.role === "super_admin" || user?.role === "reception"

  useEffect(() => {
    if (!flash) return
    const timer = window.setTimeout(() => setFlash(null), 3200)
    return () => window.clearTimeout(timer)
  }, [flash])

  const { data, isLoading } = useSubscriptions({
    page,
    page_size: 20,
    search: search || undefined,
    status: statusFilter || undefined,
  })

  const { data: packagesData } = usePackages()
  const packages = packagesData?.results ?? []

  const updateSubscriptionMut = useUpdateSubscription()
  const renewSubscriptionMut = useRenewSubscription()

  const normalizeRenewMonths = (durationType: "weeks" | "months", durationValue: number) => {
    const estimated = durationType === "weeks" ? Math.max(1, Math.ceil(durationValue / 4)) : Math.max(1, durationValue)
    const allowed = [1, 3, 6, 12]
    const match = allowed.find((m) => m >= estimated)
    return match ?? 12
  }

  const openQuickRenew = async (pkg: QuickRenewPackage) => {
    setQuickRenewPackage(pkg)
    setQuickRenewAthlete("")
    setQuickRenewSubId("")
    setQuickRenewSubs([])
    setQuickRenewError(null)
    await loadAthletes()
  }

  const closeQuickRenew = () => {
    if (renewSubscriptionMut.isPending) return
    setQuickRenewPackage(null)
    setQuickRenewAthlete("")
    setQuickRenewSubId("")
    setQuickRenewSubs([])
    setQuickRenewError(null)
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
        setQuickRenewError("لا توجد اشتراكات سابقة لهذا اللاعب لتجديدها")
      }
    } catch (err: any) {
      setQuickRenewSubs([])
      setQuickRenewSubId("")
      setQuickRenewError(err?.message || "تعذر تحميل اشتراكات اللاعب")
    } finally {
      setQuickRenewLoadingSubs(false)
    }
  }

  const submitQuickRenew = async (e: FormEvent) => {
    e.preventDefault()
    if (!quickRenewPackage) return
    if (!quickRenewAthlete) {
      setQuickRenewError("يرجى اختيار اللاعب")
      return
    }
    if (!quickRenewSubId) {
      setQuickRenewError("يرجى اختيار الاشتراك المراد تجديده")
      return
    }

    try {
      setQuickRenewError(null)
      const months = normalizeRenewMonths(quickRenewPackage.durationType, quickRenewPackage.durationValue)
      await renewSubscriptionMut.mutateAsync({
        id: Number(quickRenewSubId),
        months,
        amount: quickRenewPackage.amount.toString(),
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
      package_name: "اشتراك إداري",
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
    if (manualSubForm.payment_method === "bank_transfer" && !manualInvoice) {
      setCreateSubError("يرجى رفع إيصال PDF عند اختيار التحويل المصرفي")
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

  const handleReject = async (id: number) => {
    try {
      await updateSubscriptionMut.mutateAsync({ id, status: "rejected" })
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
    const Icon = iconMap[pkg.icon_name] || CalendarDays
    const priceNum = Number(pkg.price)
    const durationDays = pkg.duration_type === "weeks" ? pkg.duration_value * 7 : pkg.duration_value * 30
    const monthly = Math.round(priceNum / (durationDays / 30))
    const isFeatured = pkg.color_class?.includes("featured") || pkg.id === 2
    return {
      id: pkg.id,
      title: pkg.name,
      price: priceNum.toLocaleString("ar-SA-u-nu-latn"),
      perMonth: monthly.toLocaleString("ar-SA-u-nu-latn"),
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

  const resetPackageForm = () => {
    setPackageForm(DEFAULT_PACKAGE_FORM)
    setEditingPackageId(null)
    setPackageError(null)
    setPackageFieldErrors({})
  }

  const openCreatePackageModal = () => {
    resetPackageForm()
    setPackageModalOpen(true)
  }

  const openEditPackageModal = (pkg: SubscriptionPackage) => {
    setEditingPackageId(pkg.id)
    setPackageError(null)
    setPackageForm({
      name: pkg.name,
      description: pkg.description || "",
      price: pkg.price,
      duration_type: pkg.duration_type,
      duration_value: pkg.duration_value,
      max_athletes: pkg.max_athletes,
      tag: pkg.tag,
      icon_name: pkg.icon_name || "CalendarDays",
      color_class: pkg.color_class || "",
      order: pkg.order,
      is_active: pkg.is_active,
      featuresText: (pkg.features || []).join("\n"),
    })
    setPackageModalOpen(true)
  }

  const closePackageModal = () => {
    if (packageSubmitting) return
    setPackageModalOpen(false)
    resetPackageForm()
  }

  const buildPackagePayload = () => {
    const features = packageForm.featuresText
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean)

    return {
      name: packageForm.name.trim(),
      description: packageForm.description.trim(),
      price: packageForm.price,
      duration_type: packageForm.duration_type,
      duration_value: packageForm.duration_value,
      max_athletes: packageForm.max_athletes,
      tag: packageForm.tag,
      icon_name: packageForm.icon_name.trim(),
      color_class: packageForm.color_class.trim(),
      order: packageForm.order,
      is_active: packageForm.is_active,
      features,
    }
  }

  const submitPackage = async (e: FormEvent) => {
    e.preventDefault()
    const nextFieldErrors: Record<string, string> = {}
    if (!packageForm.name.trim()) nextFieldErrors.name = "اسم الباقة مطلوب"
    if (!packageForm.price || Number(packageForm.price) <= 0) nextFieldErrors.price = "السعر يجب أن يكون أكبر من صفر"
    if (!packageForm.duration_value || packageForm.duration_value < 1) nextFieldErrors.duration_value = "المدة يجب أن تكون 1 أو أكثر"
    if (!packageForm.max_athletes || packageForm.max_athletes < 1) nextFieldErrors.max_athletes = "أقصى عدد يجب أن يكون 1 أو أكثر"
    if (packageForm.order < 0) nextFieldErrors.order = "الترتيب لا يمكن أن يكون سالباً"

    if (Object.keys(nextFieldErrors).length > 0) {
      setPackageFieldErrors(nextFieldErrors)
      setPackageError("يرجى مراجعة الحقول المطلوبة")
      return
    }

    try {
      setPackageSubmitting(true)
      setPackageError(null)
      setPackageFieldErrors({})
      const payload = buildPackagePayload()

      if (editingPackageId) {
        await api.put(`/packages/${editingPackageId}/`, payload)
        setFlash({ type: "success", text: "تم تحديث الباقة بنجاح" })
      } else {
        await api.post("/packages/", payload)
        setFlash({ type: "success", text: "تم إنشاء الباقة بنجاح" })
      }

      await queryClient.invalidateQueries({ queryKey: ["packages"] })
      closePackageModal()
    } catch (err: any) {
      setPackageError(err?.message || "تعذر حفظ الباقة")
    } finally {
      setPackageSubmitting(false)
    }
  }

  const deletePackage = async (pkg: SubscriptionPackage) => {
    setDeleteTarget(pkg)
  }

  const confirmDeletePackage = async () => {
    if (!deleteTarget) return

    try {
      await api.delete(`/packages/${deleteTarget.id}/`)
      await queryClient.invalidateQueries({ queryKey: ["packages"] })
      setFlash({ type: "success", text: "تم حذف الباقة بنجاح" })
    } catch (err: any) {
      setFlash({ type: "error", text: err?.message || "تعذر حذف الباقة" })
    } finally {
      setDeleteTarget(null)
    }
  }

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
          <p className="text-muted-foreground mt-1 text-sm">تجديد، متابعة، وإدارة الباقات المالية للاعبين.</p>
        </div>
        <button className="w-full md:w-auto" onClick={() => void openCreateSubscriptionModal()} type="button">
          <Button size="lg" className="w-full md:w-auto bg-primary text-primary-foreground hover:bg-primary/90 shadow-lg shadow-primary/20 hover:shadow-xl hover:shadow-primary/25">
            <PlusCircle className="w-5 h-5" />
            اشتراك جديد
          </Button>
        </button>
      </motion.div>

      {/* ── Quick Renewal Packages ── */}
      <section>
        <motion.div variants={itemVariants} className="section-header mb-6">
          باقات التجديد السريع
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
                whileHover={{ y: -6, transition: { duration: 0.3, ease: "easeOut" } }}
                className={`relative rounded-2xl overflow-hidden transition-shadow duration-500 ${
                  pkg.featured
                    ? "glass-card shadow-lg shadow-primary/20 hover:shadow-xl hover:shadow-primary/30 border-primary/30"
                    : "glass-card hover:shadow-lg"
                }`}
              >
                {pkg.featured && (
                  <div className="absolute -right-10 -top-10 w-32 h-32 bg-primary-container/20 rounded-full blur-2xl pointer-events-none" />
                )}

                <div className="relative z-10 p-6 flex flex-col h-full">
                  <div className="flex justify-between items-start mb-4">
                    <div className={`p-2.5 rounded-lg ${pkg.featured ? "bg-primary text-primary-foreground shadow-md" : "bg-surface-container-high text-primary"}`}>
                      <Icon className="w-5 h-5" />
                    </div>
                    <span className={`text-[11px] font-bold px-2.5 py-1 rounded-full ${pkg.badgeCls}`}>
                      {pkg.badge}
                    </span>
                  </div>

                  <h4 className={`text-lg font-bold ${pkg.featured ? "text-primary" : "text-foreground"}`}>
                    {pkg.title}
                  </h4>

                  <div className="mt-2 mb-1">
                    <span className={`text-3xl font-extrabold ${pkg.featured ? "text-primary" : "text-foreground"}`}>
                      {pkg.price}
                    </span>
                    <span className={`text-sm mr-1 ${pkg.featured ? "text-primary/70" : "text-muted-foreground"}`}>
                      د.ل
                    </span>
                  </div>

                  <ul className="space-y-2.5 mb-6 flex-1">
                    {pkg.features.map((feat, i) => (
                      <li key={i} className={`flex items-center gap-2.5 text-xs ${pkg.featured ? "text-foreground/80" : "text-muted-foreground"}`}>
                        <CheckCircle2 className="w-4 h-4 shrink-0 text-secondary" />
                        {feat}
                      </li>
                    ))}
                  </ul>

                  {canManagePackages && (
                    <div className="mb-3 flex items-center justify-end gap-2">
                      <Button type="button" variant="ghost" size="sm" onClick={() => openEditPackageModal(pkg.raw)}>
                        <Pencil className="w-4 h-4" /> تعديل
                      </Button>
                      <Button type="button" variant="destructive" size="sm" onClick={() => deletePackage(pkg.raw)}>
                        <Trash2 className="w-4 h-4" /> حذف
                      </Button>
                    </div>
                  )}

                  <button
                    onClick={() => openQuickRenew({
                      id: pkg.id,
                      title: pkg.title,
                      amount: Number(pkg.raw.price),
                      durationType: pkg.raw.duration_type,
                      durationValue: pkg.raw.duration_value,
                    })}
                    className={`w-full py-2.5 rounded-xl text-sm font-bold transition-all active:scale-[0.97] ${
                      pkg.featured
                        ? "bg-primary text-primary-foreground shadow-md shadow-primary/30 hover:shadow-lg hover:shadow-primary/40 hover:bg-primary/90"
                        : "bg-surface-container-highest text-primary border border-primary/20 hover:bg-primary hover:text-primary-foreground hover:border-primary"
                    }`}
                  >
                    تجديد سريع
                  </button>
                </div>
              </motion.div>
            )
          })}

          {canManagePackages && (
            <motion.button
              type="button"
              variants={cardVariants}
              custom={pkgList.length + 1}
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true, margin: "-50px" }}
              onClick={openCreatePackageModal}
              className="rounded-2xl border-2 border-dashed border-primary/40 bg-primary/5 hover:bg-primary/10 transition-colors min-h-[260px] flex flex-col items-center justify-center gap-3"
            >
              <div className="w-12 h-12 rounded-full bg-primary text-primary-foreground flex items-center justify-center">
                <PlusCircle className="w-6 h-6" />
              </div>
              <p className="font-bold text-primary">إضافة باقة جديدة</p>
              <p className="text-xs text-muted-foreground">إنشاء باقات جديدة مع الأسعار والمدة والخصائص</p>
            </motion.button>
          )}
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
                placeholder="بحث باسم اللاعب أو رقم الهوية..."
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

        <motion.div variants={itemVariants} className="glass-card rounded-2xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[680px] text-right text-sm">
              <thead>
                <tr className="bg-surface-container-high/50 border-b border-outline-variant/30 text-muted-foreground text-xs font-bold">
                  <th scope="col" className="px-6 py-4">اسم اللاعب</th>
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
                            <Button
                              size="sm"
                              variant="ghost"
                              className="text-secondary hover:text-secondary hover:bg-secondary/10 px-2.5 py-1 h-7 text-xs font-bold rounded-lg flex items-center gap-1"
                              onClick={(e) => { e.stopPropagation(); void handleApprove(sub.id) }}
                            >
                              <CheckCircle2 className="w-3.5 h-3.5" />
                              تأكيد
                            </Button>
                            <Button
                              size="sm"
                              variant="ghost"
                              className="text-error hover:text-error hover:bg-error/10 px-2.5 py-1 h-7 text-xs font-bold rounded-lg flex items-center gap-1"
                              onClick={(e) => { e.stopPropagation(); void handleReject(sub.id) }}
                            >
                              <X className="w-3.5 h-3.5" />
                              رفض
                            </Button>
                          </div>
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

      {deleteTarget && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 flex items-center justify-center">
          <div className="w-full max-w-md rounded-2xl border border-border bg-card p-5 space-y-4">
            <h3 className="text-lg font-bold">تأكيد الحذف</h3>
            <p className="text-sm text-muted-foreground">
              هل تريد حذف باقة <span className="font-semibold text-foreground">{deleteTarget.name}</span>؟ لا يمكن التراجع بعد التنفيذ.
            </p>
            <div className="flex justify-end gap-2">
              <Button type="button" variant="ghost" onClick={() => setDeleteTarget(null)}>إلغاء</Button>
              <Button type="button" variant="destructive" onClick={confirmDeletePackage}>حذف</Button>
            </div>
          </div>
        </div>
      )}

      {packageModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 flex items-center justify-center">
          <form
            onSubmit={submitPackage}
            className="w-full max-w-3xl max-h-[90vh] overflow-y-auto rounded-2xl border border-border bg-card p-5 md:p-6 space-y-4"
          >
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold">
                {editingPackageId ? "تعديل الباقة" : "إضافة باقة جديدة"}
              </h3>
              <button
                type="button"
                onClick={closePackageModal}
                aria-label="إغلاق"
                className="text-muted-foreground hover:text-foreground"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label htmlFor="package-name" className="mb-1 block text-xs text-muted-foreground">اسم الباقة</label>
              <input
                id="package-name"
                value={packageForm.name}
                onChange={(e) => {
                  setPackageForm((prev) => ({ ...prev, name: e.target.value }))
                  setPackageFieldErrors((prev) => ({ ...prev, name: "" }))
                }}
                placeholder="اسم الباقة"
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              />
                {packageFieldErrors.name && <p className="mt-1 text-[11px] text-error">{packageFieldErrors.name}</p>}
              </div>
              <div>
                <label htmlFor="package-price" className="mb-1 block text-xs text-muted-foreground">السعر</label>
              <input
                id="package-price"
                value={packageForm.price}
                onChange={(e) => {
                  setPackageForm((prev) => ({ ...prev, price: e.target.value }))
                  setPackageFieldErrors((prev) => ({ ...prev, price: "" }))
                }}
                type="number"
                min="0"
                step="0.01"
                placeholder="السعر"
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              />
                {packageFieldErrors.price && <p className="mt-1 text-[11px] text-error">{packageFieldErrors.price}</p>}
              </div>
            </div>

            <label htmlFor="package-description" className="mb-1 block text-xs text-muted-foreground">وصف الباقة</label>
            <textarea
              id="package-description"
              value={packageForm.description}
              onChange={(e) => setPackageForm((prev) => ({ ...prev, description: e.target.value }))}
              rows={3}
              placeholder="الوصف"
              className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
            />

            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div>
                <label htmlFor="package-duration-type" className="mb-1 block text-xs text-muted-foreground">وحدة المدة</label>
              <select
                id="package-duration-type"
                value={packageForm.duration_type}
                onChange={(e) => setPackageForm((prev) => ({ ...prev, duration_type: e.target.value as "weeks" | "months" }))}
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              >
                <option value="weeks">أسابيع</option>
                <option value="months">أشهر</option>
              </select>
              </div>

              <div>
                <label htmlFor="package-duration" className="mb-1 block text-xs text-muted-foreground">عدد الوحدات</label>
              <input
                id="package-duration"
                type="number"
                min="1"
                value={packageForm.duration_value}
                onChange={(e) => {
                  setPackageForm((prev) => ({ ...prev, duration_value: Number(e.target.value) || 1 }))
                  setPackageFieldErrors((prev) => ({ ...prev, duration_value: "" }))
                }}
                placeholder="عدد المدة"
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              />
                {packageFieldErrors.duration_value && <p className="mt-1 text-[11px] text-error">{packageFieldErrors.duration_value}</p>}
              </div>

              <div>
                <label htmlFor="package-max-athletes" className="mb-1 block text-xs text-muted-foreground">الحد الأقصى للرياضيين</label>
              <input
                id="package-max-athletes"
                type="number"
                min="1"
                value={packageForm.max_athletes}
                onChange={(e) => {
                  setPackageForm((prev) => ({ ...prev, max_athletes: Number(e.target.value) || 1 }))
                  setPackageFieldErrors((prev) => ({ ...prev, max_athletes: "" }))
                }}
                placeholder="أقصى عدد رياضيين"
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              />
                {packageFieldErrors.max_athletes && <p className="mt-1 text-[11px] text-error">{packageFieldErrors.max_athletes}</p>}
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div>
                <label htmlFor="package-tag" className="mb-1 block text-xs text-muted-foreground">نوع الباقة</label>
              <select
                id="package-tag"
                value={packageForm.tag}
                onChange={(e) => setPackageForm((prev) => ({ ...prev, tag: e.target.value as "discount" | "special" | "normal" }))}
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              >
                <option value="normal">عادي</option>
                <option value="special">مميز</option>
                <option value="discount">خصم</option>
              </select>
              </div>

              <div>
                <label htmlFor="package-icon" className="mb-1 block text-xs text-muted-foreground">أيقونة العرض</label>
                <select
                  id="package-icon"
                  value={packageForm.icon_name}
                  onChange={(e) => setPackageForm((prev) => ({ ...prev, icon_name: e.target.value }))}
                  className="bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
                >
                  {ICON_OPTIONS.map((option) => (
                    <option key={option.value} value={option.value}>{option.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="package-style" className="mb-1 block text-xs text-muted-foreground">نمط العرض</label>
                <select
                  id="package-style"
                  value={packageForm.color_class}
                  onChange={(e) => setPackageForm((prev) => ({ ...prev, color_class: e.target.value }))}
                  className="bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
                >
                  {STYLE_OPTIONS.map((option) => (
                    <option key={option.value || "default"} value={option.value}>{option.label}</option>
                  ))}
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label htmlFor="package-order" className="mb-1 block text-xs text-muted-foreground">ترتيب الظهور</label>
              <input
                id="package-order"
                type="number"
                min="0"
                value={packageForm.order}
                onChange={(e) => {
                  setPackageForm((prev) => ({ ...prev, order: Number(e.target.value) || 0 }))
                  setPackageFieldErrors((prev) => ({ ...prev, order: "" }))
                }}
                placeholder="ترتيب الظهور"
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              />
                {packageFieldErrors.order && <p className="mt-1 text-[11px] text-error">{packageFieldErrors.order}</p>}
              </div>
              <label className="flex items-center gap-2 border border-border rounded-xl px-3 py-2 text-sm">
                <input
                  type="checkbox"
                  checked={packageForm.is_active}
                  onChange={(e) => setPackageForm((prev) => ({ ...prev, is_active: e.target.checked }))}
                />
                الباقة مفعلة
              </label>
            </div>

            <label htmlFor="package-features" className="mb-1 block text-xs text-muted-foreground">ميزات الباقة (كل سطر = ميزة)</label>
            <textarea
              id="package-features"
              value={packageForm.featuresText}
              onChange={(e) => setPackageForm((prev) => ({ ...prev, featuresText: e.target.value }))}
              rows={5}
              placeholder="الميزات (كل سطر ميزة)"
              className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
            />

            {packageError && <p className="text-xs text-error">{packageError}</p>}

            <div className="flex justify-end gap-2">
              <Button type="button" variant="ghost" onClick={closePackageModal}>إلغاء</Button>
              <Button type="submit" disabled={packageSubmitting}>
                {packageSubmitting ? "جارٍ الحفظ..." : "حفظ"}
              </Button>
            </div>
          </form>
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
              <div><p className="text-muted-foreground">اللاعب</p><p className="font-semibold">{detailsSub.athlete_name}</p></div>
              <div><p className="text-muted-foreground">رقم العضوية</p><p className="font-semibold">{detailsSub.membership_number}</p></div>
              <div><p className="text-muted-foreground">الباقة</p><p className="font-semibold">{detailsSub.package_name}</p></div>
              <div><p className="text-muted-foreground">طريقة الدفع</p><p className="font-semibold">{detailsSub.payment_method === "bank_transfer" ? "تحويل بنكي" : "نقدي"}</p></div>
              <div><p className="text-muted-foreground">البداية</p><p className="font-semibold">{formatDate(detailsSub.start_date)}</p></div>
              <div><p className="text-muted-foreground">النهاية</p><p className="font-semibold">{formatDate(detailsSub.end_date)}</p></div>
              <div><p className="text-muted-foreground">المبلغ</p><p className="font-semibold">{Number(detailsSub.amount).toLocaleString("ar-SA-u-nu-latn")} د.ل</p></div>
              <div><p className="text-muted-foreground">الحالة</p><p className="font-semibold">{statusMap[detailsSub.status]?.label || detailsSub.status}</p></div>
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
                <Eye className="w-4 h-4" /> فتح ملف اللاعب
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
                <label className="mb-1 block text-xs text-muted-foreground">اللاعب</label>
                <select
                  className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm"
                  value={manualSubForm.athlete}
                  onChange={(e) => setManualSubForm((p) => ({ ...p, athlete: e.target.value }))}
                  required
                >
                  <option value="">اختر لاعب</option>
                  {athleteOptions.map((athlete) => (
                    <option key={athlete.id} value={String(athlete.id)}>{athlete.full_name} ({athlete.membership_number})</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs text-muted-foreground">اسم الباقة</label>
                <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm" value={manualSubForm.package_name} onChange={(e) => setManualSubForm((p) => ({ ...p, package_name: e.target.value }))} />
              </div>
              <div>
                <label className="mb-1 block text-xs text-muted-foreground">تاريخ البداية</label>
                <input type="date" className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm" value={manualSubForm.start_date} onChange={(e) => setManualSubForm((p) => ({ ...p, start_date: e.target.value }))} required />
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

      {quickRenewPackage && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 flex items-center justify-center" onClick={closeQuickRenew}>
          <form
            className="w-full max-w-xl rounded-2xl border border-border bg-card p-5 space-y-4"
            onClick={(e) => e.stopPropagation()}
            onSubmit={submitQuickRenew}
          >
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold">تجديد سريع - {quickRenewPackage.title}</h3>
              <button type="button" onClick={closeQuickRenew}><X className="w-5 h-5 text-muted-foreground" /></button>
            </div>

            <div className="rounded-xl border border-border bg-surface-container-low p-3 text-sm">
              <p>القيمة: <span className="font-semibold">{quickRenewPackage.amount.toLocaleString("ar-SA-u-nu-latn")} د.ل</span></p>
              <p className="text-muted-foreground text-xs mt-1">
                مدة التجديد المعتمدة: {normalizeRenewMonths(quickRenewPackage.durationType, quickRenewPackage.durationValue)} شهر
              </p>
            </div>

            <div>
              <label className="mb-1 block text-xs text-muted-foreground">اختر اللاعب</label>
              <select
                className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm"
                value={quickRenewAthlete}
                onChange={(e) => {
                  setQuickRenewAthlete(e.target.value)
                  void loadAthleteSubscriptions(e.target.value)
                }}
                required
              >
                <option value="">اختر لاعب</option>
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
