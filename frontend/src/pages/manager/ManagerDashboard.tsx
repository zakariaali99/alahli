import React, { useMemo } from "react"
import { useParams, useNavigate, useSearchParams, Navigate } from "react-router-dom"
import { motion } from "framer-motion"
import {
  UserPlus,
  Users,
  BadgeAlert,
  CreditCard,
  Heart,
  ShieldCheck,
  Trophy,
  LayoutGrid,
  RefreshCw,
  AlertTriangle,
  ArrowRight,
} from "lucide-react"
import { useDepartment, useSports } from "@/lib/hooks/useDepartments"
import type { Department, Sport } from "@/lib/types"
import { isParentAcademy, getAcademyLogo } from "@/lib/departments"

interface ActionCard {
  title: string
  desc: string
  icon: React.ComponentType<{ className?: string }>
  url: string
  color: string
  withSport?: boolean
}

function buildCards(deptId: number, isParent: boolean): ActionCard[] {
  if (isParent) {
    return [
      {
        title: "إضافة ولي أمر",
        desc: "تسجيل حساب ولي أمر جديد لربطه بالأبناء لاحقاً",
        icon: UserPlus,
        url: `/dashboard/athletes/add?department=${deptId}`,
        color: "from-teal-500/10 to-teal-600/5 hover:border-teal-500 text-teal-600",
      },
      {
        title: "تجديد الاشتراكات",
        desc: "تجديد اشتراكات الأبناء وتحديث تواريخ انتهائها",
        icon: CreditCard,
        url: `/dashboard/memberships?department=${deptId}&renew=1`,
        color: "from-green-500/10 to-green-600/5 hover:border-green-500 text-green-600",
      },
      {
        title: "عرض أولياء الأمور",
        desc: "قائمة أولياء الأمور وحساباتهم المسجلة في الأكاديمية",
        icon: Users,
        url: `/dashboard/parents?department=${deptId}`,
        color: "from-emerald-500/10 to-emerald-600/5 hover:border-emerald-500 text-emerald-600",
      },
      {
        title: "عرض الأبناء (الرياضيين)",
        desc: "قائمة الرياضيين المسجلين والمستبين للأكاديمية",
        icon: Heart,
        url: `/dashboard/athletes?department=${deptId}`,
        color: "from-sky-500/10 to-sky-600/5 hover:border-sky-500 text-sky-600",
      },
      {
        title: "الاشتراكات المنتهية",
        desc: "متابعة وإخطار الاشتراكات التي انتهت صلاحيتها بالأكاديمية",
        icon: BadgeAlert,
        url: `/dashboard/expired-memberships?department=${deptId}`,
        color: "from-rose-500/10 to-rose-600/5 hover:border-rose-500 text-rose-600",
      },
      {
        title: "طلبات التسجيل المعلقة",
        desc: "مراجعة واعتماد طلبات الانتساب والتسجيل الجديدة للأكاديمية",
        icon: ShieldCheck,
        url: `/dashboard/registrations?department=${deptId}`,
        color: "from-amber-500/10 to-amber-600/5 hover:border-amber-500 text-amber-600",
      },
      {
        title: "إدارة الباقات",
        desc: "إنشاء وتعديل باقات الاشتراك وأسعارها للجديد والتجديد",
        icon: LayoutGrid,
        url: `/dashboard/plans?department=${deptId}`,
        color: "from-violet-500/10 to-violet-600/5 hover:border-violet-500 text-violet-600",
        withSport: false,
      },
    ]
  }

  return [
    {
      title: "إضافة رياضي جديد",
      desc: "تسجيل رياضي جديد وتحديد فئته السنية مباشرة بالمركز",
      icon: UserPlus,
      url: `/dashboard/athletes/add?department=${deptId}`,
      color: "from-blue-500/10 to-blue-600/5 hover:border-blue-500 text-blue-600",
    },
    {
      title: "تجديد الاشتراكات",
      desc: "تجديد اشتراكات الرياضيين وتحديث تواريخ انتهائها",
      icon: CreditCard,
      url: `/dashboard/memberships?department=${deptId}&renew=1`,
      color: "from-emerald-500/10 to-emerald-600/5 hover:border-emerald-500 text-emerald-600",
    },
    {
      title: "عرض الرياضيين",
      desc: "قائمة واستعراض الرياضيين المسجلين في المركز",
      icon: Users,
      url: `/dashboard/athletes?department=${deptId}`,
      color: "from-indigo-500/10 to-indigo-600/5 hover:border-indigo-500 text-indigo-600",
    },
    {
      title: "الاشتراكات المنتهية",
      desc: "متابعة وإخطار الاشتراكات التي انتهت صلاحيتها بالمركز",
      icon: BadgeAlert,
      url: `/dashboard/expired-memberships?department=${deptId}`,
      color: "from-rose-500/10 to-rose-600/5 hover:border-rose-500 text-rose-600",
    },
    {
      title: "طلبات التسجيل المعلقة",
      desc: "مراجعة واعتماد طلبات الانتساب والتسجيل الجديدة للمركز",
      icon: ShieldCheck,
      url: `/dashboard/registrations?department=${deptId}`,
      color: "from-amber-500/10 to-amber-600/5 hover:border-amber-500 text-amber-600",
    },
    {
      title: "إدارة الباقات",
      desc: "إنشاء وتعديل باقات الاشتراك وأسعارها للجديد والتجديد",
      icon: LayoutGrid,
      url: `/dashboard/plans?department=${deptId}`,
      color: "from-violet-500/10 to-violet-600/5 hover:border-violet-500 text-violet-600",
      withSport: false,
    },
  ]
}

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

