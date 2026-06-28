import React, { useState } from "react"
import { motion } from "framer-motion"
import {
  Dumbbell,
  Compass,
  CheckCircle2,
  Calendar,
  Smartphone,
  Send,
  HelpCircle,
  Menu,
  X,
  MapPin,
  Users,
  Award,
  Star,
  ChevronLeft,
} from "lucide-react"

export default function Landing() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [fullName, setFullName] = useState("")
  const [phone, setPhone] = useState("")
  const [dob, setDob] = useState("")
  const [interest, setInterest] = useState("")
  const [medical, setMedical] = useState("no")
  const [submitted, setSubmitted] = useState(false)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!fullName || !phone || !interest) return
    setSubmitted(true)
    setTimeout(() => {
      alert("تم إرسال طلب الانضمام بنجاح! سنتواصل معك قريباً لتحديد موعد التقييم.")
      setFullName("")
      setPhone("")
      setDob("")
      setInterest("")
      setMedical("no")
      setSubmitted(false)
    }, 800)
  }

  return (
    <div className="min-h-screen bg-[#f8f9ff] text-[#0b1c30] font-sans antialiased overflow-x-hidden relative" dir="rtl">
      {/* Decorative Background Blobs */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none z-0">
        <div className="absolute w-[600px] h-[600px] -top-[200px] -right-[200px] bg-[#b8c4ff] opacity-40 rounded-full filter blur-[80px]" />
        <div className="absolute w-[500px] h-[500px] top-[40%] -left-[150px] bg-[#79db8d] opacity-30 rounded-full filter blur-[80px]" />
        <div className="absolute w-[700px] h-[700px] -bottom-[300px] right-[10%] bg-[#b8c4ff] opacity-20 rounded-full filter blur-[80px]" />
      </div>

      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 h-20 z-50 transition-all duration-300 w-full bg-white/75 backdrop-blur-md border-b border-white/40 shadow-sm">
        <div className="max-w-[1280px] mx-auto h-full px-6 flex justify-between items-center">
          {/* Brand */}
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#00288e] text-white flex items-center justify-center shadow-lg shadow-[#00288e]/20">
              <Dumbbell className="w-5 h-5" />
            </div>
            <div>
              <h1 className="font-bold text-lg text-[#0b1c30] leading-none">الأهلي للياقة البدنية</h1>
              <p className="text-xs text-[#444653] mt-1 leading-none">إدارة الرياضة</p>
            </div>
          </div>

          {/* Desktop Links */}
          <div className="hidden md:flex items-center gap-8">
            <a className="text-sm font-medium text-[#444653] hover:text-[#00288e] transition-colors" href="#programs">البرامج</a>
            <a className="text-sm font-medium text-[#444653] hover:text-[#00288e] transition-colors" href="#process">آلية العمل</a>
            <a className="text-sm font-medium text-[#444653] hover:text-[#00288e] transition-colors" href="#trust">لماذا نحن</a>
          </div>

          {/* CTA & Mobile Menu Trigger */}
          <div className="flex items-center gap-4">
            <a className="hidden md:inline-flex items-center justify-center px-6 py-2.5 rounded-xl bg-[#00288e] text-white text-sm font-bold hover:bg-[#00288e]/90 transition-colors shadow-lg shadow-[#00288e]/20" href="#register">
              انضم الآن
            </a>
            <a className="hidden md:inline-flex items-center justify-center px-4 py-2.5 rounded-xl border border-[#00288e]/35 text-[#00288e] text-sm font-bold hover:bg-[#00288e]/5 transition-colors" href="#/login">
              لوحة الإدارة
            </a>
            <button className="md:hidden text-[#0b1c30] p-2 hover:bg-black/5 rounded-lg" onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Mobile Navigation Dropdown */}
        {mobileMenuOpen && (
          <div className="md:hidden absolute top-20 left-0 right-0 bg-white/95 backdrop-blur-lg border-b border-gray-200 p-6 flex flex-col gap-4 shadow-xl z-50">
            <a className="text-base font-semibold text-[#0b1c30]" href="#programs" onClick={() => setMobileMenuOpen(false)}>البرامج</a>
            <a className="text-base font-semibold text-[#0b1c30]" href="#process" onClick={() => setMobileMenuOpen(false)}>آلية العمل</a>
            <a className="text-base font-semibold text-[#0b1c30]" href="#trust" onClick={() => setMobileMenuOpen(false)}>لماذا نحن</a>
            <hr className="border-gray-200" />
            <a className="w-full py-3 rounded-xl bg-[#00288e] text-white font-bold text-center" href="#register" onClick={() => setMobileMenuOpen(false)}>
              انضم الآن
            </a>
            <a className="w-full py-3 rounded-xl border border-[#00288e]/30 text-[#00288e] font-bold text-center" href="#/login" onClick={() => setMobileMenuOpen(false)}>
              لوحة الإدارة
            </a>
          </div>
        )}
      </nav>

      {/* Hero Section */}
      <main className="relative z-10">
        <section className="relative pt-32 pb-20 lg:pt-48 lg:pb-28 overflow-hidden px-6">
          <div className="max-w-[1280px] mx-auto grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
            {/* Hero Text */}
            <div className="lg:col-span-6 space-y-6 text-center lg:text-right">
              <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/70 border border-white/50 backdrop-blur-md mb-2 shadow-sm">
                <span className="w-2 h-2 rounded-full bg-[#00288e] animate-pulse"></span>
                <span className="text-xs font-semibold text-[#00288e]">بوابتك نحو الاحتراف الرياضي</span>
              </div>
              <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-[#0b1c30] leading-tight">
                اصنع <span className="text-transparent bg-clip-text bg-gradient-to-l from-[#00288e] to-[#3755c3]">مستقبلك الرياضي</span> مع نخبة الأبطال.
              </h2>
              <p className="text-base md:text-lg text-[#444653] leading-relaxed max-w-2xl mx-auto lg:mx-0">
                سواء كنت تبحث عن بناء لياقتك البدنية بأحدث المعايير العالمية في مركز الأهلي، أو تطمح لاحتراف كرة القدم في أكاديمية العوس، نحن نوفر لك البيئة المتكاملة للنجاح.
              </p>
              <div className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4 pt-4">
                <a className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-[#00288e] text-white text-base font-bold hover:bg-[#00288e]/95 transition-all shadow-lg shadow-[#00288e]/25 flex items-center justify-center gap-2 group" href="#register">
                  سجل بياناتك الآن
                  <ChevronLeft className="w-5 h-5 transition-transform group-hover:-translate-x-1" />
                </a>
                <a className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-white/60 border border-white/50 text-[#0b1c30] text-base font-bold hover:bg-white/90 transition-all flex items-center justify-center gap-2 shadow-sm backdrop-blur-md" href="#programs">
                  اكتشف برامجنا
                </a>
              </div>
            </div>

            {/* Bento Image Grid */}
            <div className="lg:col-span-6 relative mt-12 lg:mt-0">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-4">
                  {/* Image 1: Fitness */}
                  <div className="rounded-3xl overflow-hidden h-64 shadow-xl shadow-[#00288e]/5 relative group border border-white/50">
                    <img
                      className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-700"
                      src="https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=600&q=80"
                      alt="Gym workout"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent flex items-end p-6">
                      <span className="text-white font-bold flex items-center gap-2 text-sm">
                        <Dumbbell className="w-4 h-4 text-white" /> اللياقة البدنية
                      </span>
                    </div>
                  </div>
                  {/* Image 2: Treadmill */}
                  <div className="rounded-3xl overflow-hidden h-48 shadow-xl shadow-[#00288e]/5 relative group border border-white/50">
                    <img
                      className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-700"
                      src="https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=600&q=80"
                      alt="Running track metrics"
                    />
                  </div>
                </div>
                <div className="space-y-4 mt-8">
                  {/* Image 3: Soccer Ball */}
                  <div className="rounded-3xl overflow-hidden h-48 shadow-xl shadow-[#006d30]/5 relative group border border-white/50">
                    <img
                      className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-700"
                      src="https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=600&q=80"
                      alt="Academy Soccer Player"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent flex items-end p-6">
                      <span className="text-white font-bold flex items-center gap-2 text-sm">
                        <Award className="w-4 h-4 text-white" /> أكاديمية العوس
                      </span>
                    </div>
                  </div>
                  {/* Image 4: Coach & Player */}
                  <div className="rounded-3xl overflow-hidden h-64 shadow-xl shadow-[#006d30]/5 relative group border border-white/50">
                    <img
                      className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-700"
                      src="https://images.unsplash.com/photo-1526232761682-d26e03ac148e?auto=format&fit=crop&w=600&q=80"
                      alt="Soccer Coaching"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Programs Section */}
        <section className="py-24 px-6 bg-[#eff4ff]/30 relative" id="programs">
          <div className="max-w-[1280px] mx-auto">
            <div className="text-center max-w-2xl mx-auto mb-16 space-y-4">
              <h3 className="text-3xl font-bold text-[#0b1c30]">مسارات الاحتراف</h3>
              <p className="text-base text-[#444653]">
                اختر المسار الذي يناسب طموحك الرياضي، حيث نقدم برامج متخصصة تحت إشراف نخبة من المدربين المعتمدين.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 lg:gap-12">
              {/* Al-Ahly Fitness Card (Blue) */}
              <div className="bg-white/70 border border-white/50 backdrop-blur-md rounded-3xl p-8 shadow-xl shadow-[#00288e]/5 relative overflow-hidden group">
                <div className="absolute top-0 right-0 w-32 h-32 bg-[#00288e]/5 rounded-bl-full -mr-10 -mt-10 transition-transform group-hover:scale-110" />
                <div className="relative z-10 flex flex-col h-full">
                  <div className="w-16 h-16 rounded-2xl bg-[#00288e]/10 text-[#00288e] flex items-center justify-center mb-6 shadow-inner">
                    <Dumbbell className="w-8 h-8" />
                  </div>
                  <h4 className="text-2xl font-bold text-[#0b1c30] mb-3">مركز الأهلي للياقة البدنية</h4>
                  <p className="text-sm md:text-base text-[#444653] mb-8 flex-grow leading-relaxed">
                    صالة رياضية متكاملة مجهزة بأحدث المعدات العالمية. نقدم برامج تدريب شخصي، تقييم بدني دقيق، وخطط تغذية مخصصة لرفع كفاءتك الرياضية.
                  </p>
                  <ul className="space-y-3.5 mb-8">
                    <li className="flex items-center gap-3 text-sm text-[#0b1c30] font-medium">
                      <CheckCircle2 className="w-5 h-5 text-[#00288e]" />
                      تقييم شامل وتحليل مكونات الجسم
                    </li>
                    <li className="flex items-center gap-3 text-sm text-[#0b1c30] font-medium">
                      <CheckCircle2 className="w-5 h-5 text-[#00288e]" />
                      مدربون شخصيون معتمدون دولياً
                    </li>
                    <li className="flex items-center gap-3 text-sm text-[#0b1c30] font-medium">
                      <CheckCircle2 className="w-5 h-5 text-[#00288e]" />
                      متابعة دورية للأداء والنتائج
                    </li>
                  </ul>
                  <a href="#register" className="w-full py-4 rounded-xl bg-[#00288e] text-white font-bold text-center hover:bg-[#00288e]/90 transition-colors shadow-md">
                    انضم للمركز
                  </a>
                </div>
              </div>

              {/* Al-Aws Academy Card (Green) */}
              <div className="bg-white/70 border border-white/50 backdrop-blur-md rounded-3xl p-8 shadow-xl shadow-[#006d30]/5 relative overflow-hidden group">
                <div className="absolute top-0 right-0 w-32 h-32 bg-[#006d30]/5 rounded-bl-full -mr-10 -mt-10 transition-transform group-hover:scale-110" />
                <div className="relative z-10 flex flex-col h-full">
                  <div className="w-16 h-16 rounded-2xl bg-[#006d30]/10 text-[#006d30] flex items-center justify-center mb-6 shadow-inner">
                    <Compass className="w-8 h-8" />
                  </div>
                  <h4 className="text-2xl font-bold text-[#0b1c30] mb-3">أكاديمية العوس لكرة القدم</h4>
                  <p className="text-sm md:text-base text-[#444653] mb-8 flex-grow leading-relaxed">
                    منصة احترافية لاكتشاف وتطوير المواهب الكروية. نعتمد على مناهج تدريب حديثة تركز على المهارات الفنية، التكتيكية، واللياقة الذهنية.
                  </p>
                  <ul className="space-y-3.5 mb-8">
                    <li className="flex items-center gap-3 text-sm text-[#0b1c30] font-medium">
                      <CheckCircle2 className="w-5 h-5 text-[#006d30]" />
                      برامج تطوير فئات سنية متعددة
                    </li>
                    <li className="flex items-center gap-3 text-sm text-[#0b1c30] font-medium">
                      <CheckCircle2 className="w-5 h-5 text-[#006d30]" />
                      مشاركات في بطولات محلية وإقليمية
                    </li>
                    <li className="flex items-center gap-3 text-sm text-[#0b1c30] font-medium">
                      <CheckCircle2 className="w-5 h-5 text-[#006d30]" />
                      تأهيل فني ونفسي متكامل للاعب
                    </li>
                  </ul>
                  <a href="#register" className="w-full py-4 rounded-xl bg-[#006d30] text-white font-bold text-center hover:bg-[#006d30]/90 transition-colors shadow-md">
                    انضم للأكاديمية
                  </a>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Join Request Form Section */}
        <section className="py-24 px-6 relative" id="register">
          <div className="max-w-[1000px] mx-auto">
            <div className="bg-white/70 border border-white/50 backdrop-blur-md rounded-[2rem] p-8 md:p-12 shadow-xl shadow-gray-100/50">
              <div className="text-center mb-10 space-y-3">
                <span className="inline-block px-4 py-1.5 rounded-full bg-[#00288e]/10 text-[#00288e] text-xs font-bold">
                  طلب انضمام
                </span>
                <h3 className="text-3xl font-bold text-[#0b1c30]">سجل بياناتك الآن</h3>
                <p className="text-sm text-[#444653]">خطوتك الأولى نحو بناء مسيرتك الرياضية الاحترافية.</p>
              </div>

              <form onSubmit={handleSubmit} className="space-y-8">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* Full Name */}
                  <div className="space-y-2">
                    <label className="block text-sm font-semibold text-[#0b1c30]" htmlFor="fullName">الاسم الرباعي</label>
                    <input
                      className="w-full bg-gray-50 border border-transparent rounded-xl px-4 py-3 text-sm text-[#0b1c30] placeholder-gray-400 focus:bg-white focus:border-[#00288e] focus:ring-4 focus:ring-[#00288e]/10 outline-none transition-all"
                      id="fullName"
                      placeholder="أدخل اسمك الكامل"
                      type="text"
                      required
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                    />
                  </div>

                  {/* Phone */}
                  <div className="space-y-2">
                    <label className="block text-sm font-semibold text-[#0b1c30]" htmlFor="phone">رقم الجوال</label>
                    <div className="relative">
                      <div className="absolute inset-y-0 right-0 flex items-center pr-4 pointer-events-none text-gray-400">
                        <Smartphone className="w-5 h-5" />
                      </div>
                      <input
                        className="w-full bg-gray-50 border border-transparent rounded-xl pr-12 pl-4 py-3 text-sm text-[#0b1c30] placeholder-gray-400 focus:bg-white focus:border-[#00288e] focus:ring-4 focus:ring-[#00288e]/10 outline-none transition-all text-left"
                        dir="ltr"
                        id="phone"
                        placeholder="05X XXX XXXX"
                        type="tel"
                        required
                        value={phone}
                        onChange={(e) => setPhone(e.target.value)}
                      />
                    </div>
                  </div>

                  {/* DOB */}
                  <div className="space-y-2">
                    <label className="block text-sm font-semibold text-[#0b1c30]" htmlFor="dob">تاريخ الميلاد</label>
                    <input
                      className="w-full bg-gray-50 border border-transparent rounded-xl px-4 py-3 text-sm text-[#0b1c30] focus:bg-white focus:border-[#00288e] focus:ring-4 focus:ring-[#00288e]/10 outline-none transition-all"
                      id="dob"
                      type="date"
                      value={dob}
                      onChange={(e) => setDob(e.target.value)}
                    />
                  </div>

                  {/* Program/Track */}
                  <div className="space-y-2">
                    <label className="block text-sm font-semibold text-[#0b1c30]" htmlFor="interest">المسار المطلوب</label>
                    <select
                      className="w-full bg-gray-50 border border-transparent rounded-xl px-4 py-3 text-sm text-[#0b1c30] focus:bg-white focus:border-[#00288e] focus:ring-4 focus:ring-[#00288e]/10 outline-none transition-all cursor-pointer"
                      id="interest"
                      required
                      value={interest}
                      onChange={(e) => setInterest(e.target.value)}
                    >
                      <option disabled value="">اختر المسار الرياضي...</option>
                      <option value="fitness">مركز الأهلي للياقة البدنية</option>
                      <option value="football">أكاديمية العوس لكرة القدم</option>
                      <option value="both">كلاهما</option>
                    </select>
                  </div>
                </div>

                {/* Medical History */}
                <div className="space-y-4 pt-4 border-t border-gray-100">
                  <label className="block text-sm font-semibold text-[#0b1c30]">التاريخ الطبي الأولي</label>
                  <p className="text-xs text-[#444653]">هل تعاني من أي إصابات سابقة أو أمراض مزمنة تتطلب عناية خاصة أثناء التدريب؟</p>
                  <div className="flex gap-6">
                    <label className="flex items-center gap-3 cursor-pointer group">
                      <input
                        className="sr-only peer"
                        name="medical"
                        type="radio"
                        value="no"
                        checked={medical === "no"}
                        onChange={() => setMedical("no")}
                      />
                      <div className="w-5 h-5 rounded-full border-2 border-gray-300 peer-checked:border-[#00288e] peer-checked:bg-[#00288e] flex items-center justify-center transition-all">
                        <div className="w-2 h-2 rounded-full bg-white opacity-0 peer-checked:opacity-100 transition-opacity" />
                      </div>
                      <span className="text-sm text-[#0b1c30] group-hover:text-[#00288e] transition-colors">لا، لائق صحياً</span>
                    </label>

                    <label className="flex items-center gap-3 cursor-pointer group">
                      <input
                        className="sr-only peer"
                        name="medical"
                        type="radio"
                        value="yes"
                        checked={medical === "yes"}
                        onChange={() => setMedical("yes")}
                      />
                      <div className="w-5 h-5 rounded-full border-2 border-gray-300 peer-checked:border-[#00288e] peer-checked:bg-[#00288e] flex items-center justify-center transition-all">
                        <div className="w-2 h-2 rounded-full bg-white opacity-0 peer-checked:opacity-100 transition-opacity" />
                      </div>
                      <span className="text-sm text-[#0b1c30] group-hover:text-[#00288e] transition-colors">نعم، يوجد ملاحظات</span>
                    </label>
                  </div>
                </div>

                {/* Submit */}
                <div className="pt-6">
                  <button
                    className="w-full py-4 rounded-xl bg-[#00288e] text-white font-bold hover:bg-[#00288e]/90 transition-all shadow-lg shadow-[#00288e]/25 flex items-center justify-center gap-2"
                    type="submit"
                    disabled={submitted}
                  >
                    {submitted ? "جاري الإرسال..." : "إرسال الطلب"}
                    <Send className="w-5 h-5" />
                  </button>
                  <p className="text-center text-xs text-[#444653] mt-4">
                    بتقديمك للطلب، أنت توافق على <a className="text-[#00288e] hover:underline" href="#">الشروط والأحكام</a> الخاصة بالنادي.
                  </p>
                </div>
              </form>
            </div>
          </div>
        </section>

        {/* Process Timeline */}
        <section className="py-24 px-6 bg-[#eff4ff]/30 relative" id="process">
          <div className="max-w-[1280px] mx-auto">
            <div className="text-center max-w-2xl mx-auto mb-16 space-y-4">
              <h3 className="text-3xl font-bold text-[#0b1c30]">آلية الانضمام السهلة</h3>
              <p className="text-base text-[#444653]">خطوات بسيطة تفصلك عن بدء رحلتك الرياضية الاحترافية معنا.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
              {/* Desktop Connecting Line */}
              <div className="hidden md:block absolute top-12 left-[15%] right-[15%] h-0.5 bg-gray-200 z-0" />

              {/* Step 1 */}
              <div className="relative z-10 flex flex-col items-center text-center group">
                <div className="w-24 h-24 rounded-3xl bg-white border border-gray-100 flex items-center justify-center mb-6 shadow-lg group-hover:-translate-y-2 transition-transform duration-300 relative">
                  <Users className="w-10 h-10 text-[#00288e]" />
                  <div className="absolute -top-3 -right-3 w-8 h-8 rounded-full bg-[#00288e] text-white font-bold flex items-center justify-center text-sm shadow-md">1</div>
                </div>
                <h4 className="text-lg font-bold text-[#0b1c30] mb-3">التسجيل الإلكتروني</h4>
                <p className="text-sm text-[#444653] px-4 leading-relaxed">قم بتعبئة نموذج الانضمام ببياناتك الأساسية واختيار المسار الرياضي المناسب لك.</p>
              </div>

              {/* Step 2 */}
              <div className="relative z-10 flex flex-col items-center text-center group">
                <div className="w-24 h-24 rounded-3xl bg-white border border-gray-100 flex items-center justify-center mb-6 shadow-lg group-hover:-translate-y-2 transition-transform duration-300 relative">
                  <CheckCircle2 className="w-10 h-10 text-[#00288e]" />
                  <div className="absolute -top-3 -right-3 w-8 h-8 rounded-full bg-[#00288e] text-white font-bold flex items-center justify-center text-sm shadow-md">2</div>
                </div>
                <h4 className="text-lg font-bold text-[#0b1c30] mb-3">المراجعة والتقييم</h4>
                <p className="text-sm text-[#444653] px-4 leading-relaxed">يقوم فريقنا بمراجعة طلبك والتواصل معك لتحديد موعد للتقييم البدني الأولي.</p>
              </div>

              {/* Step 3 */}
              <div className="relative z-10 flex flex-col items-center text-center group">
                <div className="w-24 h-24 rounded-3xl bg-white border border-gray-100 flex items-center justify-center mb-6 shadow-lg group-hover:-translate-y-2 transition-transform duration-300 relative">
                  <Award className="w-10 h-10 text-[#00288e]" />
                  <div className="absolute -top-3 -right-3 w-8 h-8 rounded-full bg-[#00288e] text-white font-bold flex items-center justify-center text-sm shadow-md">3</div>
                </div>
                <h4 className="text-lg font-bold text-[#0b1c30] mb-3">مرحباً بك في النخبة</h4>
                <p className="text-sm text-[#444653] px-4 leading-relaxed">استلم جدولك التدريبي وابدأ رحلتك نحو التميز الرياضي مع أبطالنا.</p>
              </div>
            </div>
          </div>
        </section>

        {/* Stats & Trust */}
        <section className="py-24 px-6 relative" id="trust">
          <div className="max-w-[1280px] mx-auto">
            <div className="text-center max-w-2xl mx-auto mb-16">
              <h3 className="text-3xl font-bold text-[#0b1c30]">لماذا يختارنا الأبطال؟</h3>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
              {/* Stats Grid */}
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-white/70 border border-white/50 backdrop-blur-md rounded-2xl p-6 text-center shadow-sm">
                  <span className="block text-4xl font-extrabold text-[#00288e] mb-2">+50</span>
                  <span className="text-xs text-[#444653] font-bold">مدرب محترف ومعتمد</span>
                </div>
                <div className="bg-white/70 border border-white/50 backdrop-blur-md rounded-2xl p-6 text-center shadow-sm">
                  <span className="block text-4xl font-extrabold text-[#006d30] mb-2">+1200</span>
                  <span className="text-xs text-[#444653] font-bold">لاعب ومتدرب نشط</span>
                </div>
                <div className="bg-white/70 border border-white/50 backdrop-blur-md rounded-2xl p-6 text-center shadow-sm">
                  <span className="block text-4xl font-extrabold text-[#00288e] mb-2">3</span>
                  <span className="text-xs text-[#444653] font-bold">فروع مجهزة بالكامل</span>
                </div>
                <div className="bg-white/70 border border-white/50 backdrop-blur-md rounded-2xl p-6 text-center shadow-sm">
                  <span className="block text-4xl font-extrabold text-[#006d30] mb-2">98%</span>
                  <span className="text-xs text-[#444653] font-bold">نسبة الرضا عن البرامج</span>
                </div>
              </div>

              {/* Testimonial */}
              <div className="bg-white/70 border border-white/50 backdrop-blur-md rounded-3xl p-8 md:p-10 shadow-xl shadow-gray-100/40 relative">
                <div className="flex gap-1 mb-6 text-yellow-500">
                  <Star className="w-5 h-5 fill-current" />
                  <Star className="w-5 h-5 fill-current" />
                  <Star className="w-5 h-5 fill-current" />
                  <Star className="w-5 h-5 fill-current" />
                  <Star className="w-5 h-5 fill-current" />
                </div>
                <p className="text-[#0b1c30] text-base md:text-lg italic mb-8 leading-relaxed">
                  "منذ انضمامي لمركز الأهلي، تغير مفهومي عن اللياقة البدنية تماماً. الاهتمام بالتفاصيل، المتابعة الدقيقة، والبيئة الاحترافية جعلت من التدريب جزءاً لا يتجزأ من نمط حياتي. أنا الآن في أفضل حالة بدنية في حياتي."
                </p>
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-full bg-[#00288e]/10 flex items-center justify-center font-bold text-[#00288e]">
                    أع
                  </div>
                  <div>
                    <h5 className="text-sm font-extrabold text-[#0b1c30]">أحمد عبدالله</h5>
                    <span className="text-xs text-[#444653]">متدرب في برنامج اللياقة المتقدمة</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="w-full py-6 border-t border-gray-200/50 bg-white/40 flex flex-col md:flex-row justify-between items-center px-12 gap-4">
        <div className="text-xs text-[#444653]">
          © 2026 نظام إدارة الأهلي و العوز الرياضي. الإصدار 2.1.0
        </div>
        <div className="flex items-center gap-6 text-xs">
          <a className="text-[#444653] hover:text-[#00288e] transition-colors" href="#">الدعم الفني</a>
          <a className="text-[#444653] hover:text-[#00288e] transition-colors" href="#">الشروط والأحكام</a>
        </div>
      </footer>
    </div>
  )
}
