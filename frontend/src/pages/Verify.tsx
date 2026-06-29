import React, { useState, useCallback } from "react"
import { motion, type Variants } from "framer-motion"
import {
  Keyboard,
  QrCode,
  Search,
  CheckCircle2,
  XCircle,
  Tag,
  Info,
  AlertCircle,
  ScanLine,
  User,
  Building2,
  CalendarClock,
  Phone,
  Camera,
  Fingerprint,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { useVerifyAthlete } from "@/lib/hooks/useAthletes"
import { QRScanner } from "@/components/ui/qr-scanner"
import { ErrorDisplay } from "@/components/ui/error-display"
import { useLogAttendance } from "@/lib/hooks/useAttendance"
import { useToast } from "@/lib/toast"

type SearchState = "idle" | "loading" | "found" | "notfound"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.08, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5, ease: [0.22, 1, 0.36, 1] } },
}

const resultVariants: Variants = {
  hidden: { opacity: 0, scale: 0.9, y: 20 },
  visible: { opacity: 1, scale: 1, y: 0, transition: { type: "spring", stiffness: 120, damping: 14 } },
}

const scanLineVariants: Variants = {
  animate: {
    top: ["0%", "100%", "0%"],
    transition: { duration: 2.5, repeat: Infinity, ease: "linear" },
  },
}

const statusConfig = (active: boolean) =>
  active
    ? {
        label: "صالح",
        chipClass: "bg-secondary/10 text-secondary",
        icon: CheckCircle2,
        ringClass: "ring-secondary/20",
        gradientFrom: "from-secondary",
        gradientTo: "to-emerald-400",
      }
    : {
        label: "منتهي",
        chipClass: "bg-error/10 text-error",
        icon: XCircle,
        ringClass: "ring-error/20",
        gradientFrom: "from-error",
        gradientTo: "to-rose-400",
      }

const formatDate = (d: string | null) => {
  if (!d) return "—"
  return new Date(d).toLocaleDateString("ar-SA-u-nu-latn", { year: "numeric", month: "long", day: "numeric" })
}

function IdlePlaceholder() {
  return (
    <div className="flex-1 flex flex-col items-center justify-center text-center p-10 border-2 border-dashed border-border/20 rounded-[1.5rem] bg-surface-container-low/30">
      <div className="relative mb-6">
        <div className="w-24 h-24 rounded-full bg-gradient-to-br from-primary/10 to-secondary/10 flex items-center justify-center">
          <Search className="w-10 h-10 text-primary/40" />
        </div>
        <div className="absolute -top-1 -right-1 w-8 h-8 rounded-full bg-secondary/10 flex items-center justify-center">
          <Fingerprint className="w-4 h-4 text-secondary/50" />
        </div>
      </div>
      <h3 className="text-lg font-bold text-foreground mb-2">أدخل رقم العضوية</h3>
      <p className="text-muted-foreground text-sm max-w-[260px] leading-relaxed">
        استخدم حقل الإدخال اليدوي أو فعّل كاميرا المسح للتحقق من حالة العضوية
      </p>
    </div>
  )
}

function LoadingSkeleton() {
  return (
    <div className="flex-1 flex flex-col items-center justify-center p-8 animate-pulse space-y-6">
      <div className="w-24 h-24 rounded-full bg-muted/60" />
      <div className="space-y-3 w-full max-w-[280px]">
        <div className="h-5 bg-muted/60 rounded-lg w-3/4 mx-auto" />
        <div className="h-4 bg-muted/40 rounded-lg w-1/2 mx-auto" />
      </div>
      <div className="grid grid-cols-2 gap-4 w-full max-w-[320px]">
        <div className="h-16 bg-muted/40 rounded-xl" />
        <div className="h-16 bg-muted/40 rounded-xl" />
        <div className="h-16 bg-muted/40 rounded-xl col-span-2" />
      </div>
    </div>
  )
}

function NotFoundState({ query }: { query: string }) {
  return (
    <div className="flex-1 flex flex-col items-center justify-center text-center p-10">
      <div className="w-20 h-20 rounded-2xl bg-error/10 flex items-center justify-center mb-5">
        <XCircle className="w-10 h-10 text-error/60" />
      </div>
      <h2 className="text-xl font-bold text-foreground mb-2">رقم غير موجود</h2>
      <p className="text-muted-foreground text-sm max-w-[260px] leading-relaxed mb-6">
        لم يتم العثور على عضو برقم «{query}». تأكد من الرقم وحاول مجدداً.
      </p>
      <div className="flex items-center gap-2 text-xs text-muted-foreground bg-surface-container-low px-4 py-2 rounded-full border border-border/20">
        <Info className="w-3.5 h-3.5" />
        قد يكون الرقم خطأ أو العضوية غير مسجلة في النظام
      </div>
    </div>
  )
}

