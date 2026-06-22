"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hook-form/resolvers/zod";
import * as z from "zod";
import { Eye, EyeOff, Lock, User, AlertCircle } from "lucide-react";
import Image from "next/image";

// Zod Schema with Arabic validation messages
const loginSchema = z.object({
  identifier: z
    .string()
    .min(1, { message: "الرجاء إدخال رقم الهاتف أو البريد الإلكتروني" }),
  password: z
    .string()
    .min(6, { message: "كلمة المرور يجب أن تكون 6 أحرف على الأقل" }),
  rememberMe: z.boolean().optional(),
});

type LoginFormData = z.infer<typeof loginSchema>;

export default function LoginPage() {
  const router = useRouter();
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      identifier: "",
      password: "",
      rememberMe: false,
    },
  });

  const onSubmit = async (data: LoginFormData) => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      // Mock API delay for responsiveness check
      await new Promise((resolve) => setTimeout(resolve, 800));
      
      // Save mockup session info
      localStorage.setItem("user_token", "mock_jwt_token_ahly");
      localStorage.setItem("user_role", "super_admin");
      localStorage.setItem("user_name", "الكابتن أحمد");

      router.push("/dashboard");
    } catch (err: any) {
      setErrorMessage("حدث خطأ في الاتصال بالخادم. الرجاء المحاولة لاحقاً.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="relative min-h-screen w-full flex items-center justify-center overflow-hidden bg-background">
      {/* Background Graphic */}
      <div className="absolute inset-0 z-0">
        <Image
          alt="Sports Background"
          src="https://lh3.googleusercontent.com/aida-public/AB6AXuAwa0uzV1b-vjPJOV-gLZo6lRXvrck75NQ72M3jfQAXu__4D-uQsPJEncFKW9qjWLT55l9-ny3TFJsy-qM9T8gWziF7sqL-pGb42l8o2RpYbprvJPlkOfN-7q_4PQB5_HQmgTdDokCHspvrkLdQw7Ch7cOL4s5kV_OClOAgvITRtUFt4HTOw6yovQYRNDkegiYZwzF6sk3QfT4-l--ylDMRWt8ECsAifyeUa8pi9B5HClHOURNQDzoNeUNmS9cha6C3XvDMATDABwk"
          fill
          priority
          sizes="100vw"
          className="object-cover object-center"
        />
        <div className="absolute inset-0 bg-black/60 dark:bg-black/75"></div>
      </div>

      {/* Login Card */}
      <div className="relative z-10 w-full max-w-md p-8 m-4 rounded-2xl shadow-2xl glass-card text-on-surface select-none">
        <div className="flex justify-center mb-6">
          <div className="w-20 h-20 rounded-full bg-white p-2 shadow-lg flex items-center justify-center overflow-hidden relative">
            <Image
              alt="شعار مركز الأهلي الرياضي"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuCBfpzvwGK-Btr3vkVaDsTwIzQqeI6S__X6lWkXWbRX7HIg3mbGOB9yLTP3BD_lv95xjYRkkAyGNQbOgem92Fx23wG5-9Xewqs2mgq1CIQBophGNlMXB3hZtsmr0YbZ_frVz1fYI6pB_wAfx0tkMlF20P8xdopQyJd2VOjFWsPFTOYDukKe1jF6bHKoOZUtpjXU-kWh0fXTGQDSsXmvkHTeUtonGOsGMO6MbDgw0AhmmUKLhjufn6CGV5V_jexmYkg7qPWOa4iLFOQ"
              width={70}
              height={70}
              className="object-contain"
            />
          </div>
        </div>

        <h2 className="text-2xl font-bold text-center mb-2 text-white">تسجيل الدخول</h2>
        <p className="text-sm text-center mb-6 text-gray-300">مركز الأهلي الرياضي وأكاديمية العوز</p>

        {errorMessage && (
          <div className="mb-4 p-3 rounded-lg bg-error/25 border border-error text-error text-sm flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{errorMessage}</span>
          </div>
        )}

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
          {/* Identifier Field */}
          <div>
            <label className="block text-sm font-medium text-gray-200 mb-1" htmlFor="identifier">
              رقم الهاتف أو البريد الإلكتروني
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-gray-400">
                <User className="w-5 h-5" />
              </div>
              <input
                id="identifier"
                type="text"
                placeholder="أدخل رقم الهاتف أو البريد"
                {...register("identifier")}
                className={`block w-full pl-3 pr-10 py-3 border rounded-lg bg-white/10 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all backdrop-blur-sm ${
                  errors.identifier ? "border-error" : "border-white/20"
                }`}
              />
            </div>
            {errors.identifier && (
              <span className="text-xs text-error mt-1 block">{errors.identifier.message}</span>
            )}
          </div>

          {/* Password Field */}
          <div>
            <label className="block text-sm font-medium text-gray-200 mb-1" htmlFor="password">
              كلمة المرور
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-gray-400">
                <Lock className="w-5 h-5" />
              </div>
              <input
                id="password"
                type={showPassword ? "text" : "password"}
                placeholder="أدخل كلمة المرور"
                {...register("password")}
                className={`block w-full pl-10 pr-10 py-3 border rounded-lg bg-white/10 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all backdrop-blur-sm ${
                  errors.password ? "border-error" : "border-white/20"
                }`}
              />
              <div
                className="absolute inset-y-0 left-0 pl-3 flex items-center cursor-pointer text-gray-400 hover:text-white transition-colors"
                onClick={() => setShowPassword(!showPassword)}
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </div>
            </div>
            {errors.password && (
              <span className="text-xs text-error mt-1 block">{errors.password.message}</span>
            )}
          </div>

          {/* Remember Me & Forgot Password */}
          <div className="flex items-center justify-between text-xs">
            <div className="flex items-center">
              <input
                id="remember-me"
                type="checkbox"
                {...register("rememberMe")}
                className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary bg-white/10"
              />
              <label className="mr-2 block text-gray-300 cursor-pointer" htmlFor="remember-me">
                تذكرني
              </label>
            </div>
            <div>
              <a href="#" className="font-medium text-white hover:underline transition-all">
                نسيت كلمة المرور؟
              </a>
            </div>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={isLoading}
            className="w-full flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-sm font-bold text-white bg-primary hover:bg-primary-container focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-all duration-300 disabled:opacity-50"
          >
            {isLoading ? "جاري الدخول..." : "تسجيل الدخول"}
          </button>
        </form>
      </div>
    </div>
  );
}
