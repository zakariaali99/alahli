
import React, { useState } from "react"
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
} from "lucide-react"
import { useVerifyAthlete } from "@/lib/hooks/useAthletes"
import { QRScanner } from "@/components/ui/qr-scanner"
import { ErrorDisplay } from "@/components/ui/error-display"

type SearchState = "idle" | "loading" | "found" | "notfound"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.07, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
}

export default function VerifyPage() {
  const [query, setQuery] = useState("")
  const [searchState, setSearchState] = useState<SearchState>("idle")
  const verifyMutation = useVerifyAthlete()
  const member = verifyMutation.data

  const handleSearch = () => {
    const trimmed = query.trim()
    if (!trimmed) return
    setSearchState("loading")
    verifyMutation.mutate(trimmed, {
      onSuccess: () => setSearchState("found"),
      onError: () => setSearchState("notfound"),
    })
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") handleSearch()
  }

  const statusConfig = member?.active
    ? {
        label: "صالح",
        chipClass: "bg-[#006d30]/10 text-[#006d30]",
        icon: CheckCircle2,
        ringClass: "bg-[#006d30]/20",
      }
    : {
        label: member ? "منتهي" : "غير موجود",
        chipClass: "bg-[#ba1a1a]/10 text-[#ba1a1a]",
        icon: XCircle,
        ringClass: "bg-[#ba1a1a]/20",
      }

  const formatDate = (d: string | null) => {
    if (!d) return "—"
    return new Date(d).toLocaleDateString("ar-SA", { year: "numeric", month: "long", day: "numeric" })
  }

  return (
    <motion.div className="space-y-6" dir="rtl" variants={containerVariants} initial="hidden" animate="visible">
      <motion.div variants={itemVariants}>
        <h1 className="text-3xl font-bold text-foreground">الفحص السريع</h1>
        <p className="text-muted-foreground mt-1 text-sm">التحقق من حالة اشتراك الأعضاء عند البوابة.</p>
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-5 flex flex-col gap-5">
          <motion.div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-6 shadow-lg shadow-primary/5" variants={itemVariants}>
            <h3 className="text-lg font-bold text-foreground mb-5 flex items-center gap-2">
              <Keyboard className="w-5 h-5 text-primary" />
              إدخال يدوي
            </h3>
            <div className="relative mb-5">
              <label htmlFor="member-id" className="absolute -top-3 right-4 bg-white px-2 text-xs font-semibold text-primary z-10">
                رقم العضوية
              </label>
              <input
                id="member-id"
                type="text"
                dir="ltr"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="مثال: ALA-XXXXXXXX"
                className="w-full h-16 bg-[#F1F5F9] border-2 border-transparent focus:border-primary rounded-xl px-6 text-2xl font-bold text-center tracking-widest text-foreground transition-all outline-none"
              />
            </div>
            <button
              onClick={handleSearch}
              disabled={searchState === "loading"}
              className="w-full h-14 bg-primary text-white rounded-xl text-sm font-bold shadow-md shadow-primary/20 hover:bg-primary/90 transition-all flex items-center justify-center gap-2 disabled:opacity-70"
            >
              {searchState === "loading" ? (
                <>
                  <span className="inline-block w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                  جارٍ التحقق...
                </>
              ) : (
                <>
                  <Search className="w-5 h-5" />
                  تحقق من العضوية
                </>
              )}
            </button>
          </motion.div>

          <motion.div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-6 shadow-lg shadow-primary/5 flex-1 flex flex-col" variants={itemVariants}>
            <h3 className="text-lg font-bold text-foreground mb-4 flex items-center gap-2">
              <QrCode className="w-5 h-5 text-[#006d30]" />
              مسح الرمز
            </h3>
            <QRScanner
              onScan={(code) => {
                setQuery(code)
                setSearchState("loading")
                verifyMutation.mutate(code, {
                  onSuccess: () => setSearchState("found"),
                  onError: () => setSearchState("notfound"),
                })
              }}
              onError={(msg) => alert(msg)}
            />
          </motion.div>
        </div>

        <motion.div className="lg:col-span-7" variants={itemVariants}>
          <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-8 shadow-lg shadow-primary/5 h-full flex flex-col">
            <h3 className="text-lg font-bold text-foreground mb-6 flex items-center gap-2">
              نتيجة الفحص
            </h3>

            {searchState === "idle" && (
              <div className="flex-1 flex flex-col items-center justify-center text-center p-8 border-2 border-dashed border-border/30 rounded-xl bg-surface-container-low/50">
                <Search className="w-16 h-16 text-border/50 mb-4" />
                <p className="text-muted-foreground text-sm">الرجاء إدخال رقم العضوية أو مسح الرمز لعرض النتيجة.</p>
              </div>
            )}

            {searchState === "loading" && (
              <div className="flex-1 flex flex-col items-center justify-center text-center p-8">
                <div className="w-16 h-16 border-4 border-primary/20 border-t-primary rounded-full animate-spin mb-4" />
                <p className="text-muted-foreground text-sm">جارٍ التحقق...</p>
              </div>
            )}

            {searchState === "notfound" && (
              <div className="flex-1 flex flex-col items-center justify-center text-center p-8 border-2 border-dashed border-[#ba1a1a]/30 rounded-xl bg-[#ffdad6]/20">
                <XCircle className="w-16 h-16 text-[#ba1a1a]/60 mb-4" />
                <h2 className="text-xl font-bold text-foreground mb-2">رقم غير موجود</h2>
                <p className="text-muted-foreground text-sm">لم يتم العثور على عضو برقم «{query}». تأكد من الرقم وحاول مجدداً.</p>
              </div>
            )}

            {searchState === "found" && member && (
              <div className="flex-1 flex flex-col items-center justify-center animate-fade-in">
                <div className={`${statusConfig.chipClass} px-8 py-3 rounded-full text-2xl font-extrabold flex items-center gap-3 mb-8`}>
                  <statusConfig.icon className="w-8 h-8" />
                  {statusConfig.label}
                </div>

                <div className={`relative w-40 h-40 rounded-full p-2 ${statusConfig.ringClass} mb-6`}>
                  <div className={`w-full h-full rounded-full overflow-hidden border-4 border-white shadow-lg bg-primary-container/20 flex items-center justify-center text-4xl font-bold text-primary`}>
                    {member.athlete_name?.charAt(0) || "?"}
                  </div>
                  {member.active && (
                    <div className="absolute bottom-1 left-1 bg-white text-[#006d30] w-9 h-9 rounded-full flex items-center justify-center shadow-md">
                      <CheckCircle2 className="w-5 h-5" />
                    </div>
                  )}
                </div>

                <h2 className="text-3xl font-bold text-foreground mb-2 text-center">{member.athlete_name}</h2>
                <p className="text-muted-foreground mb-8 text-center flex items-center gap-2">
                  <Tag className="w-4 h-4" />
                  {member.membership_number}
                </p>

                <div className="w-full grid grid-cols-2 gap-4 bg-surface-container-low p-6 rounded-2xl border border-border/20">
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">القسم</p>
                    <p className="text-sm font-bold text-foreground">{member.department}</p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">تاريخ الانتهاء</p>
                    <p className="text-sm font-bold text-foreground">{formatDate(member.expiry_date)}</p>
                  </div>
                  <div className="col-span-2 mt-2 pt-4 border-t border-border/20">
                    <p className="text-xs text-muted-foreground mb-1">ملاحظات النظام</p>
                    <p className={`text-sm font-bold flex items-center gap-1 ${member.active ? "text-[#006d30]" : "text-[#ba1a1a]"}`}>
                      <Info className="w-4 h-4 shrink-0" />
                      {member.active ? "العضوية سارية المفعول" : "الاشتراك منتهي"}
                    </p>
                  </div>
                </div>

                {!member.active && (
                  <div className="w-full mt-4 flex gap-3">
                    <button className="flex-1 bg-primary text-white py-3 rounded-xl text-sm font-bold hover:bg-primary/90 transition-all shadow-md">
                      تجديد الاشتراك
                    </button>
                    <button className="flex-1 border border-border/40 text-foreground py-3 rounded-xl text-sm font-semibold hover:bg-surface-container transition-all">
                      توجيه للاستقبال
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>
        </motion.div>
      </div>
    </motion.div>
  )
}
