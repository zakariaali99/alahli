import { useState } from "react"
import { Link } from "react-router-dom"
import { motion, AnimatePresence } from "framer-motion"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import {
  ArrowLeft,
  Award,
  Building2,
  CalendarClock,
  CheckCircle2,
  Dumbbell,
  Menu,
  ShieldCheck,
  Sparkles,
  Users,
  X,
} from "lucide-react"

const features = [
  {
    title: "تسجيل ذاتي فوري",
    body: "إنشاء حساب رياضي أو ولي أمر خلال دقائق مع تدفق واضح ومباشر.",
    icon: Sparkles,
  },
  {
    title: "اشتراك متعدد الخطوات",
    body: "أكاديمية ← رياضة ← مجموعة ← باقة ← دفع. كل خطوة مفهومة وسريعة.",
    icon: CalendarClock,
  },
  {
    title: "إدارة احترافية",
    body: "لوحة إدارية لمراجعة الطلبات، إدارة الباقات، الأكاديميات، والتنبيهات.",
    icon: ShieldCheck,
  },
]

const tracks = [
  {
    title: "مركز اللياقة",
    subtitle: "تدريب بدني متكامل",
    points: ["برامج قوة وتحمل", "خطط متابعة شهرية", "إشراف مدربين متخصصين"],
    tone: "from-[#0F4C81] to-[#1F6AA5]",
    icon: Dumbbell,
  },
  {
    title: "أكاديمية المهارات",
    subtitle: "تطوير فني وذهني",
    points: ["مجموعات حسب المستوى", "جداول أيام وأوقات مرنة", "تقييم أداء دوري"],
    tone: "from-[#136F63] to-[#1E9A8A]",
    icon: Award,
  },
]

