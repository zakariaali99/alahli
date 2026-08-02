import { useNavigate } from "react-router-dom"
import { motion } from "framer-motion"
import { AlertTriangle, RefreshCw } from "lucide-react"
import { useDepartments } from "@/lib/hooks/useDepartments"
import { extractResults } from "@/lib/response"
import type { Department } from "@/lib/types"
import { getAcademyLogo, isParentAcademy } from "@/lib/departments"

export default function ManagerHome() {
  const navigate = useNavigate()
  const { data, isLoading, isError, refetch } = useDepartments()
  const rawDepartments = extractResults(data)
  const departments = [...rawDepartments].sort((a, b) => {
    const isAParent = isParentAcademy(a)
    const isBParent = isParentAcademy(b)
    if (!isAParent && isBParent) return -1
    if (isAParent && !isBParent) return 1
    return a.id - b.id
  })

  if (isLoading) {
    return (
      <div className="flex h-[50vh] items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (isError) {
    return (
      <div className="flex h-[50vh] flex-col items-center justify-center gap-4 text-center">
        <AlertTriangle className="w-10 h-10 text-error" />
        <p className="text-sm font-bold text-error">تعذر تحميل قائمة الأكاديميات</p>
        <button
          onClick={() => void refetch()}
          className="inline-flex items-center gap-2 rounded-xl bg-error text-white px-4 py-2 text-sm font-bold hover:bg-error/90 transition-colors"
        >
          <RefreshCw className="w-4 h-4" />
          إعادة المحاولة
        </button>
      </div>
    )
  }

  return (
    <div className="flex flex-col items-center justify-center py-12">
      <div className="text-center space-y-3 mb-12">
        <h1 className="text-3xl font-extrabold tracking-tight text-[#0f2942]">أهلاً بك في بوابة الإدارة</h1>
        <p className="text-base text-muted-foreground">اختر الأكاديمية أو المركز للبدء في إدارة وتسيير العمليات الرياضية</p>
      </div>

      {departments.length === 0 ? (
        <div className="w-full max-w-md rounded-3xl border border-dashed border-gray-300 bg-white/60 p-10 text-center">
          <p className="text-sm font-semibold text-muted-foreground">لا توجد أكاديميات مسجلة حالياً</p>
        </div>
      ) : (
        <div className="grid gap-8 md:grid-cols-2 w-full max-w-4xl px-4">
          {departments.map((dept) => {
            const isParent = isParentAcademy(dept)
            const logo = getAcademyLogo(dept)
            const accentColor = dept.color || (isParent ? "#136F63" : "#0F4C81")
            return (
              <motion.button
                key={dept.id}
                whileHover={{ y: -6, scale: 1.01 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => navigate(`/manager/${dept.id}/sports`)}
                className="group relative flex flex-col items-center text-center p-8 bg-white rounded-3xl border border-gray-200/80 shadow-md hover:shadow-xl transition-all duration-300 overflow-hidden text-right"
              >
                <div
                  className="absolute top-0 right-0 w-24 h-24 rounded-bl-full group-hover:opacity-10 transition-opacity"
                  style={{ backgroundColor: `${accentColor}0a` }}
                />

                <div className="w-20 h-20 rounded-2xl bg-white border border-gray-150 shadow-sm flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300 p-2 shrink-0 overflow-hidden">
                  <img src={logo} alt="Logo" className="w-full h-full object-contain" />
                </div>

                <h2 className="text-2xl font-black text-[#0f2942] group-hover:text-primary transition-colors mb-2">
                  {dept.name_ar}
                </h2>
                <p className="text-sm font-semibold text-muted-foreground mb-4 h-12 flex items-center justify-center">
                  {isParent
                    ? "إدارة أكاديمية كرة القدم، أولياء الأمور، الأطفال والاشتراكات"
                    : "إدارة تدريبات الكاراتيه، السويدي، اللياقة البدنية والاشتراكات"
                  }
                </p>
                <span className="text-xs font-bold px-3 py-1 rounded-full text-white" style={{ backgroundColor: accentColor }}>
                  دخول لوحة التحكم ←
                </span>
              </motion.button>
            )
          })}
        </div>
      )}
    </div>
  )
}
