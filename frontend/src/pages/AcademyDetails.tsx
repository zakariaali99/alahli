import { useParams, useNavigate, Link } from "react-router-dom"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import {
  ArrowRight,
  Sparkles,
  Trophy,
  Dumbbell,
  ShieldCheck,
  MapPin,
  CheckCircle2,
  Activity,
} from "lucide-react"

interface AcademyData {
  id: string
  name: string
  nameAr: string
  subtitle: string
  color: string
  logo?: string
  heroImage: string
  description: string
  programs: {
    title: string
    icon: any
    desc: string
    features: string[]
  }[]
  gallery: {
    title: string
    image: string
  }[]
}

const ACADEMIES_DATA: Record<string, AcademyData> = {
  "4": {
    id: "4",
    name: "Al Ahli Sports Center",
    nameAr: "مركز الأهلي الرياضي",
    subtitle: "مصراتة - ليبيا",
    color: "#0F4C81",
    logo: "/logo.png",
    heroImage: "/alahli_center.png",
    description: "مركز رياضي متكامل مخصص لبناء الأجيال الرياضية الواعدة وتطوير مهارات القوة والمرونة والدفاع عن النفس في بيئة تربوية ورياضية آمنة ومجهزة بأحدث الصالات والمعدات.",
    programs: [
      {
        title: "قسم الكاراتيه وأبطال النادي",
        icon: ShieldCheck,
        desc: "تدريبات احترافية مخصصة للأطفال والشباب لبناء الانضباط الذاتي واللياقة العالية وتعلم فنون الدفاع عن النفس (الكاتا والكوميتيه).",
        features: [
          "قاعة تاتامي مجهزة بالكامل ومحاطة بإضاءة طبيعية وأجواء مشجعة",
          "تدرج الأحزمة الرسمية من الحزام الأبيض وحتى الحزام الأسود",
          "تمارين مرونة عالية (الفتحة وتقوية المفاصل والضغط على القبضات)",
          "مشاركة دورية في البطولات المحلية والاستعراضات الرياضية"
        ]
      },
      {
        title: "التمرين السويدي واللياقة البدنية",
        icon: Activity,
        desc: "برنامج بدني شامل يعتمد على التمارين السويدية والكاليستثنيكس لرفع معدلات التحمل والقوة العضلية والرشاقة.",
        features: [
          "تدريبات على العشب الصناعي الخارجي والملاعب المجهزة",
          "تمارين الجذع والبطن باستخدام كرات اللياقة الثقيلة والأثقال",
          "سرعة البديهة والرشاقة باستخدام مخاريط وعوارض التدريب",
          "إشراف مباشر من مدربين متخصصين لضمان الأداء الصحيح"
        ]
      }
    ],
    gallery: [
      { title: "تدريبات الكاراتيه والاستعراض", image: "/alahli_center.png" },
      { title: "حصص القتال والتركيز", image: "/alahli_karate.png" },
      { title: "تمارين اللياقة والسويدي", image: "/alahli_swedish.png" }
    ]
  },
  "5": {
    id: "5",
    name: "Al Aws Academy",
    nameAr: "أكاديمية الأوس",
    subtitle: "مصراتة - ليبيا",
    color: "#136F63",
    logo: "/alaws_logo.png",
    heroImage: "/alaws_academy.png",
    description: "أكاديمية متخصصة في اكتشاف وصقل مواهب كرة القدم والرياضات الجماعية، تهدف لتوفير بيئة تدريبية احترافية تجمع بين الانضباط والرياضة والترفيه.",
    programs: [
      {
        title: "أكاديمية كرة القدم للبراعم والشباب",
        icon: Trophy,
        desc: "برامج تدريبية كروية شاملة لتطوير المهارات التكتيكية والفردية والجماعية للاعبين الصغار والشباب.",
        features: [
          "ملاعب عشب صناعي حديثة ومجهزة بإضاءة وشباك حماية",
          "تدريبات اللياقة والتمرير والتحكم بالكرة تحت إشراف مدربين معتمدين",
          "مهرجانات رياضية دورية (يوم الأوس الرياضي) وتكريم المتميزين",
          "متابعة دورية لحضور وأداء كل رياضي"
        ]
      },
      {
        title: "التدريب الإعدادي البدني",
        icon: Dumbbell,
        desc: "تمارين لياقة بدنية مكملة لتقوية العضلات ومنع الإصابات وتحسين السرعة والتحمل البدني.",
        features: [
          "تدريبات سرعة ورشاقة باستخدام المخاريط والحواجز",
          "تمارين مرونة وإطالة عضلية متقدمة",
          "برامج تناسب جميع الفئات العمرية"
        ]
      }
    ],
    gallery: [
      { title: "تدريبات كرة القدم على العشب", image: "/alaws_academy.png" },
      { title: "تمارين الإعداد البدني", image: "/alahli_swedish.png" },
      { title: "أبطال الكاراتيه والرياضة", image: "/alahli_karate.png" }
    ]
  }
}