type AthleteVerify = {
  active: boolean
  athlete_id: number
  athlete_name: string
  department: string
  expiry_date: string | null
  membership_number: string
  subscription_id: number | null
}

function MemberFound({ member }: { member: AthleteVerify }) {
  const status = statusConfig(member.active)

  return (
    <motion.div
      className="flex-1 flex flex-col items-center"
      variants={resultVariants}
      initial="hidden"
      animate="visible"
    >
      <div className={`${status.chipClass} px-6 py-2.5 rounded-full text-lg font-extrabold flex items-center gap-2.5 mb-6 shadow-sm`}>
        <status.icon className="w-5 h-5" />
        {status.label}
      </div>

      <div className={`relative w-36 h-36 rounded-full p-1 ${status.ringClass} ring-2 mb-5`}>
        <div className="w-full h-full rounded-full overflow-hidden border-[3px] border-white shadow-lg bg-surface-container-low flex items-center justify-center">
          {member.athlete_name ? (
            <span className="text-4xl font-bold gradient-text">{member.athlete_name.charAt(0)}</span>
          ) : (
            <User className="w-12 h-12 text-primary/40" />
          )}
        </div>
        {member.active && (
          <div className="absolute -bottom-1 -left-1 bg-white dark:bg-surface-container text-secondary w-9 h-9 rounded-full flex items-center justify-center shadow-md border-2 border-secondary/20">
            <CheckCircle2 className="w-5 h-5" />
          </div>
        )}
      </div>

      <h2 className="text-2xl font-extrabold gradient-text mb-1 text-center">{member.athlete_name}</h2>
      <p className="text-muted-foreground mb-6 text-center flex items-center gap-1.5 text-sm">
        <Tag className="w-3.5 h-3.5" />
        {member.membership_number}
      </p>

      <div className="w-full grid grid-cols-2 gap-3 bg-surface-container-low/70 p-5 rounded-[1.5rem] border border-border/15">
        <div className="bg-white/50 dark:bg-surface-container-highest/30 rounded-xl p-3.5">
          <p className="text-[11px] text-muted-foreground mb-1 flex items-center gap-1">
            <Building2 className="w-3 h-3" />
            القسم
          </p>
          <p className="text-sm font-bold text-foreground">{member.department || "—"}</p>
        </div>
        <div className="bg-white/50 dark:bg-surface-container-highest/30 rounded-xl p-3.5">
          <p className="text-[11px] text-muted-foreground mb-1 flex items-center gap-1">
            <CalendarClock className="w-3 h-3" />
            تاريخ الانتهاء
          </p>
          <p className="text-sm font-bold text-foreground">{formatDate(member.expiry_date)}</p>
        </div>
        <div className="col-span-2 bg-white/50 dark:bg-surface-container-highest/30 rounded-xl p-3.5 border-t-2 border-t-border/10">
          <p className="text-[11px] text-muted-foreground mb-1 flex items-center gap-1">
            <Info className="w-3 h-3" />
            حالة العضوية
          </p>
          <p className={`text-sm font-bold flex items-center gap-1.5 ${member.active ? "text-secondary" : "text-error"}`}>
            <span className={`w-2 h-2 rounded-full ${member.active ? "bg-secondary" : "bg-error"}`} />
            {member.active ? "العضوية سارية المفعول" : "الاشتراك منتهي"}
          </p>
        </div>
      </div>

      {!member.active && (
        <motion.div
          className="w-full mt-4 flex gap-3"
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          <Button size="lg" className="flex-1 bg-gradient-to-l from-primary to-primary/80 shadow-lg shadow-primary/20">
            <CheckCircle2 className="w-4 h-4" />
            تجديد الاشتراك
          </Button>
          <Button variant="outline" size="lg" className="flex-1">
            توجيه للاستقبال
          </Button>
        </motion.div>
      )}
    </motion.div>
  )
}

