
import React, { useState, useRef, useEffect } from "react"
import { motion, type Variants } from "framer-motion"
import {
  CalendarDays,
  CalendarRange,
  Crown,
  CheckCircle2,
  Search,
  Filter,
  MoreVertical,
  CreditCard,
  Banknote,
  Building2,
  PlusCircle,
  ChevronLeft,
  ChevronRight,
} from "lucide-react"
import { useSubscriptions } from "@/lib/hooks/useSubscriptions"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.05, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
}

const statusMap: Record<string, { label: string; cls: string }> = {
  active: { label: "نشط", cls: "bg-[#92f5a4] text-[#007233]" },
  expired: { label: "منتهي", cls: "bg-[#ffdad6] text-[#93000a]" },
  pending: { label: "قيد الانتظار", cls: "bg-amber-500/15 text-amber-600" },
}

export default function MembershipsPage() {
  const [search, setSearch] = useState("")
  const [page, setPage] = useState(1)
  const [activeMenuId, setActiveMenuId] = useState<number | null>(null)
  const menuRef = useRef<HTMLTableCellElement>(null)

  const { data, isLoading } = useSubscriptions({ page, page_size: 20, search: search || undefined })

  const subscriptions = data?.results || []
  const totalPages = data ? Math.ceil(data.count / 20) : 0

  const formatDate = (d: string) =>
    new Date(d).toLocaleDateString("ar-SA", { year: "numeric", month: "numeric", day: "numeric" })

  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setActiveMenuId(null)
      }
    }
    document.addEventListener("mousedown", handleClick)
    return () => document.removeEventListener("mousedown", handleClick)
  }, [])

  const packages = [
    { id: 1, title: "شهر واحد", price: "150", icon: CalendarDays, badge: "شائع", badgeClass: "bg-[#92f5a4] text-[#007233]", features: ["دخول يومي للمرافق", "حصة تدريبية واحدة"], featured: false },
    { id: 2, title: "3 أشهر", price: "400", icon: CalendarRange, badge: "توفير 10%", badgeClass: "bg-[#ffddb8] text-[#653e00]", features: ["جميع مميزات الشهر", "تقييم بدني شهري"], featured: true },
    { id: 3, title: "6 أشهر", price: "750", icon: CalendarRange, badge: "توفير 15%", badgeClass: "bg-surface-variant text-on-surface-variant", features: ["دخول حصص جماعية", "برنامج غذائي مبدئي"], featured: false },
    { id: 4, title: "12 شهر", price: "1,200", icon: Crown, badge: "الأفضل قيمة", badgeClass: "bg-[#ffddb8] text-[#2a1700]", features: ["جميع المميزات", "تجميد الاشتراك (شهر)"], featured: false },
  ]

  return (
    <motion.div className="space-y-8" dir="rtl" variants={containerVariants} initial="hidden" animate="visible">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-3xl font-bold text-foreground">إدارة الاشتراكات</h2>
          <p className="text-muted-foreground mt-1 text-sm">تجديد، متابعة، وإدارة الباقات المالية للاعبين.</p>
        </div>
        <button className="flex items-center gap-2 bg-primary text-white px-6 py-3 rounded-full text-sm font-semibold hover:bg-primary/90 transition-all shadow-md hover:shadow-lg hover:-translate-y-0.5">
          <PlusCircle className="w-5 h-5" />
          اشتراك جديد
        </button>
      </div>

      <section>
        <h3 className="text-xl font-bold text-foreground mb-4">باقات التجديد السريع</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
          {packages.map((pkg) => {
            const Icon = pkg.icon
            return (
              <motion.div key={pkg.id} variants={itemVariants} className={`relative rounded-2xl p-6 flex flex-col hover:-translate-y-1 transition-all duration-300 overflow-hidden ${
                pkg.featured
                  ? "bg-gradient-to-br from-primary to-primary/80 text-white shadow-xl shadow-primary/30"
                  : "bg-white/70 backdrop-blur-md border border-white/50 shadow-lg shadow-primary/5"
              }`}>
                {pkg.featured && <div className="absolute -right-8 -top-8 w-28 h-28 bg-white/10 rounded-full blur-2xl pointer-events-none" />}
                <div className="flex justify-between items-start mb-4 relative z-10">
                  <div className={`p-2 rounded-lg ${pkg.featured ? "bg-white/20" : "bg-surface-container-high"}`}>
                    <Icon className={`w-5 h-5 ${pkg.featured ? "text-white" : "text-primary"}`} />
                  </div>
                  <span className={`text-xs font-bold px-2 py-1 rounded-full ${pkg.featured ? "bg-white/20 text-white" : pkg.badgeClass}`}>
                    {pkg.badge}
                  </span>
                </div>
                <h4 className={`text-lg font-bold relative z-10 ${pkg.featured ? "text-white" : "text-foreground"}`}>{pkg.title}</h4>
                <div className="mt-2 mb-4 relative z-10">
                  <span className={`text-3xl font-extrabold ${pkg.featured ? "text-white" : "text-primary"}`}>{pkg.price}</span>
                  <span className={`text-sm mr-1 ${pkg.featured ? "text-white/80" : "text-muted-foreground"}`}>د.ل</span>
                </div>
                <ul className="space-y-2 mb-5 flex-1 relative z-10">
                  {pkg.features.map((f, i) => (
                    <li key={i} className={`flex items-center gap-2 text-xs ${pkg.featured ? "text-white/90" : "text-muted-foreground"}`}>
                      <CheckCircle2 className={`w-4 h-4 ${pkg.featured ? "text-white" : "text-[#006d30]"}`} />
                      {f}
                    </li>
                  ))}
                </ul>
                <button className={`w-full py-2.5 rounded-xl text-sm font-bold transition-all relative z-10 ${
                  pkg.featured ? "bg-white text-primary hover:bg-white/90" : "bg-surface-container border border-primary/20 text-primary hover:bg-primary hover:text-white"
                }`}>
                  تجديد سريع
                </button>
              </motion.div>
            )
          })}
        </div>
      </section>

      <section className="flex flex-col">
        <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center mb-4 gap-4">
          <h3 className="text-xl font-bold text-foreground">سجل الاشتراكات</h3>
          <div className="flex flex-wrap items-center gap-3 w-full lg:w-auto">
            <div className="relative flex-1 lg:w-72">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 pointer-events-none" />
              <input
                type="text"
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(1) }}
                className="bg-surface-container-low border border-border/40 text-foreground text-sm rounded-xl focus:ring-2 focus:ring-primary focus:border-primary block w-full pr-10 p-2.5 outline-none transition-all"
                placeholder="بحث باسم اللاعب أو رقم العضوية..."
              />
            </div>
          </div>
        </div>

        <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl overflow-hidden shadow-lg shadow-primary/5">
          <div className="overflow-x-auto">
            <table className="w-full text-right text-sm">
              <thead className="text-xs text-muted-foreground uppercase bg-surface-container/50 border-b border-border/30">
                <tr>
                  <th scope="col" className="px-6 py-4 font-bold">اللاعب</th>
                  <th scope="col" className="px-6 py-4 font-bold">رقم العضوية</th>
                  <th scope="col" className="px-6 py-4 font-bold">تاريخ البدء</th>
                  <th scope="col" className="px-6 py-4 font-bold">تاريخ الانتهاء</th>
                  <th scope="col" className="px-6 py-4 font-bold">المبلغ</th>
                  <th scope="col" className="px-6 py-4 font-bold">الحالة</th>
                  <th scope="col" className="px-6 py-4 font-bold text-center">إجراءات</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center text-muted-foreground">
                      <div className="animate-spin w-6 h-6 border-2 border-primary border-t-transparent rounded-full mx-auto" />
                    </td>
                  </tr>
                ) : subscriptions.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center text-muted-foreground">لا توجد نتائج</td>
                  </tr>
                ) : (
                  subscriptions.map((sub) => (
                    <motion.tr key={sub.id} variants={itemVariants} className="bg-transparent border-b border-border/20 hover:bg-surface-container-low/50 transition-colors">
                      <td className="px-6 py-4 font-medium text-foreground">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-surface-variant flex items-center justify-center text-primary font-bold text-xs shrink-0">
                            {sub.athlete_name.charAt(0)}
                          </div>
                          {sub.athlete_name}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-muted-foreground font-mono text-xs">{sub.membership_number}</td>
                      <td className="px-6 py-4 text-muted-foreground">{formatDate(sub.start_date)}</td>
                      <td className={`px-6 py-4 font-semibold ${
                        sub.status === "expired" ? "text-[#ba1a1a]" : sub.status === "pending" ? "text-amber-600" : "text-muted-foreground"
                      }`}>{formatDate(sub.end_date)}</td>
                      <td className="px-6 py-4 font-bold text-foreground">{Number(sub.amount).toLocaleString("ar-SA")} د.ل</td>
                      <td className="px-6 py-4">
                        <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${statusMap[sub.status]?.cls || ""}`}>
                          {statusMap[sub.status]?.label || sub.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-center relative" ref={menuRef}>
                        <button
                          onClick={() => setActiveMenuId(activeMenuId === sub.id ? null : sub.id)}
                          className="p-1 text-primary hover:text-primary/70 transition-colors rounded-lg hover:bg-surface-container"
                        >
                          <MoreVertical className="w-5 h-5" />
                        </button>
                        {activeMenuId === sub.id && (
                          <div className="absolute left-4 top-full z-50 mt-1 w-40 bg-white rounded-xl border border-border/40 shadow-xl py-1">
                            <button className="w-full text-right px-4 py-2 text-sm text-foreground hover:bg-surface-container transition-colors">تجديد</button>
                            <button className="w-full text-right px-4 py-2 text-sm text-foreground hover:bg-surface-container transition-colors">تعديل</button>
                            <button className="w-full text-right px-4 py-2 text-sm text-[#ba1a1a] hover:bg-[#ffdad6] transition-colors">إلغاء</button>
                          </div>
                        )}
                      </td>
                    </motion.tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <div className="px-6 py-4 flex items-center justify-between border-t border-border/20 bg-white/50">
            <span className="text-xs text-muted-foreground">عرض {subscriptions.length} من أصل {data?.count || 0} اشتراك</span>
            <div className="flex gap-1">
              <button onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1} className="p-1.5 rounded-md text-muted-foreground hover:bg-surface-container transition-colors disabled:opacity-40">
                <ChevronRight className="w-4 h-4" />
              </button>
              {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => i + 1).map((p) => (
                <button key={p} onClick={() => setPage(p)} className={`w-8 h-8 rounded-md text-sm font-semibold transition-colors ${
                  p === page ? "bg-primary text-white" : "text-muted-foreground hover:bg-surface-container"
                }`}>{p}</button>
              ))}
              <button onClick={() => setPage((p) => p + 1)} disabled={page >= totalPages} className="p-1.5 rounded-md text-muted-foreground hover:bg-surface-container transition-colors disabled:opacity-40">
                <ChevronLeft className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </section>
    </motion.div>
  )
}
