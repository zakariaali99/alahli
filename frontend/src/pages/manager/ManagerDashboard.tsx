import React, { useState, useEffect } from "react"
import { useParams, useNavigate } from "react-router-dom"
import { motion } from "framer-motion"
import { api } from "@/lib/api"
import { type Department } from "@/lib/types"
import { 
  UserPlus, 
  Users, 
  BadgeAlert, 
  CreditCard, 
  Heart, 
  Building, 
  TrendingUp,
  ShieldCheck
} from "lucide-react"

interface ActionCard {
  title: string
  desc: string
  icon: React.ComponentType<{ className?: string }>
  url: string
  color: string
}

export default function ManagerDashboard() {
  const { academyId } = useParams<{ academyId: string }>()
  const navigate = useNavigate()
  const [department, setDepartment] = useState<Department | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!academyId) return

    setLoading(true)
    api.get<Department>(`/departments/${academyId}/`)
      .then((data) => {
        setDepartment(data)
      })
      .catch((err) => {
        console.error("Error fetching department details:", err)
        // Fallback names in case of API failure
        const fallbacks: Record<string, Partial<Department>> = {
          "2": { id: 2, name_ar: "مركز الأهلي الرياضي", color: "#0F4C81", logo: "/logo.png" },
          "3": { id: 3, name_ar: "أكاديمية الأوس", color: "#136F63", logo: "/alaws_logo.png" },
          "4": { id: 4, name_ar: "مركز الأهلي الرياضي", color: "#0F4C81", logo: "/logo.png" },
          "5": { id: 5, name_ar: "أكاديمية الأوس", color: "#136F63", logo: "/alaws_logo.png" }
        }
        if (fallbacks[academyId]) {
          setDepartment({
            id: Number(academyId),
            name: (academyId === "4" || academyId === "2") ? "Al Ahli" : "Al Aws",
            name_ar: fallbacks[academyId].name_ar!,
            color: fallbacks[academyId].color!,
            logo: fallbacks[academyId].logo!,
            bank_account_number: "",
            iban: "",
            is_active: true,
            created_at: ""
          })
        }
      })
      .finally(() => {
        setLoading(false)
      })
  }, [academyId])

  if (loading) {
    return (
      <div className="flex justify-center items-center py-24">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (!department) {
    return (
      <div className="text-center py-12">
        <p className="text-lg text-error">الأكاديمية غير موجودة أو لم يتم العثور عليها.</p>
      </div>
    )
  }

  // Cards definitions
  // Cards definitions
  const ahliCards: ActionCard[] = [
    {
      title: "إضافة رياضي جديد",
      desc: "تسجيل رياضي جديد وتحديد فئته السنية مباشرة بالمركز",
      icon: UserPlus,
      url: `/dashboard/athletes/add?department=4`,
      color: "from-blue-500/10 to-blue-600/5 hover:border-blue-500 text-blue-600"
    },
    {
      title: "عرض الرياضيين",
      desc: "قائمة واستعراض الرياضيين المسجلين في مركز الأهلي",
      icon: Users,
      url: `/dashboard/athletes?department=4`,
      color: "from-indigo-500/10 to-indigo-600/5 hover:border-indigo-500 text-indigo-600"
    },
    {
      title: "الاشتراكات المنتهية",
      desc: "متابعة وإخطار الاشتراكات التي انتهت صلاحيتها بالمركز",
      icon: BadgeAlert,
      url: `/dashboard/expired-memberships?department=4`,
      color: "from-rose-500/10 to-rose-600/5 hover:border-rose-500 text-rose-600"
    },
    {
      title: "إدارة الاشتراكات",
      desc: "عرض، إضافة، وتجديد باقات الاشتراكات للمنتسبين",
      icon: CreditCard,
      url: `/dashboard/memberships?department=4`,
      color: "from-emerald-500/10 to-emerald-600/5 hover:border-emerald-500 text-emerald-600"
    },
    {
      title: "طلبات التسجيل المعلقة",
      desc: "مراجعة واعتماد طلبات الانتساب والتسجيل الجديدة للمركز",
      icon: ShieldCheck,
      url: `/dashboard/registrations?department=4`,
      color: "from-amber-500/10 to-amber-600/5 hover:border-amber-500 text-amber-600"
    }
  ]

  const awsCards: ActionCard[] = [
    {
      title: "إضافة ولي أمر",
      desc: "تسجيل حساب ولي أمر جديد لربطه بالرياضيين لاحقاً",
      icon: UserPlus,
      url: `/dashboard/athletes/add?department=5`,
      color: "from-teal-500/10 to-teal-600/5 hover:border-teal-500 text-teal-600"
    },
    {
      title: "عرض أولياء الأمور",
      desc: "قائمة أولياء الأمور وحساباتهم المسجلة في الأكاديمية",
      icon: Users,
      url: `/dashboard/parents?department=5`,
      color: "from-emerald-500/10 to-emerald-600/5 hover:border-emerald-500 text-emerald-600"
    },
    {
      title: "عرض الأبناء (الرياضيين)",
      desc: "قائمة الرياضيين المسجلين والمستبين لأكاديمية الأوس",
      icon: Heart,
      url: `/dashboard/athletes?department=5`,
      color: "from-sky-500/10 to-sky-600/5 hover:border-sky-500 text-sky-600"
    },
    {
      title: "إدارة الاشتراكات",
      desc: "عرض، إضافة، وتجديد الباقات لأكاديمية الأوس",
      icon: CreditCard,
      url: `/dashboard/memberships?department=5`,
      color: "from-green-500/10 to-green-600/5 hover:border-green-500 text-green-600"
    },
    {
      title: "طلبات التسجيل المعلقة",
      desc: "مراجعة واعتماد طلبات الانتساب والتسجيل الجديدة للأكاديمية",
      icon: ShieldCheck,
      url: `/dashboard/registrations?department=5`,
      color: "from-amber-500/10 to-amber-600/5 hover:border-amber-500 text-amber-600"
    }
  ]

  const actionCards = academyId === "4" ? ahliCards : awsCards
  const themeColor = department.color || "#0F4C81"

  return (
    <div className="space-y-8">
      
      {/* ── Header Badge Section ── */}
      <div className="bg-white rounded-3xl border border-gray-200/80 p-6 sm:p-8 shadow-sm flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
        <div className="flex items-center gap-4">
          <div 
            className="w-16 h-16 rounded-2xl flex items-center justify-center text-white shadow-md shrink-0 overflow-hidden bg-white border border-gray-100"
          >
            {department.logo ? (
              <img src={department.logo} alt="Logo" className="w-full h-full object-cover" />
            ) : (
              <Building className="w-8 h-8 text-primary" />
            )}
          </div>
          <div>
            <h1 className="text-2xl font-black text-[#0f2942]">{department.name_ar}</h1>
            <p className="text-sm font-semibold text-muted-foreground mt-1">لوحة المدير العام للمركز والأكاديمية</p>
          </div>
        </div>

        <div className="flex items-center gap-2 bg-gray-50 border border-gray-150 rounded-2xl px-4 py-2 self-start sm:self-auto">
          <ShieldCheck className="w-5 h-5 text-emerald-600" />
          <span className="text-sm font-bold text-[#0f2942]">صلاحيات المدير الخاص</span>
        </div>
      </div>

      {/* ── Grid Cards ── */}
      <div>
        <h2 className="text-lg font-extrabold text-[#0f2942] mb-6">العمليات والخدمات السريعة</h2>
        
        <div className="grid gap-6 sm:grid-cols-2">
          {actionCards.map((card, idx) => {
            const Icon = card.icon
            return (
              <motion.button
                key={idx}
                whileHover={{ y: -4 }}
                whileTap={{ scale: 0.99 }}
                onClick={() => navigate(card.url)}
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
