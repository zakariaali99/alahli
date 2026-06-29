import React from "react"
import { motion, type Variants } from "framer-motion"
import { useParams } from "react-router-dom"
import { Link } from "react-router-dom"
import {
  ChevronLeft, Edit, RefreshCw, Printer, Shield,
  Calendar, Award, Receipt, Users, Activity,
  CreditCard, Hash, Clock, BadgeCheck,
  Phone, User, Briefcase,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { useAthlete } from "@/lib/hooks/useAthletes"
import { useSubscriptions } from "@/lib/hooks/useSubscriptions"
import { useToast } from "@/lib/toast"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.08, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
}

export default function AthleteProfilePage() {
  const toast = useToast()
  const params = useParams()
  const id = Number(params.id)
  const isValidId = !isNaN(id) && id > 0
  const { data: athlete, isLoading } = useAthlete(isValidId ? id : 0)
  const { data: subsData } = useSubscriptions(isValidId ? { athlete: String(id) } : {})

  if (isNaN(id) || id <= 0) {
    return (
      <div className="text-center py-20 text-muted-foreground">
        لم يتم العثور على اللاعب
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!athlete) {
    return (
      <div className="text-center py-20 text-muted-foreground">
        لم يتم العثور على اللاعب
      </div>
    )
  }

  const subscriptions = subsData?.results || []
  const activeSub = subscriptions.find((s) => s.status === "active")
  const subs = activeSub || subscriptions[0]

  const formatDate = (d: string) =>
    new Date(d).toLocaleDateString("ar-SA-u-nu-latn", { year: "numeric", month: "long", day: "numeric" })

  const calcPercent = (start: string, end: string) => {
    const s = new Date(start).getTime()
    const e = new Date(end).getTime()
    const now = Date.now()
    if (now >= e) return 100
    if (now <= s) return 0
    return Math.round(((now - s) / (e - s)) * 100)
  }

  const calcDaysRemaining = (end: string) => {
    const diff = new Date(end).getTime() - Date.now()
    return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)))
  }

  const genderLabel = athlete.gender === "male" ? "ذكر" : "أنثى"

  const activeCount = subscriptions.filter((s) => s.status === "active").length
  const daysRemaining = subs ? calcDaysRemaining(subs.end_date) : 0
  const totalRenewals = subscriptions.reduce((acc, s) => acc + (s.renewals?.length || 0), 0)

  const membershipStart = subscriptions.length > 0
    ? new Date(Math.min(...subscriptions.map((s) => new Date(s.start_date).getTime())))
    : null
  const membershipAgeMonths = membershipStart
    ? Math.floor((Date.now() - membershipStart.getTime()) / (1000 * 60 * 60 * 24 * 30))
    : 0
  const membershipAgeLabel = membershipAgeMonths >= 12
    ? `${Math.floor(membershipAgeMonths / 12)} سنة ${membershipAgeMonths % 12 > 0 ? `و ${membershipAgeMonths % 12} شهور` : ""}`
    : `${membershipAgeMonths} شهور`

  return (
    <motion.div className="space-y-6 select-none print:bg-white print:text-black" variants={containerVariants} initial="hidden" animate="visible">
      <div className="fixed top-0 left-0 w-full h-full overflow-hidden -z-10 pointer-events-none print:hidden">
        <div className="absolute top-[-10%] right-[-5%] w-[40vw] h-[40vw] rounded-full bg-primary/5 blur-3xl" />
        <div className="absolute bottom-[-10%] left-[-5%] w-[30vw] h-[30vw] rounded-full bg-secondary/5 blur-3xl" />
      </div>

      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-2 print:hidden">
        <div className="flex items-center gap-2 text-muted-foreground text-sm font-semibold">
          <Link to="/dashboard/athletes" className="hover:text-primary transition-colors">اللاعبين</Link>
          <ChevronLeft className="w-4 h-4" />
          <span className="text-primary font-bold">ملف اللاعب</span>
        </div>
        <div className="flex items-center gap-3 w-full md:w-auto">
          <Link to={`/dashboard/athletes/add`}>
            <Button variant="outline" size="lg">
              <Edit className="w-4 h-4" />
              تعديل البيانات
            </Button>
          </Link>
          <Link to="/dashboard/memberships">
            <Button size="lg" className="bg-gradient-to-l from-primary to-primary/80 shadow-lg shadow-primary/20">
              <RefreshCw className="w-4 h-4" />
              تجديد الاشتراك
            </Button>
          </Link>
        </div>
      </div>

      <motion.div variants={itemVariants} className="glass-card-premium rounded-[2rem] p-6 md:p-8 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-primary/[0.07] via-transparent to-secondary/[0.07]" />
        <div className="absolute top-0 left-0 w-72 h-72 bg-gradient-to-br from-primary/10 to-transparent rounded-full -translate-x-1/2 -translate-y-1/2 blur-3xl" />
        <div className="absolute bottom-0 right-0 w-56 h-56 bg-gradient-to-tl from-secondary/10 to-transparent rounded-full translate-x-1/3 translate-y-1/3 blur-3xl" />
        <div className="relative z-10 flex flex-col md:flex-row items-center md:items-end gap-6">
          <div className="relative shrink-0">
            <div className="w-28 h-28 md:w-32 md:h-32 rounded-full overflow-hidden border-4 border-white/80 dark:border-surface shadow-xl">
              {athlete.photo ? (
                <img alt={athlete.full_name} src={athlete.photo} className="object-cover w-full h-full" />
              ) : (
                <div className="w-full h-full flex items-center justify-center bg-primary-container/20 text-primary text-4xl font-bold">
                  {athlete.full_name.charAt(0)}
                </div>
              )}
            </div>
            <div className="absolute -bottom-2 -left-2 z-20 bg-secondary-container text-on-secondary-container text-[11px] font-bold px-3 py-1 rounded-full border-2 border-white dark:border-surface-container-high flex items-center gap-1 shadow-sm">
              <span className={`w-2 h-2 rounded-full ${athlete.is_active ? "bg-secondary" : "bg-error"}`} />
              {athlete.is_active ? "نشط" : "غير نشط"}
            </div>
          </div>
          <div className="flex-1 text-center md:text-right pt-2">
            <h1 className="text-2xl md:text-3xl lg:text-4xl font-extrabold gradient-text mb-1">{athlete.full_name}</h1>
            <p className="text-sm text-muted-foreground">{athlete.department_name} <span className="mx-1.5 opacity-40">•</span> {athlete.membership_number}</p>
            <div className="flex flex-wrap justify-center md:justify-start gap-2 mt-4">
              <div className="bg-surface-container-low px-3 py-1.5 rounded-lg border border-border/20 inline-flex items-center gap-1.5 text-xs font-semibold text-foreground">
                <Shield className="w-3.5 h-3.5 text-primary" />
                {genderLabel}
              </div>
              <div className="bg-surface-container-low px-3 py-1.5 rounded-lg border border-border/20 inline-flex items-center gap-1.5 text-xs font-semibold text-foreground">
                <Calendar className="w-3.5 h-3.5 text-primary" />
                {formatDate(athlete.birth_date)}
              </div>
            </div>
          </div>
        </div>
      </motion.div>

      <motion.div variants={itemVariants} className="flex flex-wrap gap-3">
        <div className="bg-surface-container-low backdrop-blur-sm px-4 py-2.5 rounded-xl border border-border/20 flex items-center gap-2.5">
          <Activity className="w-4 h-4 text-primary shrink-0" />
          <div>
            <span className="text-[10px] text-muted-foreground block leading-tight">إجمالي الاشتراكات</span>
            <span className="text-sm font-bold text-foreground">{subscriptions.length}</span>
          </div>
        </div>
        <div className="bg-surface-container-low backdrop-blur-sm px-4 py-2.5 rounded-xl border border-border/20 flex items-center gap-2.5">
          <BadgeCheck className="w-4 h-4 text-secondary shrink-0" />
          <div>
            <span className="text-[10px] text-muted-foreground block leading-tight">النشط منها</span>
            <span className="text-sm font-bold text-foreground">{activeCount}</span>
          </div>
        </div>
        <div className="bg-surface-container-low backdrop-blur-sm px-4 py-2.5 rounded-xl border border-border/20 flex items-center gap-2.5">
          <Clock className="w-4 h-4 text-amber-500 shrink-0" />
          <div>
            <span className="text-[10px] text-muted-foreground block leading-tight">الأيام المتبقية</span>
            <span className="text-sm font-bold text-foreground">{daysRemaining}</span>
          </div>
        </div>
        {membershipStart && (
          <div className="bg-surface-container-low backdrop-blur-sm px-4 py-2.5 rounded-xl border border-border/20 flex items-center gap-2.5">
            <User className="w-4 h-4 text-sky-500 shrink-0" />
            <div>
              <span className="text-[10px] text-muted-foreground block leading-tight">مدة العضوية</span>
              <span className="text-sm font-bold text-foreground">{membershipAgeLabel}</span>
            </div>
          </div>
        )}
        {totalRenewals > 0 && (
          <div className="bg-surface-container-low backdrop-blur-sm px-4 py-2.5 rounded-xl border border-border/20 flex items-center gap-2.5">
            <RefreshCw className="w-4 h-4 text-purple-500 shrink-0" />
            <div>
              <span className="text-[10px] text-muted-foreground block leading-tight">إجمالي التجديدات</span>
              <span className="text-sm font-bold text-foreground">{totalRenewals}</span>
            </div>
          </div>
        )}
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-5 space-y-6">
          <motion.div variants={itemVariants} className="glass-card-premium rounded-[2rem] p-6 flex flex-col items-center text-center relative overflow-hidden group">
            <div className="absolute inset-0 bg-gradient-to-b from-surface-container-highest/20 to-transparent pointer-events-none" />
            <div className="relative z-10 w-full">
              <h3 className="text-base font-bold text-foreground mb-6 pb-2 relative inline-block after:content-[''] after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-12 after:h-[3px] after:rounded-full after:bg-gradient-to-l after:from-primary after:to-transparent">
                الصورة الشخصية
              </h3>
              <div className="w-40 h-40 mx-auto rounded-2xl overflow-hidden border-2 border-border/30 shadow-lg transition-transform duration-300 group-hover:scale-[1.02]">
                {athlete.photo ? (
                  <img alt={athlete.full_name} src={athlete.photo} className="object-cover w-full h-full" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-primary-container/20 text-primary text-5xl font-bold">
                    {athlete.full_name.charAt(0)}
                  </div>
                )}
              </div>
            </div>
          </motion.div>

          <motion.div variants={itemVariants} className="glass-card-premium rounded-[2rem] p-6 flex flex-col items-center text-center relative overflow-hidden group">
            <div className="absolute inset-0 bg-gradient-to-b from-surface-container-highest/20 to-transparent pointer-events-none" />
            <div className="relative z-10 w-full flex flex-col items-center">
              <div className="flex items-center justify-between w-full mb-4">
                <h3 className="text-base font-bold text-foreground">بطاقة العضوية</h3>
                <Button variant="ghost" size="icon-xs" onClick={() => toast.info("طباعة البطاقة غير متوفرة حالياً")}>
                  <Printer className="w-4 h-4" />
                </Button>
              </div>
              <div className="w-full max-w-[260px] bg-gradient-to-br from-primary/90 to-primary/40 rounded-2xl p-5 text-white shadow-xl relative overflow-hidden flex flex-col items-center gap-3 transition-all duration-300 hover:scale-[1.02] hover:shadow-2xl">
                <div className="absolute top-[-20px] left-[-20px] w-24 h-24 bg-white/5 rounded-full blur-xl" />
                <div className="absolute bottom-[-30px] right-[-30px] w-32 h-32 bg-white/[0.03] rounded-full blur-2xl" />
                <div className="flex justify-between items-center w-full pb-2 border-b border-white/10">
                  <span className="text-[10px] uppercase font-bold tracking-wider opacity-85">بطاقة هوية رياضية</span>
                  <Award className="w-4 h-4 text-amber-400" />
                </div>
                <motion.div
                  className="bg-white/10 backdrop-blur-sm p-3 rounded-xl border border-white/20 relative z-10"
                  whileHover={{ scale: 1.04 }}
                  transition={{ type: "spring", stiffness: 300, damping: 15 }}
                >
                  {athlete.qr_code ? (
                    <img alt="QR Code" src={athlete.qr_code} width={120} height={120} className="opacity-90 mix-blend-screen" />
                  ) : (
                    <div className="w-[120px] h-[120px] flex items-center justify-center text-white/60 text-xs">لا يوجد QR</div>
                  )}
                </motion.div>
                <div className="w-full text-center">
                  <div className="text-sm font-bold">{athlete.full_name}</div>
                  <div className="text-[10px] opacity-75 mt-1 font-mono tracking-widest">{athlete.membership_number}</div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        <div className="lg:col-span-7 space-y-6">
          <motion.div variants={itemVariants} className="glass-card-premium rounded-[1.5rem] p-6">
            <h3 className="section-header flex items-center gap-2 mb-6">
              <div className="w-8 h-8 rounded-lg bg-primary-container/20 text-primary flex items-center justify-center shrink-0">
                <Users className="w-4 h-4" />
              </div>
              المعلومات الأساسية
            </h3>
            <div className="grid grid-cols-2 gap-y-5 gap-x-4 text-sm">
              <div className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-lg bg-primary-container/10 text-primary/60 flex items-center justify-center shrink-0 mt-0.5">
                  <Hash className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-[11px] text-muted-foreground mb-0.5">رقم العضوية</p>
                  <p className="text-foreground font-semibold font-mono">{athlete.membership_number}</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-lg bg-primary-container/10 text-primary/60 flex items-center justify-center shrink-0 mt-0.5">
                  <Phone className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-[11px] text-muted-foreground mb-0.5">رقم الهاتف</p>
                  <p className="text-foreground font-semibold" dir="ltr">{athlete.phone}</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-lg bg-primary-container/10 text-primary/60 flex items-center justify-center shrink-0 mt-0.5">
                  <Calendar className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-[11px] text-muted-foreground mb-0.5">تاريخ الميلاد</p>
                  <p className="text-foreground font-semibold">{formatDate(athlete.birth_date)}</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-lg bg-primary-container/10 text-primary/60 flex items-center justify-center shrink-0 mt-0.5">
                  <Briefcase className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-[11px] text-muted-foreground mb-0.5">القسم</p>
                  <p className="text-foreground font-semibold">{athlete.department_name || "—"}</p>
                </div>
              </div>
              {athlete.parent_phone && (
                <div className="col-span-2 flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-primary-container/10 text-primary/60 flex items-center justify-center shrink-0 mt-0.5">
                    <Phone className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-[11px] text-muted-foreground mb-0.5">هاتف ولي الأمر</p>
                    <p className="text-foreground font-semibold" dir="ltr">{athlete.parent_phone}</p>
                  </div>
                </div>
              )}
            </div>
          </motion.div>

          {subs && (
            <motion.div variants={itemVariants} className="glass-card-premium rounded-[1.5rem] p-6 border-r-4 border-r-secondary relative overflow-hidden">
              <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-bl from-secondary/10 to-transparent rounded-bl-full pointer-events-none" />
              <h3 className="section-header flex items-center gap-2 mb-6">
                <div className="w-8 h-8 rounded-lg bg-secondary-container/20 text-secondary flex items-center justify-center shrink-0">
                  <Award className="w-4 h-4" />
                </div>
                تفاصيل الاشتراك الحالي
                <span className={`mr-auto inline-flex items-center gap-1.5 text-[11px] font-bold px-3 py-1 rounded-full border ${
                  subs.status === "active" ? "bg-secondary/10 text-secondary border-secondary/10" :
                  subs.status === "expired" ? "bg-error/10 text-error border-error/10" : "bg-amber-500/10 text-amber-600 border-amber-500/10"
                }`}>
                  <span className={`w-1.5 h-1.5 rounded-full ${
                    subs.status === "active" ? "bg-secondary" :
                    subs.status === "expired" ? "bg-error" : "bg-amber-500"
                  }`} />
                  {subs.status === "active" ? "نشط" : subs.status === "expired" ? "منتهي" : "قيد الانتظار"}
                </span>
              </h3>
              <div className="grid grid-cols-2 gap-y-5 gap-x-4 text-sm mb-5">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-secondary-container/10 text-secondary/60 flex items-center justify-center shrink-0 mt-0.5">
                    <Calendar className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-[11px] text-muted-foreground mb-0.5">تاريخ البدء</p>
                    <p className="text-foreground font-semibold">{formatDate(subs.start_date)}</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-secondary-container/10 text-secondary/60 flex items-center justify-center shrink-0 mt-0.5">
                    <Calendar className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-[11px] text-muted-foreground mb-0.5">تاريخ الانتهاء</p>
                    <p className="text-foreground font-semibold">{formatDate(subs.end_date)}</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-secondary-container/10 text-secondary/60 flex items-center justify-center shrink-0 mt-0.5">
                    <CreditCard className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-[11px] text-muted-foreground mb-0.5">قيمة الاشتراك</p>
                    <p className="text-foreground font-bold">{Number(subs.amount).toLocaleString("ar-SA-u-nu-latn")} د.ل</p>
                  </div>
                </div>
              </div>
              <div className="bg-surface-container-low rounded-xl p-4">
                <div className="flex justify-between items-center mb-2">
                  <span className="text-xs text-muted-foreground">المدة الزمنية المتبقية</span>
                  <span className="text-xs font-bold text-secondary">{calcDaysRemaining(subs.end_date)} يوم متبقي</span>
                </div>
                <div className="w-full bg-muted rounded-full h-2.5 overflow-hidden">
                  <motion.div
                    className="bg-gradient-to-l from-secondary to-secondary/60 h-full rounded-full"
                    initial={{ width: 0 }}
                    animate={{ width: `${calcPercent(subs.start_date, subs.end_date)}%` }}
                    transition={{ duration: 1, ease: [0.22, 1, 0.36, 1], delay: 0.3 }}
                  />
                </div>
              </div>
            </motion.div>
          )}
        </div>

        <motion.div className="lg:col-span-12 glass-card-premium rounded-[1.5rem] p-6 overflow-hidden" variants={itemVariants}>
          <h3 className="section-header flex items-center gap-2 mb-6">
            <div className="w-8 h-8 rounded-lg bg-primary-container/20 text-primary flex items-center justify-center shrink-0">
              <Receipt className="w-4 h-4" />
            </div>
            سجل الاشتراكات والتجديد
          </h3>
          <div className="overflow-x-auto w-full">
            <table className="w-full text-right border-collapse min-w-[600px]">
              <thead>
                <tr className="border-b border-border/40 text-muted-foreground text-xs font-semibold bg-surface-container-lowest/50 sticky top-0">
                  <th className="py-3 px-4 rounded-tr-xl">رقم العضوية</th>
                  <th className="py-3 px-4">تاريخ البدء</th>
                  <th className="py-3 px-4">تاريخ الانتهاء</th>
                  <th className="py-3 px-4">القيمة</th>
                  <th className="py-3 px-4">الحالة</th>
                  <th className="py-3 px-4 rounded-tl-xl text-center">تجديدات</th>
                </tr>
              </thead>
              <tbody className="text-sm text-foreground">
                {subscriptions.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-12 text-center text-muted-foreground">
                      لا يوجد سجل اشتراكات
                    </td>
                  </tr>
                ) : (
                  subscriptions.map((sub) => (
                    <tr
                      key={sub.id}
                      className="border-b border-border/20 hover:bg-surface-container-low/50 transition-all duration-200 group"
                    >
                      <td className="py-4 px-4 font-semibold font-mono text-xs">{sub.membership_number}</td>
                      <td className="py-4 px-4 text-muted-foreground">{formatDate(sub.start_date)}</td>
                      <td className="py-4 px-4 text-muted-foreground">{formatDate(sub.end_date)}</td>
                      <td className="py-4 px-4 font-bold">{Number(sub.amount).toLocaleString("ar-SA-u-nu-latn")} د.ل</td>
                      <td className="py-4 px-4">
                        <span className={`px-3 py-1 rounded-full text-xs font-bold inline-flex items-center gap-1.5 border ${
                          sub.status === "active" ? "bg-secondary/10 text-secondary border-secondary/10" :
                          sub.status === "expired" ? "bg-error/10 text-error border-error/10" : "bg-amber-500/10 text-amber-600 border-amber-500/10"
                        }`}>
                          <span className={`w-1.5 h-1.5 rounded-full ${
                            sub.status === "active" ? "bg-secondary" :
                            sub.status === "expired" ? "bg-error" : "bg-amber-500"
                          }`} />
                          {sub.status === "active" ? "نشط" : sub.status === "expired" ? "منتهي" : "قيد الانتظار"}
                        </span>
                      </td>
                      <td className="py-4 px-4 text-center">
                        <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-surface-container-low text-xs font-bold text-foreground">
                          {sub.renewals?.length || 0}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </motion.div>
      </div>
    </motion.div>
  )
}
