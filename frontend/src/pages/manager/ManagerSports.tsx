import { useNavigate, useParams, useSearchParams } from "react-router-dom"
import { motion } from "framer-motion"
import { AlertTriangle, ArrowLeft, Check, RefreshCw, Trophy } from "lucide-react"
import { useDepartment, useSports } from "@/lib/hooks/useDepartments"
import type { Department, Sport } from "@/lib/types"
import { getAcademyLogo } from "@/lib/departments"

function fallbackDepartment(academyId: number): Department {
  return {
    id: academyId,
    name: "",
    name_ar: `أكاديمية رقم ${academyId}`,
    color: "#0F4C81",
    logo: null,
    bank_account_number: "",
    iban: "",
    is_active: true,
    created_at: "",
  }
}

export default function ManagerSports() {
  const { academyId } = useParams<{ academyId: string }>()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const sportParam = searchParams.get("sport")
  const numericId = academyId ? Number(academyId) : undefined

  const {
    data: department,
    isLoading: deptLoading,
    isError: deptError,
  } = useDepartment(numericId)

  const {
    data: sports,
    isLoading: sportsLoading,
    isError: sportsError,
    refetch: refetchSports,
  } = useSports(numericId)

  const activeDepartment = department ?? (deptError && numericId ? fallbackDepartment(numericId) : null)

  if (deptLoading) {
    return (
      <div className="flex justify-center items-center py-24">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (!activeDepartment) {
    return (
      <div className="text-center py-12">
        <p className="text-lg text-error">الأكاديمية غير موجودة أو لم يتم العثور عليها.</p>
      </div>
    )
  }

  const sportCards = (sports ?? []).filter((s) => s.is_active)
  const themeColor = activeDepartment.color || "#0F4C81"
  const selectedId = sportParam ? Number(sportParam) : null

  const enterDashboard = (sport: Sport | null) => {
    const query = sport ? `?sport=${sport.id}` : ""
    navigate(`/manager/${activeDepartment.id}/dashboard${query}`)
  }

  return (
    <div className="space-y-8">
      <div className="bg-white rounded-3xl border border-gray-200/80 p-6 sm:p-8 shadow-sm flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate("/manager")}
            className="w-10 h-10 rounded-2xl border border-gray-200 bg-gray-50 flex items-center justify-center text-muted-foreground hover:text-foreground transition-colors"
            aria-label="الرجوع إلى قائمة الأكاديميات"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div className="w-16 h-16 rounded-2xl flex items-center justify-center text-white shadow-md shrink-0 overflow-hidden bg-white border border-gray-100">
            <img src={getAcademyLogo(activeDepartment)} alt="Logo" className="w-full h-full object-contain" />
          </div>
          <div>
            <h1 className="text-2xl font-black text-[#0f2942]">{activeDepartment.name_ar}</h1>
            <p className="text-sm font-semibold text-muted-foreground mt-1">اختر الرياضة للمتابعة إلى لوحة العمليات</p>
          </div>
        </div>
      </div>

      <div>
        <h2 className="text-lg font-extrabold text-[#0f2942] mb-6">اختيار الرياضة</h2>

        {sportsLoading ? (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 3 }).map((_, idx) => (
              <div key={idx} className="h-32 rounded-3xl border border-gray-200/60 bg-white shadow-sm animate-pulse" />
            ))}
          </div>
        ) : sportsError ? (
          <div className="flex flex-col items-center gap-3 rounded-3xl border border-error/20 bg-error/5 p-8 text-center">
            <AlertTriangle className="w-8 h-8 text-error" />
            <p className="text-sm font-bold text-error">تعذر تحميل أقسام الرياضة</p>
            <button
              onClick={() => void refetchSports()}
              className="inline-flex items-center gap-2 rounded-xl bg-error text-white px-4 py-2 text-sm font-bold hover:bg-error/90 transition-colors"
            >
              <RefreshCw className="w-4 h-4" />
              إعادة المحاولة
            </button>
          </div>
        ) : sportCards.length === 0 ? (
          <div className="flex flex-col items-center gap-4 rounded-3xl border border-dashed border-gray-300 bg-white/60 p-10 text-center">
            <Trophy className="w-8 h-8 text-muted-foreground/50" />
            <p className="text-sm font-semibold text-muted-foreground">
              لا توجد رياضات مسجلة في هذه الأكاديمية حالياً
            </p>
            <button
              onClick={() => enterDashboard(null)}
              className="rounded-xl px-5 py-2.5 text-sm font-bold text-white shadow-lg hover:opacity-90 transition-opacity"
              style={{ backgroundColor: themeColor }}
            >
              متابعة بدون تحديد رياضة
            </button>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {sportCards.map((sp, idx) => {
              const isSelected = selectedId === sp.id
              return (
                <motion.button
                  key={sp.id}
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: idx * 0.05 }}
                  whileHover={{ y: -4 }}
                  whileTap={{ scale: 0.99 }}
                  onClick={() => enterDashboard(sp)}
                  className={`w-full text-right p-6 rounded-3xl border transition-all duration-300 flex items-center gap-5 ${
                    isSelected
                      ? "border-primary bg-primary/[0.06] shadow-lg shadow-primary/10"
                      : "border-gray-200/60 bg-gradient-to-br from-white to-gray-50 hover:border-primary/50 shadow-sm"
                  }`}
                >
                  <div
                    className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 transition-colors ${
                      isSelected ? "bg-primary text-white" : "bg-primary/10 text-primary"
                    }`}
                  >
                    <Trophy className="w-6 h-6" />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-lg font-black text-[#0f2942]">{sp.name_ar}</h3>
                    <p className="text-xs font-medium text-muted-foreground" dir="ltr">
                      {sp.name}
                    </p>
                  </div>
                  {isSelected && (
                    <motion.span
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      className="w-7 h-7 rounded-full bg-primary flex items-center justify-center shrink-0"
                    >
                      <Check className="w-4 h-4 text-white" />
                    </motion.span>
                  )}
                </motion.button>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
