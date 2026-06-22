import React, { useState } from "react"
import { useNavigate } from "react-router-dom"
import { motion, type Variants } from "framer-motion"
import { Eye, EyeOff, Lock, User, AlertCircle } from "lucide-react"
import { useAuth } from "@/lib/auth"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.08, delayChildren: 0.2 },
  },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5, ease: [0.22, 1, 0.36, 1] } },
}

export default function LoginPage() {
  const navigate = useNavigate()
  const { login } = useAuth()
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [phone, setPhone] = useState("")
  const [password, setPassword] = useState("")

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!phone.trim() || !password.trim()) {
      setErrorMessage("الرجاء إدخال رقم الهاتف وكلمة المرور")
      return
    }
    setIsLoading(true)
    setErrorMessage(null)
    try {
      await login(phone.trim(), password)
      navigate("/")
    } catch (err: any) {
      setErrorMessage(err.message || "فشل تسجيل الدخول. تحقق من البيانات")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="relative min-h-screen w-full flex items-center justify-center overflow-hidden bg-background">
      {/* Animated mesh gradient background */}
      <div className="absolute inset-0 z-0">
        <div className="absolute inset-0 bg-dot-grid opacity-[0.15]" />
        <div className="absolute inset-0 bg-mesh-gradient" />
        <motion.div
          className="absolute -top-40 -right-40 w-[500px] h-[500px] bg-primary/10 rounded-full blur-3xl"
          animate={{ x: [0, 30, -20, 0], y: [0, -30, 20, 0] }}
          transition={{ duration: 12, repeat: Infinity, ease: "easeInOut" }}
        />
        <motion.div
          className="absolute -bottom-40 -left-40 w-[600px] h-[600px] bg-secondary/10 rounded-full blur-3xl"
          animate={{ x: [0, -20, 30, 0], y: [0, 30, -20, 0] }}
          transition={{ duration: 15, repeat: Infinity, ease: "easeInOut" }}
        />
        <motion.div
          className="absolute top-1/2 left-1/3 w-[300px] h-[300px] bg-amber-500/5 rounded-full blur-3xl"
          animate={{ x: [0, 40, -30, 0], y: [0, -20, 40, 0] }}
          transition={{ duration: 10, repeat: Infinity, ease: "easeInOut" }}
        />
      </div>

      {/* Floating glass card */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        className="relative z-10 w-full max-w-md p-8 m-4"
      >
        <div className="relative">
          <div className="absolute -inset-1 bg-gradient-to-br from-primary/20 via-secondary/10 to-amber-500/10 rounded-3xl blur-xl" />
          <div className="relative bg-white/80 dark:bg-card/80 backdrop-blur-2xl rounded-2xl p-8 border border-white/50 dark:border-white/5 shadow-2xl">
            <motion.div
              variants={containerVariants}
              initial="hidden"
              animate="visible"
              className="space-y-6"
            >
              <motion.div variants={itemVariants} className="flex justify-center">
                <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-primary to-primary-container p-0.5 shadow-lg shadow-primary/20">
                  <div className="w-full h-full rounded-2xl bg-white flex items-center justify-center overflow-hidden">
                    <img
                      alt="شعار مركز الأهلي الرياضي"
                      src="https://lh3.googleusercontent.com/aida-public/AB6AXuCBfpzvwGK-Btr3vkVaDsTwIzQqeI6S__X6lWkXWbRX7HIg3mbGOB9yLTP3BD_lv95xjYRkkAyGNQbOgem92Fx23wG5-9Xewqs2mgq1CIQBophGNlMXB3hZtsmr0YbZ_frVz1fYI6pB_wAfx0tkMlF20P8xdopQyJd2VOjFWsPFTOYDukKe1jF6bHKoOZUtpjXU-kWh0fXTGQDSsXmvkHTeUtonGOsGMO6MbDgw0AhmmUKLhjufn6CGV5V_jexmYkg7qPWOa4iLFOQ"
                      width={70}
                      height={70}
                      className="object-contain p-3"
                    />
                  </div>
                </div>
              </motion.div>

              <motion.div variants={itemVariants} className="text-center">
                <h2 className="text-2xl font-bold text-foreground">تسجيل الدخول</h2>
                <p className="text-sm text-muted-foreground mt-1">مركز الأهلي الرياضي وأكاديمية العوز</p>
              </motion.div>

              {errorMessage && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: "auto" }}
                  className="p-3 rounded-xl bg-destructive/10 border border-destructive/20 text-destructive text-sm flex items-center gap-2"
                >
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{errorMessage}</span>
                </motion.div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
                <motion.div variants={itemVariants}>
                  <label className="block text-sm font-semibold text-foreground mb-1.5" htmlFor="phone">
                    رقم الهاتف
                  </label>
                  <div className="relative group">
                    <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-muted-foreground group-focus-within:text-primary transition-colors">
                      <User className="w-5 h-5" />
                    </div>
                    <input
                      id="phone"
                      type="text"
                      dir="ltr"
                      placeholder="0910000000"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      className="block w-full pl-3 pr-10 py-3 rounded-xl border-2 border-border/50 bg-surface-container-low text-foreground placeholder-muted-foreground focus:outline-none focus:border-primary focus:bg-white transition-all"
                    />
                  </div>
                </motion.div>

                <motion.div variants={itemVariants}>
                  <label className="block text-sm font-semibold text-foreground mb-1.5" htmlFor="password">
                    كلمة المرور
                  </label>
                  <div className="relative group">
                    <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-muted-foreground group-focus-within:text-primary transition-colors">
                      <Lock className="w-5 h-5" />
                    </div>
                    <input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      placeholder="أدخل كلمة المرور"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="block w-full pl-10 pr-10 py-3 rounded-xl border-2 border-border/50 bg-surface-container-low text-foreground placeholder-muted-foreground focus:outline-none focus:border-primary focus:bg-white transition-all"
                    />
                    <div
                      className="absolute inset-y-0 left-0 pl-3 flex items-center cursor-pointer text-muted-foreground hover:text-foreground transition-colors"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                    </div>
                  </div>
                </motion.div>

                <motion.div variants={itemVariants} className="flex items-center justify-between text-xs">
                  <div className="flex items-center">
                    <input
                      id="remember-me"
                      type="checkbox"
                      className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
                    />
                    <label className="mr-2 block text-muted-foreground cursor-pointer" htmlFor="remember-me">
                      تذكرني
                    </label>
                  </div>
                  <a href="#" className="font-medium text-primary hover:text-primary/80 transition-colors">
                    نسيت كلمة المرور؟
                  </a>
                </motion.div>

                <motion.div variants={itemVariants}>
                  <motion.button
                    type="submit"
                    disabled={isLoading}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                    className="w-full flex justify-center py-3.5 px-4 rounded-xl text-sm font-bold text-white bg-gradient-to-r from-primary to-primary-container hover:from-primary/90 hover:to-primary-container/90 shadow-lg shadow-primary/25 hover:shadow-xl hover:shadow-primary/30 transition-all duration-300 disabled:opacity-50"
                  >
                    {isLoading ? (
                      <span className="flex items-center gap-2">
                        <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                        جاري الدخول...
                      </span>
                    ) : (
                      "تسجيل الدخول"
                    )}
                  </motion.button>
                </motion.div>
              </form>
            </motion.div>
          </div>
        </div>
      </motion.div>
    </div>
  )
}
