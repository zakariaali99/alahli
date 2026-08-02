import React, { useEffect, useState, type FormEvent } from "react"
import { useQueryClient } from "@tanstack/react-query"
import { motion, type Variants } from "framer-motion"
import { CalendarDays, CalendarRange, Crown, Pencil, PlusCircle, Trash2, X } from "lucide-react"
import { usePackages, type SubscriptionPackage } from "@/lib/hooks/usePackages"
import { Button } from "@/components/ui/button"
import { Can } from "@/components/ui/can"
import { api } from "@/lib/api"
import { useSearchParams } from "react-router-dom"

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

type PackageFormState = {
  name: string
  description: string
  price: string
  new_price: string
  renewal_price: string
  package_type: "monthly" | "multi_month" | "single_session"
  duration_type: "days" | "weeks" | "months"
  duration_value: number
  max_athletes: number
  tag: "discount" | "special" | "normal"
  order: number
  is_active: boolean
  featuresText: string
  department: number | null
}

type FlashMessage = {
  type: "success" | "error" | "info"
  text: string
}

const DEFAULT_PACKAGE_FORM: PackageFormState = {
  name: "",
  description: "",
  price: "",
  new_price: "",
  renewal_price: "",
  package_type: "monthly",
  duration_type: "months",
  duration_value: 1,  max_athletes: 1,
  tag: "normal",
  order: 0,
  is_active: true,
  featuresText: "",
  department: null,
}

