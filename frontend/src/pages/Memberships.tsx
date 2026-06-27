import React, { useState } from "react"
import { motion, type Variants } from "framer-motion"
import {
  CalendarDays,
  CalendarRange,
  Crown,
  CheckCircle2,
  Search,
  Filter,
  MoreVertical,
  PlusCircle,
  ChevronLeft,
  ChevronRight,
} from "lucide-react"
import { useSubscriptions } from "@/lib/hooks/useSubscriptions"
import { usePackages } from "@/lib/hooks/usePackages"
import { Button } from "@/components/ui/button"
import { Link } from "react-router-dom"

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
}

const paymentMethods: Record<string, { label: string; icon: string }> = {
  credit_card: { label: "بطاقة ائتمان", icon: "💳" },
  bank_transfer: { label: "تحويل بنكي", icon: "🏦" },
  cash: { label: "نقدي", icon: "💰" },
  mada: { label: "بطاقة مدى", icon: "💳" },
}

export default function MembershipsPage() {
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("")
  const [page, setPage] = useState(1)

  const { data, isLoading } = useSubscriptions({
    page,
    page_size: 20,
    search: search || undefined,
    status: statusFilter || undefined,
  })

  const { data: packagesData } = usePackages()
  const packages = packagesData?.results ?? []

  const subscriptions = data?.results || []
  const totalPages = data ? Math.ceil(data.count / 20) : 0

  const formatDate = (d: string) =>
    new Date(d).toLocaleDateString("ar-SA", { year: "numeric", month: "numeric", day: "numeric" })

  const iconMap: Record<string, React.ElementType> = {
    CalendarDays, CalendarRange, Crown,
  }

  const pkgList = (packages || []).map((pkg) => {
    const Icon = iconMap[pkg.icon_name] || CalendarDays
    const priceNum = Number(pkg.price)
    const monthly = Math.round(priceNum / (pkg.duration_days / 30))
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

  return (
    <motion.div className="space-y-8" dir="rtl" variants={containerVariants} initial="hidden" animate="visible">
      {/* ── Ambient Background ── */}
      <div className="fixed top-[-20%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-primary-container/10 blur-[120px] -z-10 pointer-events-none" />
      <div className="fixed bottom-[-15%] left-[-10%] w-[40vw] h-[40vw] rounded-full bg-secondary/5 blur-[100px] -z-10 pointer-events-none" />

      <motion.div variants={itemVariants} className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold gradient-text">إدارة الاشتراكات</h1>
          <p className="text-muted-foreground mt-1 text-sm">تجديد، متابعة، وإدارة الباقات المالية للاعبين.</p>
        </div>
        <Link to="/dashboard/athletes/add">
          <Button size="lg" className="bg-primary text-primary-foreground hover:bg-primary/90 shadow-lg shadow-primary/20 hover:shadow-xl hover:shadow-primary/25">
            <PlusCircle className="w-5 h-5" />
            اشتراك جديد
          </Button>
        </Link>
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

                  <button
                    onClick={() => alert('سيتم تفعيل التجديد قريباً')}
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
        </div>
      </section>

      {/* ── Subscriptions Table ── */}
      <section>
        <motion.div variants={itemVariants} className="section-header mb-6">
          سجل الاشتراكات
        </motion.div>

        <motion.div variants={itemVariants} className="glass-card rounded-2xl p-4 mb-6">
          <div className="flex flex-col lg:flex-row gap-3">
            <div className="relative flex-1">
              <Search className="absolute right-3.5 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 pointer-events-none" />
              <input
                type="text"
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(1) }}
                className="bg-surface-container-low border border-outline-variant/30 text-foreground text-sm rounded-xl focus:ring-2 focus:ring-primary focus:border-primary block w-full pr-10 p-2.5 outline-none transition-all placeholder:text-muted-foreground/60"
                placeholder="بحث باسم اللاعب أو رقم الهوية..."
              />
            </div>
            <div className="relative">
              <Filter className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 pointer-events-none" />
              <select
                value={statusFilter}
                onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
                className="bg-surface-container-low border border-outline-variant/30 text-foreground text-sm rounded-xl focus:ring-2 focus:ring-primary focus:border-primary block w-full pr-10 p-2.5 outline-none transition-all appearance-none cursor-pointer min-w-[150px]"
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
            <table className="w-full text-right text-sm">
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
                      className="bg-transparent border-b border-outline-variant/20 hover:bg-surface-container-lowest/50 transition-colors group"
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
                        <span className={`inline-flex items-center gap-1.5 text-xs font-bold px-3 py-1 rounded-full ${statusMap[sub.status]?.cls || ""}`}>
                          <span className={`w-1.5 h-1.5 rounded-full ${statusMap[sub.status]?.dot || ""}`} />
                          {statusMap[sub.status]?.label || sub.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-center">
                        <button className="p-1.5 text-muted-foreground hover:text-primary transition-colors rounded-lg hover:bg-surface-container">
                          <MoreVertical className="w-4 h-4" />
                        </button>
                      </td>
                    </motion.tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* ── Pagination ── */}
          <div className="px-6 py-4 flex flex-col sm:flex-row items-center justify-between gap-4 border-t border-outline-variant/20 bg-surface/50">
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
    </motion.div>
  )
}