export default function Landing() {
  const [mobileOpen, setMobileOpen] = useState(false)

  return (
    <div className="min-h-screen bg-[#f6f8fb] text-[#102033]" dir="rtl">
      <div className="fixed inset-0 pointer-events-none -z-10 overflow-hidden">
        <div className="absolute -top-28 right-[-10%] w-[48vw] h-[48vw] rounded-full bg-[#0F4C81]/12 blur-[120px]" />
        <div className="absolute bottom-[-22%] left-[-12%] w-[56vw] h-[56vw] rounded-full bg-[#136F63]/12 blur-[130px]" />
      </div>

      <header className="sticky top-0 z-40 border-b border-white/70 bg-white/80 backdrop-blur-xl">
        <div className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between px-4 md:px-6">
          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#0F4C81] text-white">
              <Dumbbell className="h-5 w-5" />
            </div>
            <div>
              <p className="text-sm font-extrabold leading-none">منصة الأكاديمية الرياضية</p>
              <p className="mt-1 text-[11px] text-[#4d6178]">إدارة التسجيل والاشتراكات</p>
            </div>
          </div>

          <nav className="hidden items-center gap-3 md:flex">
            <Link className="rounded-lg px-3 py-2 text-sm font-semibold text-[#0F4C81] hover:bg-[#0F4C81]/8" to="/register/athlete">
              تسجيل رياضي
            </Link>
            <Link className="rounded-lg px-3 py-2 text-sm font-semibold text-[#0F4C81] hover:bg-[#0F4C81]/8" to="/register/parent">
              تسجيل ولي أمر
            </Link>
            <Link className="rounded-xl border border-[#0F4C81]/20 bg-white px-4 py-2 text-sm font-bold text-[#0F4C81] hover:bg-[#0F4C81]/8" to="/login">
              تسجيل الدخول
            </Link>
          </nav>

          <button className="rounded-lg p-2 text-[#0F4C81] md:hidden" onClick={() => setMobileOpen((v) => !v)}>
            {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>

        <AnimatePresence>
          {mobileOpen && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              exit={{ opacity: 0, height: 0 }}
              className="overflow-hidden border-t border-white/80 bg-white/95 px-4 pb-4 pt-2 md:hidden"
            >
              <div className="grid gap-2">
                <Link className="rounded-lg px-3 py-2 text-sm font-semibold text-[#0F4C81] hover:bg-[#0F4C81]/8" onClick={() => setMobileOpen(false)} to="/register/athlete">
                  تسجيل رياضي
                </Link>
                <Link className="rounded-lg px-3 py-2 text-sm font-semibold text-[#0F4C81] hover:bg-[#0F4C81]/8" onClick={() => setMobileOpen(false)} to="/register/parent">
                  تسجيل ولي أمر
                </Link>
                <Link className="rounded-xl border border-[#0F4C81]/20 bg-white px-4 py-2 text-center text-sm font-bold text-[#0F4C81] hover:bg-[#0F4C81]/8" onClick={() => setMobileOpen(false)} to="/login">
                  تسجيل الدخول
                </Link>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </header>

      <main className="mx-auto w-full max-w-6xl px-4 pb-16 pt-10 md:px-6 md:pt-16">
        <section className="grid items-center gap-6 lg:grid-cols-2">
          <div className="space-y-6">
            <span className="inline-flex items-center gap-2 rounded-full border border-[#0F4C81]/15 bg-white/85 px-3 py-1 text-xs font-bold text-[#0F4C81] shadow-sm">
              <Sparkles className="h-3.5 w-3.5" /> منصة رقمية متكاملة للأكاديميات
            </span>
            <h1 className="text-3xl font-black leading-tight text-[#102033] md:text-5xl tracking-tight">
              إدارة التسجيل والاشتراكات
              <span className="block bg-gradient-to-l from-[#0F4C81] to-[#136F63] bg-clip-text text-transparent mt-1">
                بتجربة فاخرة وسريعة
              </span>
            </h1>
            <p className="max-w-xl text-sm leading-7 text-[#4d6178] md:text-base">
              نظام شامل يربط بين الرياضي وولي الأمر والإدارة ضمن تدفق واضح: من التسجيل بالكاميرا إلى
              اعتماد الاشتراك وإدارة التنبيهات.
            </p>
            <div className="flex flex-col gap-3 sm:flex-row">
              <Link to="/register/athlete">
                <Button variant="pill" size="pill-md" className="gap-2 bg-[#0F4C81] hover:bg-[#0F4C81]/95 text-white shadow-lg shadow-[#0F4C81]/20 w-full sm:w-auto">
                  ابدأ كرياضي
                  <ArrowLeft className="h-4 w-4" />
                </Button>
              </Link>
              <Link to="/register/parent">
                <Button variant="pill-outline" size="pill-md" className="border-[#136F63]/25 text-[#136F63] hover:bg-[#136F63]/8 w-full sm:w-auto">
                  ابدأ كولي أمر
                </Button>
              </Link>
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            {features.map((item) => {
              const Icon = item.icon
              return (
                <Card
                  key={item.title}
                  variant="interactive"
                  className="p-5 border border-white/80"
                >
                  <div className="mb-3.5 flex h-9 w-9 items-center justify-center rounded-xl bg-[#0F4C81]/10 text-[#0F4C81]">
                    <Icon className="h-4.5 w-4.5" />
                  </div>
                  <h3 className="text-sm font-extrabold text-[#102033]">{item.title}</h3>
                  <p className="mt-2 text-xs leading-6 text-[#4d6178]">{item.body}</p>
                </Card>
              )
            })}
            <Card
              variant="interactive"
              className="p-5 border border-white/80 sm:col-span-2"
            >
              <div className="flex items-center gap-2 text-[#136F63]">
                <Users className="h-4.5 w-4.5" />
                <p className="text-xs font-bold">سير عمل واضح ومترابط</p>
              </div>
              <p className="mt-2 text-xs leading-6 text-[#4d6178]">
                التسجيل الذاتي ← اختيار الأكاديمية والرياضة والمجموعة ← اختيار الباقة ← تحديد طريقة الدفع ←
                مراجعة الإدارة واعتماد الاشتراك.
              </p>
            </Card>
          </div>
        </section>

        <section className="mt-12 grid gap-4 md:grid-cols-2">
          {tracks.map((track) => {
            const Icon = track.icon
            return (
              <Card key={track.title} variant="glass" className="overflow-hidden p-0 border border-white/80">
                <div className={`bg-gradient-to-l ${track.tone} p-5 text-white`}>
                  <div className="flex items-center gap-2.5">
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/20 backdrop-blur-sm">
                      <Icon className="h-5 w-5" />
                    </div>
                    <div>
                      <h3 className="text-lg font-black">{track.title}</h3>
                      <p className="text-xs text-white/90">{track.subtitle}</p>
                    </div>
                  </div>
                </div>
                <div className="space-y-3.5 p-5 bg-white/40 dark:bg-transparent">
                  {track.points.map((point) => (
                    <p key={point} className="flex items-center gap-2 text-sm text-[#24384d] dark:text-[#c8d6e5]">
                      <CheckCircle2 className="h-4 w-4 text-[#136F63]" /> {point}
                    </p>
                  ))}
                </div>
              </Card>
            )
          })}
        </section>

        <Card variant="glass" className="mt-12 border border-white/80 p-5 md:p-7">
          <div className="grid gap-5 md:grid-cols-3">
            <div className="rounded-2xl border border-[#0F4C81]/10 bg-[#0F4C81]/5 p-5">
              <Building2 className="mb-2.5 h-5 w-5 text-[#0F4C81]" />
              <p className="text-sm font-extrabold text-[#102033]">إدارة الأكاديميات</p>
              <p className="mt-1.5 text-xs leading-5 text-[#4d6178]">إنشاء الأكاديميات والرياضات والمجموعات وربطها بالمدربين.</p>
            </div>
            <div className="rounded-2xl border border-[#136F63]/10 bg-[#136F63]/5 p-5">
              <ShieldCheck className="mb-2.5 h-5 w-5 text-[#136F63]" />
              <p className="text-sm font-extrabold text-[#102033]">اعتمادات آمنة</p>
              <p className="mt-1.5 text-xs leading-5 text-[#4d6178]">كل حساب جديد يبقى Pending حتى الاشتراك والموافقة الإدارية.</p>
            </div>
            <div className="rounded-2xl border border-[#A63F3F]/10 bg-[#A63F3F]/5 p-5">
              <CalendarClock className="mb-2.5 h-5 w-5 text-[#A63F3F]" />
              <p className="text-sm font-extrabold text-[#102033]">تنبيهات انتهاء الاشتراكات</p>
              <p className="mt-1.5 text-xs leading-5 text-[#4d6178]">عرض فوري للاشتراكات المنتهية والقريبة من الانتهاء.</p>
            </div>
          </div>
        </Card>
      </main>
    </div>
  )
}