export default function PlansPage() {
  const queryClient = useQueryClient()
  const [searchParams] = useSearchParams()
  const deptParam = searchParams.get("department")

  const [packageModalOpen, setPackageModalOpen] = useState(false)
  const [editingPackageId, setEditingPackageId] = useState<number | null>(null)
  const [packageForm, setPackageForm] = useState<PackageFormState>(DEFAULT_PACKAGE_FORM)
  const [packageSubmitting, setPackageSubmitting] = useState(false)
  const [packageError, setPackageError] = useState<string | null>(null)
  const [packageFieldErrors, setPackageFieldErrors] = useState<Record<string, string>>({})
  const [flash, setFlash] = useState<FlashMessage | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<SubscriptionPackage | null>(null)
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

  const { data: packagesData, isLoading } = usePackages(deptParam ?? undefined)
  const packages = packagesData?.results ?? []

  const resetPackageForm = () => {
    setPackageForm({
      ...DEFAULT_PACKAGE_FORM,
      department: deptParam ? Number(deptParam) : null,
    })
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
      new_price: pkg.new_price || pkg.price,
      renewal_price: pkg.renewal_price || "",
      package_type: pkg.package_type || "monthly",
      duration_type: pkg.duration_type,
      duration_value: pkg.duration_value,
      max_athletes: pkg.max_athletes,
      tag: pkg.tag,
      order: pkg.order,
      is_active: pkg.is_active,
      featuresText: (pkg.features || []).join("\n"),
      department: pkg.department ?? null,
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
      price: packageForm.price || packageForm.new_price,
      new_price: packageForm.new_price || packageForm.price,
      renewal_price: packageForm.renewal_price || "0.00",
      package_type: packageForm.package_type,
      duration_type: packageForm.duration_type,
      duration_value: packageForm.duration_value,
      max_athletes: packageForm.max_athletes,
      tag: packageForm.tag,
      order: packageForm.order,
      is_active: packageForm.is_active,
      features,
      department: packageForm.department || null,
    }
  }

  const submitPackage = async (e: FormEvent) => {
    e.preventDefault()
    const nextFieldErrors: Record<string, string> = {}
    if (!packageForm.name.trim()) nextFieldErrors.name = "اسم الباقة مطلوب"

    const priceVal = packageForm.price || packageForm.new_price
    if (!priceVal || Number(priceVal) <= 0) {
      nextFieldErrors.price = "السعر الأساسي مطلوب ويجب أن يكون أكبر من صفر"
    }
    if (packageForm.new_price && Number(packageForm.new_price) < 0) {
      nextFieldErrors.new_price = "سعر الاشتراك الجديد لا يمكن أن يكون سالباً"
    }
    if (packageForm.renewal_price && Number(packageForm.renewal_price) < 0) {
      nextFieldErrors.renewal_price = "سعر التجديد لا يمكن أن يكون سالباً"
    }

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

  const iconMap: Record<string, React.ElementType> = {
    CalendarDays, CalendarRange, Crown,
  }

  const pkgList = (packages || []).map((pkg) => {
    const Icon = iconMap[pkg.icon_name || "CalendarDays"] || CalendarDays
    const newPriceNum = Number(pkg.new_price || pkg.price)
    const renewalPriceNum = Number(pkg.renewal_price || pkg.price)
    const isFeatured = pkg.color_class?.includes("featured") || pkg.tag === "special"

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

      <div className="fixed top-[-20%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-primary-container/10 blur-[120px] -z-10 pointer-events-none" />
      <div className="fixed bottom-[-15%] left-[-10%] w-[40vw] h-[40vw] rounded-full bg-secondary/5 blur-[100px] -z-10 pointer-events-none" />

      <motion.div variants={itemVariants} className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold gradient-text">إدارة الباقات</h1>
          <p className="text-muted-foreground mt-1 text-sm">إنشاء وتعديل باقات الاشتراك وأسعارها للجديد والتجديد.</p>
        </div>
        <Can action="packages:create">
          <Button
            size="lg"
            className="w-full md:w-auto bg-primary text-primary-foreground hover:bg-primary/90 shadow-lg shadow-primary/20 hover:shadow-xl hover:shadow-primary/25 rounded-xl font-bold"
            onClick={openCreatePackageModal}
          >
            <PlusCircle className="w-5 h-5" />
            إضافة باقة
          </Button>
        </Can>
      </motion.div>

      <section>
        <motion.div variants={itemVariants} className="section-header mb-6">
          الباقات الحالية
          {deptParam && <span className="text-xs font-bold px-3 py-1 rounded-full bg-primary/10 text-primary mr-3">{packagesData?.count || 0} باقة</span>}
        </motion.div>

        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-[280px] rounded-2xl border border-border/40 bg-white/60 animate-pulse" />
            ))}
          </div>
        ) : pkgList.length === 0 ? (
          <motion.div variants={itemVariants} className="rounded-2xl border-2 border-dashed border-border/60 bg-white/50 p-12 text-center">
            <p className="text-sm font-semibold text-muted-foreground">لا توجد باقات مسجلة. أضف أول باقة من الزر أعلاه.</p>
          </motion.div>
        ) : (
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
                        {!pkg.raw.is_active && (
                          <>
                            <span>•</span>
                            <span className="text-error font-bold">غير مفعلة</span>
                          </>
                        )}
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
                      <div className="flex items-center justify-between gap-1">
                        <span className="text-[10px] text-muted-foreground">{pkg.typeLabel}</span>
                        <Can action="packages:update">
                          <div className="flex items-center gap-1">
                            <Button type="button" variant="ghost" size="xs" className="h-7 text-xs text-muted-foreground hover:text-foreground px-2" onClick={() => openEditPackageModal(pkg.raw)}>
                              <Pencil className="w-3.5 h-3.5 mr-1" /> تعديل
                            </Button>
                            <Button
                              type="button"
                              variant="ghost"
                              size="xs"
                              className="h-7 text-xs text-error hover:text-error px-2"
                              onClick={() => setDeleteTarget(pkg.raw)}
                            >
                              <Trash2 className="w-3.5 h-3.5 mr-1" /> حذف
                            </Button>
                          </div>
                        </Can>
                      </div>
                    </div>
                  </div>
                </motion.div>
              )
            })}
          </div>
        )}
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
        <div className="fixed inset-0 z-50 bg-black/50 p-4 flex items-center justify-center backdrop-blur-sm">
          <form
            onSubmit={submitPackage}
            className="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-3xl border border-border bg-card p-6 md:p-8 space-y-6 shadow-2xl relative"
          >
            <div className="flex items-center justify-between border-b border-border/20 pb-4">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                  <PlusCircle className="w-5 h-5" />
                </div>
                <h3 className="text-xl font-extrabold text-foreground">
                  {editingPackageId ? "تعديل الباقة" : "إضافة باقة جديدة"}
                </h3>
              </div>
              <button
                type="button"
                onClick={closePackageModal}
                aria-label="إغلاق"
                className="text-muted-foreground hover:text-foreground transition-colors p-1 rounded-lg hover:bg-surface-container"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label htmlFor="package-name" className="mb-1.5 block text-xs font-bold text-muted-foreground">اسم الباقة <span className="text-error">*</span></label>
                  <input
                    id="package-name"
                    value={packageForm.name}
                    onChange={(e) => {
                      setPackageForm((prev) => ({ ...prev, name: e.target.value }))
                      setPackageFieldErrors((prev) => ({ ...prev, name: "" }))
                    }}
                    placeholder="مثال: الباقة الذهبية السنوية"
                    className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                  />
                  {packageFieldErrors.name && <p className="mt-1 text-[11px] text-error font-medium">{packageFieldErrors.name}</p>}
                </div>

                <div>
                  <label htmlFor="package-department" className="mb-1.5 block text-xs font-bold text-muted-foreground">الأكاديمية المتاحة لها</label>
                  <select
                    id="package-department"
                    value={packageForm.department ?? ""}
                    onChange={(e) => setPackageForm((prev) => ({ ...prev, department: e.target.value ? Number(e.target.value) : null }))}
                    disabled={!!deptParam}
                    className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all cursor-pointer disabled:opacity-75 disabled:cursor-not-allowed"
                  >
                    <option value="">جميع الأكاديميات (باقة عامة)</option>
                    {departments.map((d) => (
                      <option key={d.id} value={d.id}>{d.name_ar}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="p-4 rounded-2xl border border-border/40 bg-surface-container-lowest/50 space-y-4">
                <p className="text-xs font-bold text-primary">إعدادات التسعير (د.ل)</p>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label htmlFor="package-new-price" className="mb-1.5 block text-xs font-bold text-muted-foreground">سعر الاشتراك الجديد (أول مرة) <span className="text-error">*</span></label>
                    <div className="relative">
                      <input
                        id="package-new-price"
                        value={packageForm.new_price}
                        onChange={(e) => {
                          const val = e.target.value
                          setPackageForm((prev) => ({ ...prev, new_price: val, price: val }))
                          setPackageFieldErrors((prev) => ({ ...prev, price: "" }))
                        }}
                        type="number"
                        min="0"
                        step="0.01"
                        placeholder="0.00"
                        className="w-full bg-surface-container-low border border-border rounded-xl pl-10 pr-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                      />
                      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs text-muted-foreground font-semibold">د.ل</span>
                    </div>
                    {packageFieldErrors.price && <p className="mt-1 text-[11px] text-error font-medium">{packageFieldErrors.price}</p>}
                  </div>

                  <div>
                    <label htmlFor="package-renewal-price" className="mb-1.5 block text-xs font-bold text-muted-foreground">سعر التجديد (اختياري)</label>
                    <div className="relative">
                      <input
                        id="package-renewal-price"
                        value={packageForm.renewal_price}
                        onChange={(e) => {
                          setPackageForm((prev) => ({ ...prev, renewal_price: e.target.value }))
                          setPackageFieldErrors((prev) => ({ ...prev, renewal_price: "" }))
                        }}
                        type="number"
                        min="0"
                        step="0.01"
                        placeholder="0.00"
                        className="w-full bg-surface-container-low border border-border rounded-xl pl-10 pr-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                      />
                      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs text-muted-foreground font-semibold">د.ل</span>
                    </div>
                    {packageFieldErrors.renewal_price && <p className="mt-1 text-[11px] text-error font-medium">{packageFieldErrors.renewal_price}</p>}
                  </div>
                </div>
              </div>

              <div>
                <label htmlFor="package-description" className="mb-1.5 block text-xs font-bold text-muted-foreground">وصف الباقة</label>
                <textarea
                  id="package-description"
                  value={packageForm.description}
                  onChange={(e) => setPackageForm((prev) => ({ ...prev, description: e.target.value }))}
                  rows={2}
                  placeholder="اكتب وصفاً موجزاً للباقة وما تغطيه..."
                  className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all resize-none"
                />
              </div>

              <div className="p-4 rounded-2xl border border-border/40 bg-surface-container-lowest/50 space-y-4">
                <p className="text-xs font-bold text-primary">المدة والخصائص للرياضيين</p>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <label htmlFor="package-duration-type" className="mb-1.5 block text-xs font-bold text-muted-foreground">وحدة المدة</label>
                    <select
                      id="package-duration-type"
                      value={packageForm.duration_type}
                      onChange={(e) => setPackageForm((prev) => ({ ...prev, duration_type: e.target.value as "days" | "weeks" | "months" }))}
                      className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all cursor-pointer"
                    >
                      <option value="days">أيام</option>
                      <option value="weeks">أسابيع</option>
                      <option value="months">أشهر</option>
                    </select>
                  </div>

                  <div>
                    <label htmlFor="package-duration" className="mb-1.5 block text-xs font-bold text-muted-foreground">عدد الفترات <span className="text-error">*</span></label>
                    <input
                      id="package-duration"
                      type="number"
                      min="1"
                      value={packageForm.duration_value}
                      onChange={(e) => {
                        setPackageForm((prev) => ({ ...prev, duration_value: Number(e.target.value) || 1 }))
                        setPackageFieldErrors((prev) => ({ ...prev, duration_value: "" }))
                      }}
                      placeholder="مثال: 3"
                      className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                    />
                    {packageFieldErrors.duration_value && <p className="mt-1 text-[11px] text-error font-medium">{packageFieldErrors.duration_value}</p>}
                  </div>

                  <div>
                    <label htmlFor="package-max-athletes" className="mb-1.5 block text-xs font-bold text-muted-foreground">عدد الرياضيين <span className="text-error">*</span></label>
                    <input
                      id="package-max-athletes"
                      type="number"
                      min="1"
                      value={packageForm.max_athletes}
                      onChange={(e) => {
                        setPackageForm((prev) => ({ ...prev, max_athletes: Number(e.target.value) || 1 }))
                        setPackageFieldErrors((prev) => ({ ...prev, max_athletes: "" }))
                      }}
                      placeholder="مثال: 1"
                      className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                    />
                    {packageFieldErrors.max_athletes && <p className="mt-1 text-[11px] text-error font-medium">{packageFieldErrors.max_athletes}</p>}
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
                <div>
                  <label htmlFor="package-tag" className="mb-1.5 block text-xs font-bold text-muted-foreground">وسم الباقة</label>
                  <select
                    id="package-tag"
                    value={packageForm.tag}
                    onChange={(e) => setPackageForm((prev) => ({ ...prev, tag: e.target.value as "discount" | "special" | "normal" }))}
                    className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all cursor-pointer"
                  >
                    <option value="normal">عادي</option>
                    <option value="special">مميز (الأكثر طلباً)</option>
                    <option value="discount">خصم</option>
                  </select>
                </div>

                <div>
                  <label htmlFor="package-order" className="mb-1.5 block text-xs font-bold text-muted-foreground">ترتيب الظهور</label>
                  <input
                    id="package-order"
                    type="number"
                    min="0"
                    value={packageForm.order}
                    onChange={(e) => {
                      setPackageForm((prev) => ({ ...prev, order: Number(e.target.value) || 0 }))
                      setPackageFieldErrors((prev) => ({ ...prev, order: "" }))
                    }}
                    className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                  />
                  {packageFieldErrors.order && <p className="mt-1 text-[11px] text-error font-medium">{packageFieldErrors.order}</p>}
                </div>

                <div className="flex items-center h-10 pr-2">
                  <label className="flex items-center gap-2.5 cursor-pointer select-none text-sm font-semibold">
                    <input
                      type="checkbox"
                      checked={packageForm.is_active}
                      onChange={(e) => setPackageForm((prev) => ({ ...prev, is_active: e.target.checked }))}
                      className="w-4.5 h-4.5 accent-primary rounded cursor-pointer"
                    />
                    الباقة مفعلة ونشطة
                  </label>
                </div>
              </div>

              <div>
                <label htmlFor="package-features" className="mb-1.5 block text-xs font-bold text-muted-foreground">ميزات الباقة (كل سطر = ميزة منفصلة)</label>
                <textarea
                  id="package-features"
                  value={packageForm.featuresText}
                  onChange={(e) => setPackageForm((prev) => ({ ...prev, featuresText: e.target.value }))}
                  rows={3}
                  placeholder="مثال:&#10;دخول غير محدود لصالة الرياضة&#10;جلسة تدريب خاصة واحدة شهرياً"
                  className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                />
              </div>
            </div>

            {packageError && <p className="text-xs text-error font-bold">{packageError}</p>}

            <div className="flex justify-end gap-3 border-t border-border/20 pt-4">
              <Button type="button" variant="ghost" onClick={closePackageModal}>إلغاء</Button>
              <Button type="submit" disabled={packageSubmitting} className="bg-primary text-primary-foreground hover:bg-primary/95 px-5">
                {packageSubmitting ? "جارٍ الحفظ..." : "حفظ الباقة"}
              </Button>
            </div>
          </form>
        </div>
      )}
    </motion.div>
  )
}
