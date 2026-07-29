import { useState, useEffect } from "react"
import { Link } from "react-router-dom"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { api } from "@/lib/api"
import { extractResults } from "@/lib/response"
import type { Department } from "@/lib/types"
import {
  Users,
  CreditCard,
  Smartphone,
} from "lucide-react"

export default function Landing() {
  const [departments, setDepartments] = useState<Department[]>([])

  useEffect(() => {
    api.get("/departments/")
      .then((res) => {
        const list = extractResults<Department>(res)
        if (list.length >= 2) setDepartments(list)
      })
      .catch(() => {})
  }, [])

  const ahli = departments.length >= 2 ? departments[0] : null
  const aws = departments.length >= 2 ? departments[1] : null

  const scrollToSection = (id: string) => {
    const element = document.getElementById(id)
    if (element) {
      element.scrollIntoView({ behavior: "smooth" })
    }
  }

  return (
    <div className="min-h-screen bg-white text-[#0f2942] flex flex-col font-sans selection:bg-[#047857]/10 selection:text-[#047857]" dir="rtl">
      
      {/* ── Header ── */}
      <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-gray-100 shadow-sm transition-all duration-300">
        <div className="mx-auto flex h-20 w-full max-w-7xl items-center justify-between px-3 sm:px-6 lg:px-8">
          
          <div className="flex items-center gap-2 sm:gap-3 cursor-pointer" onClick={() => scrollToSection("hero")}>
            <img src="/logo.png" alt="Logo" className="h-9 w-9 sm:h-12 sm:w-12 object-contain" />
            <div className="flex flex-col">
              <span className="text-sm sm:text-base font-extrabold text-[#0f2942] leading-tight block md:hidden">الأهلي والأوس</span>
              <span className="text-base font-extrabold text-[#0f2942] leading-tight hidden md:block">مركز الأهلي الرياضي وأكاديمية الأوس</span>
              <span className="text-[11px] sm:text-xs text-[#5f7288] font-semibold">مصراتة - ليبيا</span>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="hidden md:flex items-center gap-8 text-sm font-bold">
            <button 
              onClick={() => scrollToSection("hero")} 
              className="text-[#047857] hover:text-[#047857]/80 transition-colors cursor-pointer"
            >
              الرئيسية
            </button>
            <button 
              onClick={() => scrollToSection("academies")} 
              className="text-[#0f2942] hover:text-[#047857] transition-colors cursor-pointer"
            >
              الأكاديميات
            </button>
            <button 
              onClick={() => scrollToSection("contact")} 
              className="text-[#0f2942] hover:text-[#047857] transition-colors cursor-pointer"
            >
              تواصل معنا
            </button>
          </nav>

          {/* Header Action Buttons */}
          <div className="flex items-center gap-1.5 sm:gap-2">
            <Link to="/login">
              <Button 
                className="bg-[#0f2942] hover:bg-[#0f2942]/90 text-white font-bold px-2.5 sm:px-5 py-1.5 sm:py-2.5 rounded-lg sm:rounded-xl text-[10px] sm:text-sm transition-all cursor-pointer h-auto"
              >
                تسجيل الدخول
              </Button>
            </Link>
            <Link to="/register/athlete">
              <Button 
                className="bg-[#047857] hover:bg-[#047857]/90 text-white font-bold px-2.5 sm:px-5 py-1.5 sm:py-2.5 rounded-lg sm:rounded-xl text-[10px] sm:text-sm transition-all cursor-pointer h-auto"
              >
                تسجيل جديد
              </Button>
            </Link>
          </div>
        </div>
      </header>

      {/* ── Hero Section ── */}
      <section id="hero" className="relative flex flex-col items-center justify-center text-center px-4 py-20 md:py-32 overflow-hidden bg-gradient-to-b from-[#fafafb] to-white">
        
        {/* Soft Background Blurs */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[70vw] h-[70vw] rounded-full bg-gradient-to-br from-[#047857]/5 to-[#0f2942]/5 blur-[120px] -z-10 pointer-events-none" />

        <div className="max-w-4xl mx-auto space-y-6">
          <h1 className="text-4xl font-extrabold tracking-tight text-[#0f2942] sm:text-5xl md:text-6xl leading-[1.15] md:leading-[1.15]">
            منصة مركز الأهلي الرياضي <br className="sm:hidden" /> وأكاديمية الأوس<br className="sm:hidden" /> - مصراتة
          </h1>
          <p className="max-w-2xl mx-auto text-lg md:text-xl text-[#5f7288] font-medium leading-relaxed">
            الحل المتكامل لإدارة الأكاديميات الرياضية والتدريب
          </p>

          <div className="flex flex-wrap items-center justify-center gap-4 pt-4">
            <Link to="/login">
              <Button 
                className="bg-[#0f2942] hover:bg-[#0f2942]/90 text-white font-extrabold px-8 py-3.5 rounded-xl text-base shadow-lg shadow-[#0f2942]/10 transition-all cursor-pointer"
              >
                تسجيل الدخول
              </Button>
            </Link>
            <Link to="/register/athlete">
              <Button 
                className="bg-[#047857] hover:bg-[#047857]/90 text-white font-extrabold px-8 py-3.5 rounded-xl text-base shadow-lg shadow-[#047857]/10 transition-all cursor-pointer"
              >
                تسجيل جديد
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* ── Academies Cards Section ── */}
      <section id="academies" className="py-20 bg-white border-t border-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <div className="grid gap-10 md:grid-cols-2 max-w-5xl mx-auto">
            
            {/* Card 1: Al Ahly Sports Center */}
            <Link to={ahli ? `/academy/${ahli.id}` : "#"} className="block">
              <motion.div 
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5 }}
                className="group bg-white rounded-3xl border border-gray-150 p-6 flex flex-col hover:shadow-xl transition-all duration-300 cursor-pointer"
              >
                <div className="relative aspect-[16/10] w-full">
                  <div className="w-full h-full rounded-2xl overflow-hidden shadow-inner bg-gray-50">
                    <img 
                      src="/alahli_center.png" 
                      alt="Al Ahly Sports Center" 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                    />
                  </div>
                  
                  {/* Logo Overlay */}
                  <div className="absolute bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2 w-16 h-16 rounded-full border-4 border-white bg-white shadow-md flex items-center justify-center overflow-hidden z-20">
                    <img src="/logo.png" alt="Logo" className="w-12 h-12 object-contain" />
                  </div>
                </div>

                <div className="mt-10 text-center space-y-2">
                  <h3 className="text-2xl font-extrabold text-[#0f2942] group-hover:text-[#047857] transition-colors">مركز الأهلي الرياضي</h3>
                  <p className="text-sm font-semibold text-[#5f7288]">اضغط للاطلاع على التفاصيل والرياضات</p>
                </div>
              </motion.div>
            </Link>

            {/* Card 2: Al Aws Academy */}
            <Link to={aws ? `/academy/${aws.id}` : "#"} className="block">
              <motion.div 
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.15 }}
                className="group bg-white rounded-3xl border border-gray-150 p-6 flex flex-col hover:shadow-xl transition-all duration-300 cursor-pointer"
              >
                <div className="relative aspect-[16/10] w-full">
                  <div className="w-full h-full rounded-2xl overflow-hidden shadow-inner bg-gray-50">
                    <img 
                      src="/alaws_academy.png" 
                      alt="Al Aws Academy" 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                    />
                  </div>
                  
                  {/* Logo Overlay */}
                  <div className="absolute bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2 w-16 h-16 rounded-full border-4 border-white bg-white shadow-md flex items-center justify-center overflow-hidden z-20">
                    <img src="/alaws_logo.png" alt="Logo" className="w-full h-full object-cover" />
                  </div>
                </div>

                <div className="mt-10 text-center space-y-2">
                  <h3 className="text-2xl font-extrabold text-[#0f2942] group-hover:text-[#047857] transition-colors">أكاديمية الأوس</h3>
                  <p className="text-sm font-semibold text-[#5f7288]">اضغط للاطلاع على التفاصيل والرياضات</p>
                </div>
              </motion.div>
            </Link>

          </div>
        </div>
      </section>

      {/* ── System Features Section ── */}
      <section id="features" className="py-20 bg-[#fafafb] border-t border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <div className="text-center max-w-3xl mx-auto mb-16 space-y-3">
            <h2 className="text-3xl font-extrabold text-[#0f2942]">النظام البسيطة باستحقاقات</h2>
          </div>

          <div className="grid gap-8 md:grid-cols-3 max-w-6xl mx-auto">
            
            {/* Feature 1: Phone Login */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="bg-white rounded-3xl p-8 border border-gray-100 flex flex-col items-center text-center space-y-4 hover:shadow-md transition-shadow"
            >
              <div className="w-14 h-14 rounded-2xl bg-[#047857]/10 flex items-center justify-center text-[#047857]">
                <Smartphone className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-extrabold text-[#0f2942]">الدخول برقم الهاتف فقط</h3>
              <p className="text-sm font-medium text-[#5f7288] leading-relaxed">
                الدخول برقم الهاتف فقط لاستخدام التطبيق ولا تحتاج إلى كلمة مرور في كل مرة.
              </p>
            </motion.div>

            {/* Feature 2: Parent Portal */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.1 }}
              className="bg-white rounded-3xl p-8 border border-gray-100 flex flex-col items-center text-center space-y-4 hover:shadow-md transition-shadow"
            >
              <div className="w-14 h-14 rounded-2xl bg-[#047857]/10 flex items-center justify-center text-[#047857]">
                <Users className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-extrabold text-[#0f2942]">بوابة أولياء الأمور لعدة أطفال</h3>
              <p className="text-sm font-medium text-[#5f7288] leading-relaxed">
                بوابة أولياء الأمور لربط العائلة ومتابعة الأبناء من أولياء الأمور لعدة أطفال.
              </p>
            </motion.div>

            {/* Feature 3: Subscription & Payments */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.2 }}
              className="bg-white rounded-3xl p-8 border border-gray-100 flex flex-col items-center text-center space-y-4 hover:shadow-md transition-shadow"
            >
              <div className="w-14 h-14 rounded-2xl bg-[#047857]/10 flex items-center justify-center text-[#047857]">
                <CreditCard className="w-7 h-7" />
              </div>
              <h3 className="text-xl font-extrabold text-[#0f2942]">إدارة الاشتراكات والمدفوعات</h3>
              <p className="text-sm font-medium text-[#5f7288] leading-relaxed">
                اختيار الباقات المناسبة وتجديد الاشتراكات بسهولة، مع إمكانية رفع إيصال الدفع أو التحويل المصرفي للمراجعة الفورية.
              </p>
            </motion.div>

          </div>
        </div>
      </section>

      {/* ── Contact & Footer ── */}
      <footer id="contact" className="bg-[#0f2942] text-white py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center space-y-4">
          <p className="text-lg md:text-xl font-extrabold tracking-wide">
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
