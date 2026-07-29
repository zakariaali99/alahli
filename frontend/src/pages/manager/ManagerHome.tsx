import React from "react"
import { useNavigate } from "react-router-dom"
import { motion } from "framer-motion"
import { Building2, GraduationCap } from "lucide-react"

export default function ManagerHome() {
  const navigate = useNavigate()

  return (
    <div className="flex flex-col items-center justify-center py-12">
      <div className="text-center space-y-3 mb-12">
        <h1 className="text-3xl font-extrabold tracking-tight text-[#0f2942]">أهلاً بك في بوابة الإدارة</h1>
        <p className="text-base text-muted-foreground">اختر الأكاديمية أو المركز للبدء في إدارة وتسيير العمليات الرياضية</p>
      </div>

      <div className="grid gap-8 md:grid-cols-2 w-full max-w-4xl px-4">
        
        {/* Card 1: Al Ahly Sports Center */}
        <motion.button
          whileHover={{ y: -6, scale: 1.01 }}
          whileTap={{ scale: 0.98 }}
          onClick={() => navigate("/manager/4/dashboard")}
          className="group relative flex flex-col items-center text-center p-8 bg-white rounded-3xl border border-gray-200/80 shadow-md hover:shadow-xl transition-all duration-300 overflow-hidden"
        >
          <div className="absolute top-0 right-0 w-24 h-24 bg-[#0F4C81]/5 rounded-bl-full group-hover:bg-[#0F4C81]/10 transition-colors" />
          
          <div className="w-16 h-16 rounded-2xl bg-[#0F4C81]/10 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
            <Building2 className="w-8 h-8 text-[#0F4C81]" />
          </div>

          <h2 className="text-2xl font-black text-[#0f2942] group-hover:text-[#0F4C81] transition-colors mb-2">
            مركز الأهلي الرياضي
          </h2>
          <p className="text-sm font-semibold text-muted-foreground mb-4">
            إدارة تدريبات الكاراتيه، السويدي، اللياقة البدنية والاشتراكات
          </p>
          <span className="text-xs font-bold text-[#0F4C81] bg-[#0F4C81]/10 px-3 py-1 rounded-full">
            دخول لوحة التحكم ←
          </span>
        </motion.button>

        {/* Card 2: Al Aws Academy */}
        <motion.button
          whileHover={{ y: -6, scale: 1.01 }}
          whileTap={{ scale: 0.98 }}
          onClick={() => navigate("/manager/5/dashboard")}
          className="group relative flex flex-col items-center text-center p-8 bg-white rounded-3xl border border-gray-200/80 shadow-md hover:shadow-xl transition-all duration-300 overflow-hidden"
        >
          <div className="absolute top-0 right-0 w-24 h-24 bg-[#136F63]/5 rounded-bl-full group-hover:bg-[#136F63]/10 transition-colors" />
          
          <div className="w-16 h-16 rounded-2xl bg-[#136F63]/10 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
            <GraduationCap className="w-8 h-8 text-[#136F63]" />
          </div>

          <h2 className="text-2xl font-black text-[#0f2942] group-hover:text-[#136F63] transition-colors mb-2">
            أكاديمية الأوس
          </h2>
          <p className="text-sm font-semibold text-muted-foreground mb-4">
            إدارة أكاديمية كرة القدم، أولياء الأمور، الأطفال والاشتراكات
          </p>
          <span className="text-xs font-bold text-[#136F63] bg-[#136F63]/10 px-3 py-1 rounded-full">
            دخول لوحة التحكم ←
          </span>
        </motion.button>

      </div>
    </div>
  )
}
