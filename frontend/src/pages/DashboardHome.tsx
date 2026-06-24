import React, { useRef, useState, useEffect } from "react"
import { motion, type Variants } from "framer-motion"
import {
  Users, CheckCircle, ShieldAlert, Clock, TrendingUp, TrendingDown,
  Plus, UserPlus, ScanLine, CalendarPlus, ArrowLeft, Sparkles,
} from "lucide-react"
import { Link } from "react-router-dom"
import { Button } from "@/components/ui/button"
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from "recharts"
import { useDashboardStats, useMonthlyGrowth } from "@/lib/hooks/useAnalytics"
import { useAuth } from "@/lib/auth"

function CountUp({ end, duration = 1500 }: { end: number; duration?: number }) {
  const [count, setCount] = useState(0)
  const ref = useRef<HTMLSpanElement>(null)
  const started = useRef(false)

  useEffect(() => {
    if (started.current) return
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !started.current) {
          started.current = true
          const start = performance.now()
          const animate = (now: number) => {
            const elapsed = now - start
            const progress = Math.min(elapsed / duration, 1)
            const eased = 1 - Math.pow(1 - progress, 3)
            setCount(Math.floor(eased * end))
            if (progress < 1) requestAnimationFrame(animate)
          }
          requestAnimationFrame(animate)
        }
      },
      { threshold: 0.3 }
    )
    if (ref.current) observer.observe(ref.current)
    return () => observer.disconnect()
  }, [end, duration])

  return <span ref={ref}>{count.toLocaleString("ar-SA")}</span>
}

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.08, delayChildren: 0.15 },
  },
}

const cardVariants: Variants = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5, ease: [0.22, 1, 0.36, 1] } },
}

