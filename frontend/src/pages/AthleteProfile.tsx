import React from "react"
import { motion, type Variants } from "framer-motion"
import { useParams } from "react-router-dom"
import { Link } from "react-router-dom"
import { ArrowRight, Edit, RefreshCw, Printer, Shield, Dumbbell, Calendar, Heart, Award, Receipt, Users } from "lucide-react"
import { useAthlete } from "@/lib/hooks/useAthletes"
import { useSubscriptions } from "@/lib/hooks/useSubscriptions"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.08, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
}

export default function AthleteProfilePage() {
  const params = useParams()
  const id = Number(params.id)
  const { data: athlete, isLoading } = useAthlete(id)
  const { data: subsData } = useSubscriptions({ athlete: String(id) })

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
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
    new Date(d).toLocaleDateString("ar-SA", { year: "numeric", month: "long", day: "numeric" })

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

  return (
    <motion.div className="space-y-6 select-none print:bg-white print:text-black" variants={containerVariants} initial="hidden" animate="visible">
      <div className="fixed top-0 left-0 w-full h-full overflow-hidden -z-10 pointer-events-none print:hidden">
        <div className="absolute top-[-10%] right-[-5%] w-[40vw] h-[40vw] rounded-full bg-primary/5 blur-3xl" />
        <div className="absolute bottom-[-10%] left-[-5%] w-[30vw] h-[30vw] rounded-full bg-secondary/5 blur-3xl" />
      </div>

      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6 print:hidden">
        <div className="flex items-center gap-2 text-muted-foreground text-sm font-semibold">
          <Link to="/dashboard/athletes" className="hover:text-primary transition-colors">اللاعبين</Link>
          <ChevronLeftIcon className="w-4 h-4" />
          <span className="text-primary font-bold">ملف اللاعب</span>
        </div>
        <div className="flex items-center gap-3 w-full md:w-auto">
          <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-5 py-2.5 bg-white border border-border/65 text-primary text-sm font-bold rounded-xl hover:bg-muted transition-colors shadow-sm">
            <Printer className="w-4 h-4" />
            طباعة البطاقة
          </button>
          <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-5 py-2.5 bg-white border border-border/65 text-primary text-sm font-bold rounded-xl hover:bg-muted transition-colors shadow-sm">
            <Edit className="w-4 h-4" />
            تعديل البيانات
          </button>
          <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-5 py-2.5 bg-primary text-primary-foreground text-sm font-bold rounded-xl hover:bg-primary/95 transition-all shadow-lg shadow-primary/20">
            <RefreshCw className="w-4 h-4" />
            تجديد الاشتراك
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <motion.div className="lg:col-span-8 glass-card rounded-[2rem] p-6 md:p-8 relative overflow-hidden flex flex-col sm:flex-row items-center sm:items-start gap-6" variants={itemVariants}>
          <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-bl from-primary/10 to-transparent rounded-bl-full pointer-events-none" />
          <div className="relative shrink-0">
            <div className="w-32 h-32 md:w-36 md:h-36 rounded-full overflow-hidden border-4 border-white shadow-xl relative z-10">
              {athlete.photo ? (
                <img alt={athlete.full_name} src={athlete.photo} className="object-cover w-full h-full" />
              ) : (
                <div className="w-full h-full flex items-center justify-center bg-primary-container/20 text-primary text-4xl font-bold">
                  {athlete.full_name.charAt(0)}
                </div>
              )}
            </div>
            <div className="absolute bottom-2 left-2 z-20 bg-secondary-container text-on-secondary-container text-[11px] font-bold px-3 py-1 rounded-full border-2 border-white flex items-center gap-1 shadow-sm">
              <span className="w-2 h-2 rounded-full bg-secondary" />
              {athlete.is_active ? "نشط" : "غير نشط"}
            </div>
          </div>
          <div className="flex-1 text-center sm:text-right pt-2 relative z-10">
            <h2 className="text-2xl md:text-3xl font-extrabold text-foreground mb-2">{athlete.full_name}</h2>
            <p className="text-sm text-muted-foreground mb-4">{athlete.department_name} • {athlete.membership_number}</p>
            <div className="flex flex-wrap justify-center sm:justify-start gap-3 mt-4">
              <div className="bg-surface-container-low px-4 py-2 rounded-xl flex items-center gap-2 border border-border/20 text-xs font-semibold text-foreground">
                <Shield className="w-4 h-4 text-primary" />
                <span>{genderLabel}</span>
              </div>
              <div className="bg-surface-container-low px-4 py-2 rounded-xl flex items-center gap-2 border border-border/20 text-xs font-semibold text-foreground">
                <Calendar className="w-4 h-4 text-primary" />
                <span>{formatDate(athlete.birth_date)}</span>
              </div>
            </div>
          </div>
        </motion.div>

        <motion.div className="lg:col-span-4 glass-card rounded-[2rem] p-6 flex flex-col items-center justify-center text-center relative overflow-hidden group" variants={itemVariants}>
          <div className="absolute inset-0 bg-gradient-to-br from-surface-container-highest/20 to-transparent pointer-events-none" />
          <div className="w-full flex justify-between items-center mb-6 relative z-10">
            <h3 className="text-lg font-bold text-foreground">بطاقة العضوية</h3>
            <button className="text-primary hover:bg-primary/10 p-2 rounded-full transition-colors">
              <Printer className="w-4 h-4" />
            </button>
          </div>
          <div className="w-full max-w-[260px] bg-gradient-to-tr from-[#00204f] to-[#1a3668] rounded-2xl p-4 text-white shadow-xl relative overflow-hidden flex flex-col items-center gap-3">
            <div className="absolute top-[-20px] left-[-20px] w-24 h-24 bg-white/5 rounded-full blur-xl" />
            <div className="flex justify-between items-center w-full pb-2 border-b border-white/10">
              <span className="text-[10px] uppercase font-bold tracking-wider opacity-85">بطاقة هوية رياضية</span>
              <Award className="w-4 h-4 text-amber-400" />
            </div>
            <div className="bg-white p-3 rounded-xl border border-white/20 my-2 relative z-10 transition-all duration-300">
              {athlete.qr_code ? (
                <img alt="QR Code" src={athlete.qr_code} width={120} height={120} className="opacity-90" />
              ) : (
                <div className="w-[120px] h-[120px] flex items-center justify-center text-gray-400 text-xs">لا يوجد QR</div>
              )}
            </div>
            <div className="w-full text-center">
              <div className="text-xs font-semibold">{athlete.full_name}</div>
              <div className="text-[10px] opacity-75 mt-1 font-mono tracking-widest">{athlete.membership_number}</div>
            </div>
          </div>
        </motion.div>

        <motion.div className="lg:col-span-6 glass-card rounded-[1.5rem] p-6 flex flex-col" variants={itemVariants}>
          <div className="flex items-center gap-2 mb-6 pb-4 border-b border-border/20">
            <div className="w-8 h-8 rounded-lg bg-primary-container/20 text-primary flex items-center justify-center shrink-0">
              <Users className="w-4 h-4" />
            </div>
            <h3 className="text-base font-bold text-foreground">المعلومات الأساسية</h3>
          </div>
          <div className="grid grid-cols-2 gap-y-6 gap-x-4 flex-1 text-sm">
            <div>
              <p className="text-xs text-muted-foreground mb-1">رقم العضوية</p>
              <p className="text-foreground font-semibold font-mono">{athlete.membership_number}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">رقم الهاتف</p>
              <p className="text-foreground font-semibold" dir="ltr">{athlete.phone}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">تاريخ الميلاد</p>
              <p className="text-foreground font-semibold">{formatDate(athlete.birth_date)}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">القسم</p>
              <p className="text-foreground font-semibold">{athlete.department_name || "—"}</p>
            </div>
            {athlete.parent_phone && (
              <div className="col-span-2">
                <p className="text-xs text-muted-foreground mb-1">هاتف ولي الأمر</p>
                <p className="text-foreground font-semibold" dir="ltr">{athlete.parent_phone}</p>
              </div>
            )}
          </div>
        </motion.div>

        {subs && (
          <motion.div className="lg:col-span-6 glass-card rounded-[1.5rem] p-6 flex flex-col border-l-4 border-l-secondary" variants={itemVariants}>
            <div className="flex justify-between items-center mb-6 pb-4 border-b border-border/20">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-secondary-container/20 text-secondary flex items-center justify-center shrink-0">
                  <Award className="w-4 h-4" />
                </div>
                <h3 className="text-base font-bold text-foreground">تفاصيل الاشتراك الحالي</h3>
              </div>
              <span className={`text-xs font-bold px-3 py-1 rounded-full ${
                subs.status === "active" ? "bg-secondary/15 text-secondary" :
                subs.status === "expired" ? "bg-error/15 text-error" : "bg-amber-500/15 text-amber-600"
              }`}>
                {subs.status === "active" ? "نشط" : subs.status === "expired" ? "منتهي" : "قيد الانتظار"}
              </span>
            </div>
            <div className="flex-1 flex flex-col justify-between text-sm">
              <div className="grid grid-cols-2 gap-y-4 gap-x-4 mb-4">
                <div>
                  <p className="text-xs text-muted-foreground mb-1">تاريخ البدء</p>
                  <p className="text-foreground font-semibold flex items-center gap-1.5">
                    <Calendar className="w-4 h-4 text-muted-foreground" />
                    {formatDate(subs.start_date)}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-muted-foreground mb-1">تاريخ الانتهاء</p>
                  <p className="text-foreground font-semibold flex items-center gap-1.5">
                    <Calendar className="w-4 h-4 text-muted-foreground" />
                    {formatDate(subs.end_date)}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-muted-foreground mb-1">قيمة الاشتراك</p>
                  <p className="text-foreground font-bold">{Number(subs.amount).toLocaleString("ar-SA")} د.ل</p>
                </div>
              </div>
              <div className="mt-4">
                <div className="flex justify-between items-end mb-2 text-xs">
                  <span className="text-muted-foreground">المدة الزمنية المتبقية</span>
                  <span className="text-secondary font-bold">{calcDaysRemaining(subs.end_date)} يوم متبقي</span>
                </div>
                <div className="w-full bg-muted rounded-full h-2 overflow-hidden">
                  <div
                    className="bg-secondary h-full rounded-full transition-all duration-500"
                    style={{ width: `${calcPercent(subs.start_date, subs.end_date)}%` }}
                  />
                </div>
              </div>
            </div>
          </motion.div>
        )}

        <motion.div className="lg:col-span-12 glass-card rounded-[1.5rem] p-6 overflow-hidden" variants={itemVariants}>
          <div className="flex items-center gap-2 mb-6">
            <div className="w-8 h-8 rounded-lg bg-primary-container/20 text-primary flex items-center justify-center shrink-0">
              <Receipt className="w-4 h-4" />
            </div>
            <h3 className="text-base font-bold text-foreground">سجل الاشتراكات والتجديد</h3>
          </div>
          <div className="overflow-x-auto w-full">
            <table className="w-full text-right border-collapse min-w-[600px]">
              <thead>
                <tr className="border-b border-border/40 text-muted-foreground text-xs font-semibold bg-surface-container-lowest/50">
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
                    <tr key={sub.id} className="border-b border-border/20 hover:bg-surface-container-low/50 transition-colors group">
                      <td className="py-4 px-4 font-semibold font-mono text-xs">{sub.membership_number}</td>
                      <td className="py-4 px-4 text-muted-foreground">{formatDate(sub.start_date)}</td>
                      <td className="py-4 px-4 text-muted-foreground">{formatDate(sub.end_date)}</td>
                      <td className="py-4 px-4 font-bold">{Number(sub.amount).toLocaleString("ar-SA")} د.ل</td>
                      <td className="py-4 px-4">
                        <span className={`px-2 py-0.5 rounded text-xs font-semibold ${
                          sub.status === "active" ? "bg-secondary/15 text-secondary" :
                          sub.status === "expired" ? "bg-error/15 text-error" : "bg-amber-500/15 text-amber-600"
                        }`}>
                          {sub.status === "active" ? "نشط" : sub.status === "expired" ? "منتهي" : "قيد الانتظار"}
                        </span>
                      </td>
                      <td className="py-4 px-4 text-center">
                        <span className="text-xs text-muted-foreground">{sub.renewals?.length || 0}</span>
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

function ChevronLeftIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m15 18-6-6 6-6" />
    </svg>
  )
}