export default function VerifyPage() {
  const [query, setQuery] = useState("")
  const [searchState, setSearchState] = useState<SearchState>("idle")
  const verifyMutation = useVerifyAthlete()
  const logAttendance = useLogAttendance()
  const toast = useToast()
  const member = verifyMutation.data

  const handleSearch = useCallback(() => {
    const trimmed = query.trim()
    if (!trimmed) return
    setSearchState("loading")
    verifyMutation.mutate(trimmed, {
      onSuccess: (data) => {
        setSearchState("found")
        if (data.athlete_id) {
          logAttendance.mutate({ athlete: data.athlete_id, subscription: data.subscription_id ?? undefined })
        }
      },
      onError: () => setSearchState("notfound"),
    })
  }, [query, verifyMutation, logAttendance])

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === "Enter") handleSearch()
  }, [handleSearch])

  const handleQrScan = useCallback(
    (code: string) => {
      setQuery(code)
      setSearchState("loading")
      verifyMutation.mutate(code, {
        onSuccess: (data) => {
          setSearchState("found")
          if (data.athlete_id) {
            logAttendance.mutate({ athlete: data.athlete_id, subscription: data.subscription_id ?? undefined })
          }
        },
        onError: () => setSearchState("notfound"),
      })
    },
    [verifyMutation, logAttendance],
  )

  return (
    <motion.div className="space-y-6" dir="rtl" variants={containerVariants} initial="hidden" animate="visible">
      <motion.div variants={itemVariants}>
        <h1 className="text-3xl font-extrabold gradient-text">الفحص السريع</h1>
        <p className="text-muted-foreground mt-1 text-sm">التحقق من حالة اشتراك الأعضاء عند البوابة.</p>
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-5 flex flex-col gap-5">
          <motion.div
            className="glass-card-premium rounded-[2rem] p-6 md:p-7 relative overflow-hidden"
            variants={itemVariants}
          >
            <div className="absolute inset-0 bg-gradient-to-br from-primary/[0.05] via-transparent to-secondary/[0.05]" />
            <div className="relative z-10">
              <h3 className="section-header flex items-center gap-2 mb-6">
                <Keyboard className="w-5 h-5 text-primary" />
                إدخال يدوي
              </h3>

              <div className="relative mb-5">
                <div className="absolute -top-3 right-4 bg-white dark:bg-surface-container-high px-2.5 text-[11px] font-bold text-primary z-10 rounded-md">
                  رقم العضوية
                </div>
                <input
                  id="member-id"
                  type="text"
                  dir="ltr"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="ALA-XXXXXXXX"
                  className="w-full h-16 bg-surface-container-low border-2 border-border/30 focus:border-primary/60 rounded-xl px-6 text-2xl font-bold text-center tracking-[0.15em] text-foreground transition-all outline-none placeholder:text-border/40"
                />
              </div>

              <Button
                onClick={handleSearch}
                disabled={searchState === "loading"}
                size="lg"
                className="w-full h-14 bg-gradient-to-l from-primary to-primary/80 text-primary-foreground shadow-lg shadow-primary/25"
              >
                {searchState === "loading" ? (
                  <>
                    <LoadingSpinner size="sm" className="border-primary-foreground/40 border-t-primary-foreground" />
                    جارٍ التحقق...
                  </>
                ) : (
                  <>
                    <Search className="w-5 h-5" />
                    تحقق من العضوية
                  </>
                )}
              </Button>
            </div>
          </motion.div>

          <motion.div
            className="glass-card-premium rounded-[2rem] p-6 md:p-7 relative overflow-hidden flex-1 flex flex-col"
            variants={itemVariants}
          >
            <div className="absolute inset-0 bg-gradient-to-br from-secondary/[0.04] via-transparent to-primary/[0.04]" />
            <div className="relative z-10 flex flex-col flex-1">
              <h3 className="section-header flex items-center gap-2 mb-5">
                <QrCode className="w-5 h-5 text-secondary" />
                مسح الرمز
              </h3>

              <div className="relative flex-1">
                <div className="relative overflow-hidden rounded-2xl">
                  <QRScanner onScan={handleQrScan} onError={(msg) => toast.error(msg)} />
                  <motion.div
                    className="absolute left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-secondary to-transparent pointer-events-none z-20"
                    variants={scanLineVariants}
                    animate="animate"
                    style={{ top: "0%" }}
                  />
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        <motion.div className="lg:col-span-7" variants={itemVariants}>
          <div className="glass-card-premium rounded-[2rem] p-6 md:p-8 relative overflow-hidden h-full flex flex-col">
            <div className="absolute inset-0 bg-gradient-to-br from-primary/[0.03] via-transparent to-secondary/[0.03]" />
            <div className="relative z-10 flex flex-col flex-1">
              <h3 className="section-header flex items-center gap-2 mb-6">
                <Fingerprint className="w-5 h-5 text-primary" />
                نتيجة الفحص
              </h3>

              {searchState === "idle" && <IdlePlaceholder />}
              {searchState === "loading" && <LoadingSkeleton />}
              {searchState === "notfound" && <NotFoundState query={query} />}
              {searchState === "found" && member && <MemberFound member={member} />}
              {verifyMutation.isError && searchState !== "notfound" && searchState !== "loading" && (
                <ErrorDisplay
                  message="حدث خطأ أثناء التحقق"
                  onRetry={handleSearch}
                />
              )}
            </div>
          </div>
        </motion.div>
      </div>
    </motion.div>
  )
}