export default function AcademyDetails() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()

  // Default to Al Ahly (4) if id not found
  const academy = ACADEMIES_DATA[id || "4"] || ACADEMIES_DATA["4"]

  return (
    <div className="min-h-screen bg-[#fafafb] text-[#0f2942] font-sans selection:bg-[#047857]/10 selection:text-[#047857]" dir="rtl">
      
      {/* ── Header Bar ── */}
      <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-gray-150 shadow-sm transition-all">
        <div className="mx-auto flex h-20 w-full max-w-7xl items-center justify-between px-3 sm:px-6 lg:px-8">
          
          <Link to="/" className="flex items-center gap-2 sm:gap-3">
            <img src={academy.logo || "/logo.png"} alt="Logo" className="h-9 w-9 sm:h-11 sm:w-11 object-contain rounded-full shadow-sm" />
            <div>
              <span className="text-[11px] sm:text-base font-extrabold text-[#0f2942] block leading-tight">مركز الأهلي الرياضي & أكاديمية الأوس</span>
              <span className="text-[9px] sm:text-xs text-[#5f7288] font-bold">مصراتة - ليبيا</span>
            </div>
          </Link>

          <Button
            onClick={() => navigate("/")}
            variant="ghost"
            className="flex items-center gap-1 sm:gap-2 text-[10px] sm:text-xs font-bold text-[#5f7288] hover:text-[#0f2942] px-2.5 sm:px-4 py-1.5 sm:py-2 h-auto"
          >
            <ArrowRight className="w-3.5 h-3.5" />
            العودة للرئيسية
          </Button>
        </div>
      </header>

      {/* ── Hero Section ── */}
      <section className="relative bg-white border-b border-gray-100 overflow-hidden py-12 md:py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid gap-10 lg:grid-cols-12 items-center">
            
            {/* Info Side */}
            <div className="lg:col-span-7 space-y-6 text-right">
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#047857]/10 text-[#047857] text-xs font-black">
                <Sparkles className="w-3.5 h-3.5" />
                {academy.subtitle}
              </div>

              <h1 className="text-3xl sm:text-4xl md:text-5xl font-black text-[#0f2942] leading-tight">
                {academy.nameAr}
              </h1>

              <p className="text-base md:text-lg text-[#5f7288] font-medium leading-relaxed max-w-2xl">
                {academy.description}
              </p>

              <div className="flex flex-wrap items-center gap-4 pt-2">
                <Link to="/register/athlete">
                  <Button className="bg-[#047857] hover:bg-[#047857]/90 text-white font-extrabold px-8 py-3.5 rounded-xl text-base shadow-lg shadow-[#047857]/20 transition-all cursor-pointer">
                    تسجيل جديد الآن
                  </Button>
                </Link>
                <Link to="/login">
                  <Button variant="outline" className="border-gray-200 text-[#0f2942] hover:bg-gray-50 font-bold px-6 py-3.5 rounded-xl text-base transition-all">
                    تسجيل الدخول
                  </Button>
                </Link>
              </div>
            </div>

            {/* Banner Image Side */}
            <div className="lg:col-span-5">
              <div className="relative rounded-3xl overflow-hidden shadow-2xl border-4 border-white bg-gray-100 aspect-[4/3]">
                <img
                  src={academy.heroImage}
                  alt={academy.nameAr}
                  className="w-full h-full object-cover"
                />
                <div className="absolute top-4 right-4 bg-white/90 backdrop-blur-md px-3.5 py-1.5 rounded-full text-xs font-black text-[#0f2942] shadow-sm flex items-center gap-2">
                  <MapPin className="w-3.5 h-3.5 text-[#047857]" />
                  مصراتة
                </div>
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* ── Sports Programs Section ── */}
      <section className="py-16 md:py-24 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-3">
          <h2 className="text-3xl font-extrabold text-[#0f2942]">البرامج والرياضات المتاحة</h2>
          <p className="text-sm font-semibold text-[#5f7288]">تعرف على الأنشطة والرياضات المتخصصة المتوفرة في الأكاديمية</p>
        </div>

        <div className="grid gap-8 md:grid-cols-2 max-w-5xl mx-auto">
          {academy.programs.map((program, idx) => {
            const Icon = program.icon
            return (
              <motion.div
                key={idx}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.4, delay: idx * 0.1 }}
                className="bg-white rounded-3xl p-8 border border-gray-150 shadow-sm hover:shadow-md transition-all flex flex-col justify-between space-y-6"
              >
                <div className="space-y-4">
                  <div className="w-14 h-14 rounded-2xl bg-[#047857]/10 flex items-center justify-center text-[#047857]">
                    <Icon className="w-7 h-7" />
                  </div>
                  <h3 className="text-2xl font-extrabold text-[#0f2942]">{program.title}</h3>
                  <p className="text-sm font-medium text-[#5f7288] leading-relaxed">
                    {program.desc}
                  </p>
                  
                  <ul className="space-y-2.5 pt-2">
                    {program.features.map((feat, fIdx) => (
                      <li key={fIdx} className="flex items-start gap-2.5 text-xs font-bold text-[#0f2942]">
                        <CheckCircle2 className="w-4 h-4 text-[#047857] shrink-0 mt-0.5" />
                        <span>{feat}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <div className="pt-4 border-t border-gray-100">
                  <Link to="/register/athlete">
                    <Button variant="ghost" className="w-full justify-between text-xs font-black text-[#047857] hover:bg-[#047857]/5 rounded-xl py-2.5">
                      <span>الاشتراك في هذا البرنامج</span>
                      <ArrowRight className="w-4 h-4 rotate-180" />
                    </Button>
                  </Link>
                </div>
              </motion.div>
            )
          })}
        </div>
      </section>

      {/* ── Photo Gallery Section ── */}
      <section className="py-16 bg-white border-t border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <div className="text-center max-w-3xl mx-auto mb-12 space-y-2">
            <h2 className="text-3xl font-extrabold text-[#0f2942]">معرض الصور والتدريبات</h2>
            <p className="text-sm font-semibold text-[#5f7288]">جانب من التدريبات الواقعية والحصص الرياضية في الأكاديمية</p>
          </div>

          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 max-w-6xl mx-auto">
            {academy.gallery.map((item, gIdx) => (
              <motion.div
                key={gIdx}
                initial={{ opacity: 0, scale: 0.95 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ duration: 0.4, delay: gIdx * 0.1 }}
                className="group relative rounded-3xl overflow-hidden border border-gray-150 shadow-sm bg-gray-50 aspect-[4/3]"
              >
                <img
                  src={item.image}
                  alt={item.title}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent flex items-end p-5">
                  <span className="text-sm font-black text-white">{item.title}</span>
                </div>
              </motion.div>
            ))}
          </div>

        </div>
      </section>

      {/* ── Registration Callout Banner ── */}
      <section className="py-16 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-gradient-to-r from-[#0f2942] to-[#00204f] rounded-3xl p-8 sm:p-12 text-white text-center space-y-6 shadow-xl relative overflow-hidden">
          <div className="max-w-2xl mx-auto space-y-4 relative z-10">
            <h2 className="text-3xl font-black">انضم إلى {academy.nameAr} اليوم!</h2>
            <p className="text-sm text-white/80 font-medium leading-relaxed">
              سجل طفلك أو انضم بنفسك لبدء رحلة التدريب والتطوير الرياضي تحت إشراف كادر تدريبي متكامل.
            </p>
            <div className="pt-2">
              <Link to="/register/athlete">
                <Button className="bg-[#047857] hover:bg-[#047857]/90 text-white font-black px-10 py-4 rounded-xl text-base shadow-lg shadow-[#047857]/30 transition-all cursor-pointer">
                  الانتقال لصفحة التسجيل
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* ── Footer ── */}
      <footer className="bg-[#0f2942] text-white py-12 border-t border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center space-y-3">
          <p className="text-base font-extrabold">
            مركز الأهلي الرياضي وأكاديمية الأوس - مصراتة، ليبيا
          </p>
          <p className="text-xs text-white/50 font-medium">
            © {new Date().getFullYear()} جميع الحقوق محفوظة لـ مركز الأهلي الرياضي وأكاديمية الأوس
          </p>
        </div>
      </footer>

    </div>
  )
}