export default function ManagerDashboard() {
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

  const activeDepartment = useMemo<Department | null>(() => {
    if (department) return department
    if (deptError && numericId) return fallbackDepartment(numericId)
    return null
  }, [department, deptError, numericId])

  const selectedSport = useMemo<Sport | null>(() => {
    if (!sportParam || !sports) return null
    return sports.find((s) => s.id === Number(sportParam)) ?? null
  }, [sports, sportParam])

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

  if (!sportParam) {
    return <Navigate to={`/manager/${activeDepartment.id}/sports`} replace />
  }

  const isSportParent = selectedSport ? (
    selectedSport.name_ar.includes("كاراتيه") ||
    (selectedSport as any).supports_parents === true
  ) : false
  const isParent = isParentAcademy(activeDepartment) || isSportParent
  const actionCards = buildCards(activeDepartment.id, isParent)
  const themeColor = activeDepartment.color || "#0F4C81"

  const navigateTo = (card: ActionCard) => {
    const sportParamStr = card.withSport !== false && selectedSport ? `&sport=${selectedSport.id}` : ""
    navigate(`${card.url}${sportParamStr}`)
  }

  return (
    <div className="space-y-8">
      <div className="bg-white rounded-3xl border border-gray-200/80 p-6 sm:p-8 shadow-sm flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(`/manager/${activeDepartment.id}/sports`)}
            className="w-10 h-10 rounded-2xl border border-gray-200 bg-gray-50 flex items-center justify-center text-muted-foreground hover:text-foreground transition-colors shrink-0"
            aria-label="الرجوع لقطع الرياضات"
          >
            <ArrowRight className="w-5 h-5" />
          </button>
          <div className="w-16 h-16 rounded-2xl flex items-center justify-center text-white shadow-md shrink-0 overflow-hidden bg-white border border-gray-100">
            <img src={getAcademyLogo(activeDepartment)} alt="Logo" className="w-full h-full object-contain" />
          </div>
          <div>
            <h1 className="text-2xl font-black text-[#0f2942]">{activeDepartment.name_ar}</h1>
            <p className="text-sm font-semibold text-muted-foreground mt-1">
              لوحة المدير العام للمركز والأكاديمية
              {selectedSport ? (
                <>
                  {" "}
                  <span className="font-bold" style={{ color: themeColor }}>
                    ← {selectedSport.name_ar}
                  </span>
                </>
              ) : null}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2 self-start sm:self-auto">
          <button
            onClick={() => navigate(`/manager/${activeDepartment.id}/sports`)}
            className="inline-flex items-center gap-2 rounded-2xl border border-gray-200 bg-gray-50 px-4 py-2 text-sm font-bold text-[#0f2942] hover:bg-gray-100 transition-colors"
          >
            <Trophy className="w-4 h-4" style={{ color: themeColor }} />
            {selectedSport ? "تغيير الرياضة" : "اختيار الرياضة"}
          </button>
          <div className="flex items-center gap-2 bg-gray-50 border border-gray-150 rounded-2xl px-4 py-2">
            <ShieldCheck className="w-5 h-5 text-emerald-600" />
            <span className="text-sm font-bold text-[#0f2942]">صلاحيات المدير الخاص</span>
          </div>
        </div>
      </div>

      {sportsLoading ? (
        <div className="flex items-center gap-2 rounded-2xl border border-gray-200/60 bg-white/60 px-4 py-3 text-sm font-semibold text-muted-foreground">
          <RefreshCw className="w-4 h-4 animate-spin" />
          جارٍ التحقق من الرياضة المحددة...
        </div>
      ) : sportsError ? (
        <div className="flex items-center gap-3 rounded-2xl border border-error/20 bg-error/5 px-4 py-3 text-sm font-bold text-error">
          <AlertTriangle className="w-5 h-5" />
          تعذر تحميل الرياضات — قد تكون الرياضة المحددة غير صحيحة.
          <button
            onClick={() => void refetchSports()}
            className="underline hover:opacity-80"
          >
            إعادة المحاولة
          </button>
        </div>
      ) : null}

      <div>
        <div className="flex items-center gap-2 mb-6">
          <h2 className="text-lg font-extrabold text-[#0f2942]">العمليات والخدمات السريعة</h2>
          {selectedSport && (
            <span
              className="text-xs font-bold px-3 py-1 rounded-full text-white"
              style={{ backgroundColor: themeColor }}
            >
              {selectedSport.name_ar}
            </span>
          )}
        </div>

        <div className="grid gap-6 sm:grid-cols-2">
          {actionCards.map((card, idx) => {
            const Icon = card.icon
            return (
              <motion.button
                key={idx}
                whileHover={{ y: -4 }}
                whileTap={{ scale: 0.99 }}
                onClick={() => navigateTo(card)}
                className={`w-full text-right p-6 rounded-3xl border border-gray-200/60 bg-gradient-to-br ${card.color} shadow-sm transition-all duration-300 flex items-start gap-5`}
              >
                <div className="w-12 h-12 rounded-2xl bg-white flex items-center justify-center shadow-sm shrink-0">
                  <Icon className="w-6 h-6" />
                </div>
                <div className="space-y-1">
                  <h3 className="text-lg font-black text-[#0f2942]">{card.title}</h3>
                  <p className="text-sm font-medium text-muted-foreground leading-relaxed">{card.desc}</p>
                </div>
              </motion.button>
            )
          })}
        </div>
      </div>
    </div>
  )
}