export default function DashboardPage() {
  const { user } = useAuth()
  const { data: stats, isLoading: statsLoading } = useDashboardStats()
  const { data: growthData, isLoading: growthLoading } = useMonthlyGrowth()
  const [period, setPeriod] = useState<string>("شهر")

  const statCards = [
    {
      label: "إجمالي اللاعبين",
      value: stats?.total_athletes ?? 0,
      icon: Users,
      iconBg: "bg-primary-container/30 text-primary",
      glow: "shadow-primary/10",
      badge: stats?.new_this_month ? `+${stats.new_this_month} هذا الشهر` : null,
      trend: "up" as const,
    },
    {
      label: "اشتراكات نشطة",
      value: stats?.active_memberships ?? 0,
      icon: CheckCircle,
      iconBg: "bg-secondary-container/30 text-secondary",
      glow: "shadow-secondary/10",
      badge: null,
      trend: "up" as const,
    },
    {
      label: "اشتراكات منتهية",
      value: stats?.expired_memberships ?? 0,
      icon: ShieldAlert,
      iconBg: "bg-error-container/30 text-error",
      glow: "shadow-error/10",
      badge: null,
      trend: "down" as const,
    },
    {
      label: "تنتهي قريباً (7 أيام)",
      value: stats?.expiring_soon ?? 0,
      icon: Clock,
      iconBg: "bg-amber-500/15 text-amber-600",
      glow: "shadow-amber-500/10",
      badge: "تتطلب المتابعة",
      badgeIcon: Sparkles,
      trend: "warning" as const,
    },
  ]

  const chartData = (growthData || []).map((d) => {
    const date = new Date(d.month)
    const months = ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"]
    return { name: months[date.getMonth()], value: d.count }
  })

  const branchData = [
    {
      name: "الأهلي للياقة",
      icon: "🏋️",
      color: "bg-primary",
      revenue: "850,000",
      percentage: 75,
      trend: "+8%",
    },
    {
      name: "أكاديمية العوز",
      icon: "⚽",
      color: "bg-tertiary-container",
      revenue: "420,000",
      percentage: 45,
      trend: "+12%",
    },
  ]

  const recentAthletes = [
    { name: "عمر عبدالله", id: "#4592", date: "12 مايو 2024", sport: "كرة القدم - العوز", package: "احترافي 6 شهور", status: "نشط" as const },
    { name: "سارة محمد", id: "#4591", date: "11 مايو 2024", sport: "لياقة بدنية - الأهلي", package: "أساسي 3 شهور", status: "نشط" as const },
    { name: "خالد سعيد", id: "#4590", date: "10 مايو 2024", sport: "سباحة - الأهلي", package: "شهر واحد", status: "قيد المراجعة" as const },
  ]

  const statusBadge = (status: string) => {
    const styles: Record<string, string> = {
      "نشط": "bg-secondary-container/30 text-secondary",
      "منتهي": "bg-error-container/30 text-error",
      "قيد المراجعة": "bg-tertiary-container/30 text-on-tertiary-container",
    }
    const dots: Record<string, string> = {
      "نشط": "bg-secondary",
      "منتهي": "bg-error",
      "قيد المراجعة": "bg-tertiary",
    }
    return (
      <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold ${styles[status] || "bg-surface-container-high text-muted-foreground"}`}>
        <span className={`w-1.5 h-1.5 rounded-full ${dots[status] || "bg-muted-foreground"}`} />
        {status}
      </span>
    )
  }

  return (
    <motion.div
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="space-y-6 select-none"
    >
      {/* ── Header ── */}
      <motion.div variants={cardVariants} className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
        <div>
          <h1 className="text-3xl font-extrabold flex items-center gap-3">
            <span>مرحباً بك</span>
            <span className="gradient-text">، {user?.full_name_ar || "المسؤول"}</span>
            <span className="w-2 h-2 rounded-full bg-primary animate-pulse-soft" />
          </h1>
          <p className="text-muted-foreground mt-2 text-sm">
            إليك نظرة عامة على أداء الأكاديمية اليوم.
          </p>
        </div>
        <Link to="/dashboard/athletes/add">
          <motion.button whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.97 }}
            className="bg-gradient-to-r from-primary to-primary-container text-primary-foreground px-5 py-2.5 rounded-xl text-sm font-semibold shadow-lg shadow-primary/20 flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            إضافة لاعب جديد
          </motion.button>
        </Link>
      </motion.div>

      {/* ── Glass KPI Cards ── */}
      <motion.div variants={cardVariants} className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {statCards.map((card, idx) => {
          const Icon = card.icon
          const BadgeIcon = card.badgeIcon
          return (
            <motion.div
              key={idx}
              whileHover={{ y: -4, transition: { duration: 0.2 } }}
              className="glass-card rounded-2xl p-6 relative overflow-hidden group"
            >
              <div className="absolute -left-6 -top-6 w-24 h-24 rounded-full blur-xl opacity-60 group-hover:opacity-100 transition-opacity bg-primary/5" />
              <div className="flex justify-between items-start mb-4">
                <span className="text-sm font-medium text-muted-foreground">{card.label}</span>
                <div className={`w-10 h-10 rounded-full ${card.iconBg} flex items-center justify-center shadow-sm`}>
                  <Icon className="w-5 h-5" />
                </div>
              </div>
              <div className="text-3xl font-extrabold text-foreground tracking-tight">
                {statsLoading ? (
                  <span className="animate-pulse bg-muted rounded w-20 h-9 inline-block" />
                ) : (
                  <CountUp end={card.value} />
                )}
              </div>
              {card.badge && (
                <div className="flex items-center gap-1.5 mt-3 text-xs font-semibold text-muted-foreground">
                  {BadgeIcon && <BadgeIcon className="w-3.5 h-3.5 text-primary" />}
                  <span>{card.badge}</span>
                  {String(card.trend) === "up" && <TrendingUp className="w-3.5 h-3.5 text-emerald-500" />}
                  {String(card.trend) === "down" && <TrendingDown className="w-3.5 h-3.5 text-rose-500" />}
                </div>
              )}
            </motion.div>
          )
        })}
      </motion.div>

      {/* ── Quick Actions ── */}
      <motion.div variants={cardVariants}>
        <div className="flex items-center gap-2 mb-4">
          <h2 className="section-header">إجراءات سريعة</h2>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <Link to="/dashboard/athletes/add">
            <Button size="lg"
              className="w-full relative overflow-hidden rounded-2xl bg-gradient-to-br from-violet-500/10 to-violet-500/5 dark:from-violet-500/15 dark:to-violet-500/5 border border-violet-500/20 hover:border-violet-500/40 p-5 flex items-center gap-4 transition-all group justify-start h-auto"
            >
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center shadow-lg shadow-violet-500/30 text-white">
                <UserPlus className="w-5 h-5" />
              </div>
              <div className="text-right flex-1">
                <p className="font-bold text-foreground">إضافة لاعب</p>
                <p className="text-xs text-muted-foreground mt-0.5">تسجيل رياضي جديد في النظام</p>
              </div>
              <ArrowLeft className="w-4 h-4 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity shrink-0" />
            </Button>
          </Link>
          <Link to="/dashboard/memberships">
            <Button size="lg"
              className="w-full relative overflow-hidden rounded-2xl bg-gradient-to-br from-emerald-500/10 to-emerald-500/5 dark:from-emerald-500/15 dark:to-emerald-500/5 border border-emerald-500/20 hover:border-emerald-500/40 p-5 flex items-center gap-4 transition-all group justify-start h-auto"
            >
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center shadow-lg shadow-emerald-500/30 text-white">
                <CalendarPlus className="w-5 h-5" />
              </div>
              <div className="text-right flex-1">
                <p className="font-bold text-foreground">اشتراك جديد</p>
                <p className="text-xs text-muted-foreground mt-0.5">إضافة اشتراك للاعب موجود</p>
              </div>
              <ArrowLeft className="w-4 h-4 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity shrink-0" />
            </Button>
          </Link>
          <Link to="/dashboard/verify">
            <Button size="lg"
              className="w-full relative overflow-hidden rounded-2xl bg-gradient-to-br from-amber-500/10 to-amber-500/5 dark:from-amber-500/15 dark:to-amber-500/5 border border-amber-500/20 hover:border-amber-500/40 p-5 flex items-center gap-4 transition-all group justify-start h-auto"
            >
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center shadow-lg shadow-amber-500/30 text-white">
                <ScanLine className="w-5 h-5" />
              </div>
              <div className="text-right flex-1">
                <p className="font-bold text-foreground">مسح QR</p>
                <p className="text-xs text-muted-foreground mt-0.5">التحقق من العضوية عبر الكود</p>
              </div>
              <ArrowLeft className="w-4 h-4 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity shrink-0" />
            </Button>
          </Link>
        </div>
      </motion.div>

      {/* ── Bento Grid: Chart + Branch Performance ── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Monthly Growth — AreaChart, spans 2 cols */}
        <motion.div variants={cardVariants} className="lg:col-span-2 glass-card rounded-3xl p-6 min-h-[400px] group">
          <div className="flex justify-between items-center mb-6">
            <h2 className="section-header">نمو الاشتراكات الشهرية</h2>
            <div className="flex gap-2">
              {["أسبوع", "شهر", "سنة"].map((p) => (
                <button
                  key={p}
                  onClick={() => setPeriod(p)}
                  className={`px-3 py-1 rounded-full text-xs font-semibold transition-all ${
                    period === p
                      ? "bg-primary text-primary-foreground shadow-sm"
                      : "bg-surface-container-low text-muted-foreground hover:bg-white"
                  }`}
                >
                  {p}
                </button>
              ))}
            </div>
          </div>
          <div className="w-full min-h-[280px]">
            {growthLoading ? (
              <div className="h-[280px] flex items-center justify-center">
                <div className="animate-spin w-6 h-6 border-2 border-primary border-t-transparent rounded-full" />
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="growthGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="var(--primary)" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" opacity={0.5} />
                  <XAxis dataKey="name" stroke="var(--outline)" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="var(--outline)" fontSize={12} tickLine={false} axisLine={false} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: "var(--card)",
                      borderColor: "var(--border)",
                      borderRadius: "12px",
                      boxShadow: "0 8px 32px rgba(0,0,0,0.1)",
                      padding: "8px 14px",
                    }}
                    labelStyle={{ fontWeight: "bold", marginBottom: 4 }}
                  />
                  <Area
                    type="monotone"
                    dataKey="value"
                    stroke="var(--primary)"
                    strokeWidth={3}
                    fill="url(#growthGradient)"
                    dot={false}
                    activeDot={{ r: 6, fill: "var(--primary)", stroke: "white", strokeWidth: 2 }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </div>
        </motion.div>

        {/* Branch Performance */}
        <motion.div variants={cardVariants} className="glass-card rounded-3xl p-6 flex flex-col gap-6">
          <h2 className="section-header">أداء الفروع</h2>
          {branchData.map((branch, idx) => (
            <div
              key={idx}
              className="p-4 rounded-2xl bg-surface-container-lowest border border-outline-variant/30 hover:border-primary/50 transition-colors"
            >
              <div className="flex justify-between items-center mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center text-primary text-sm">
                    {branch.icon}
                  </div>
                  <span className="text-sm font-bold text-foreground">{branch.name}</span>
                </div>
                <span className="bg-secondary/10 text-secondary px-2 py-0.5 rounded text-[11px] font-semibold">
                  {branch.trend}
                </span>
              </div>
              <div className="space-y-2">
                <div className="flex justify-between text-sm text-muted-foreground">
                  <span>الإيرادات</span>
                  <span className="text-foreground font-semibold">{branch.revenue} د.ل</span>
                </div>
                <div className="w-full bg-surface-variant rounded-full h-1.5 overflow-hidden">
                  <div className={`${branch.color} h-full rounded-full transition-all duration-700`} style={{ width: `${branch.percentage}%` }} />
                </div>
              </div>
            </div>
          ))}
          <Button variant="outline" size="lg"
            className="mt-auto w-full py-3 rounded-xl border-border/60 text-sm font-semibold text-muted-foreground hover:bg-surface-container hover:text-primary"
          >
            عرض التفاصيل
          </Button>
        </motion.div>
      </div>

      {/* ── Recent Registrations Table ── */}
      <motion.div variants={cardVariants} className="glass-card rounded-3xl p-6">
        <div className="flex justify-between items-center mb-6">
          <h2 className="section-header">التسجيلات الحديثة</h2>
          <Link to="/dashboard/athletes">
            <Button variant="ghost" size="xs" className="text-sm font-semibold text-primary">
              عرض الكل
              <ArrowLeft className="w-3 h-3 mr-1" />
            </Button>
          </Link>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-right">
            <thead>
              <tr className="border-b border-outline-variant/20 text-muted-foreground text-xs font-semibold">
                <th className="pb-4 pl-4 font-medium">اللاعب</th>
                <th className="pb-4 pl-4 font-medium">تاريخ التسجيل</th>
                <th className="pb-4 pl-4 font-medium">الفرع / الرياضة</th>
                <th className="pb-4 pl-4 font-medium">الباقة</th>
                <th className="pb-4 font-medium">الحالة</th>
              </tr>
            </thead>
            <tbody className="text-sm text-foreground">
              {recentAthletes.map((a, i) => (
                <tr
                  key={i}
                  className="border-b border-outline-variant/10 hover:bg-surface-container-low/50 transition-colors"
                >
                  <td className="py-4 pl-4">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full bg-surface-variant flex items-center justify-center text-primary font-bold text-xs">
                        {a.name.charAt(0)}
                      </div>
                      <div>
                        <div className="font-semibold text-sm">{a.name}</div>
                        <div className="text-[11px] text-muted-foreground">{a.id}</div>
                      </div>
                    </div>
                  </td>
                  <td className="py-4 pl-4 text-muted-foreground text-xs">{a.date}</td>
                  <td className="py-4 pl-4 text-xs">{a.sport}</td>
                  <td className="py-4 pl-4 text-xs font-semibold">{a.package}</td>
                  <td className="py-4">{statusBadge(a.status)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </motion.div>
    </motion.div>
  )
}
