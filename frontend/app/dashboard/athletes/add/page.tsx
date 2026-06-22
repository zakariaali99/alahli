"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hook-form/resolvers/zod";
import * as z from "zod";
import { ArrowRight, User, Phone, Calendar, UserCheck, Tag, Upload, AlertCircle, FileText } from "lucide-react";
import Link from "next/link";
import Image from "next/image";

// Zod validation schema for athlete registration
const athleteSchema = z.object({
  fullName: z
    .string()
    .min(3, { message: "الاسم الكامل يجب أن يكون 3 أحرف على الأقل" })
    .max(50, { message: "الاسم الكامل طويل جداً" }),
  phone: z
    .string()
    .min(9, { message: "رقم الهاتف غير صحيح" })
    .max(15, { message: "رقم الهاتف طويل جداً" }),
  parentPhone: z
    .string()
    .optional(),
  birthDate: z
    .string()
    .min(1, { message: "الرجاء تحديد تاريخ الميلاد" }),
  gender: z
    .enum(["male", "female"], { errorMap: () => ({ message: "الرجاء تحديد الجنس" }) }),
  departmentId: z
    .string()
    .min(1, { message: "الرجاء اختيار القسم أو الفرع الرياضي" }),
  notes: z
    .string()
    .optional(),
});

type AthleteFormData = z.infer<typeof athleteSchema>;

export default function AddAthletePage() {
  const router = useRouter();
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<AthleteFormData>({
    resolver: zodResolver(athleteSchema),
    defaultValues: {
      fullName: "",
      phone: "",
      parentPhone: "",
      birthDate: "",
      gender: "male",
      departmentId: "",
      notes: "",
    },
  });

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setPhotoPreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const onSubmit = async (data: AthleteFormData) => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      // Mock API request to register athlete
      await new Promise((resolve) => setTimeout(resolve, 1000));
      
      // Navigate back to the athletes database list
      router.push("/dashboard/athletes");
    } catch (err: any) {
      setErrorMessage("حدث خطأ أثناء حفظ البيانات. يرجى إعادة المحاولة.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6 select-none">
      {/* Page Header */}
      <div className="flex items-center gap-3">
        <Link href="/dashboard/athletes" className="text-muted-foreground hover:text-foreground transition-colors">
          <ArrowRight className="w-6 h-6" />
        </Link>
        <div>
          <h1 className="text-2xl font-extrabold text-foreground">إضافة رياضي جديد</h1>
          <p className="text-xs text-muted-foreground mt-1">تعبئة نموذج تسجيل رياضي جديد وتحديد الفرع الرياضي له.</p>
        </div>
      </div>

      {errorMessage && (
        <div className="p-4 rounded-xl bg-error/15 border border-error/30 text-error text-sm flex items-center gap-2">
          <AlertCircle className="w-5 h-5 shrink-0" />
          <span>{errorMessage}</span>
        </div>
      )}

      {/* Main Form container */}
      <div className="glass-card rounded-3xl p-6 md:p-8 border border-border/20 shadow-sm">
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
          
          {/* File Upload Section */}
          <div className="flex flex-col sm:flex-row items-center gap-6 pb-6 border-b border-border/20">
            <div className="relative w-28 h-28 rounded-full overflow-hidden bg-surface-container border border-border/40 shrink-0 flex items-center justify-center">
              {photoPreview ? (
                <Image
                  alt="صورة الرياضي"
                  src={photoPreview}
                  fill
                  className="object-cover"
                />
              ) : (
                <User className="w-12 h-12 text-muted-foreground" />
              )}
            </div>
            <div className="flex-1 flex flex-col items-center sm:items-start gap-2">
              <h4 className="text-sm font-bold text-foreground">صورة اللاعب الشخصية</h4>
              <p className="text-xs text-muted-foreground text-center sm:text-right">
                الرجاء رفع صورة واضحة للاعب. الصيغ المدعومة: JPG, PNG. الحجم الأقصى: 2 ميجابايت.
              </p>
              <label className="mt-2 cursor-pointer bg-primary text-primary-foreground text-xs font-semibold px-4 py-2.5 rounded-lg hover:bg-primary/95 transition-all flex items-center gap-2">
                <Upload className="w-4 h-4" />
                تحميل الصورة
                <input
                  type="file"
                  accept="image/*"
                  onChange={handlePhotoUpload}
                  className="hidden"
                />
              </label>
            </div>
          </div>

          {/* Form Fields Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            
            {/* Full Name */}
            <div>
              <label className="block text-sm font-bold text-foreground mb-2" htmlFor="fullName">
                الاسم الكامل للرياضي
              </label>
              <div className="relative">
                <User className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <input
                  id="fullName"
                  type="text"
                  placeholder="أحمد علي الورفلي"
                  {...register("fullName")}
                  className={`w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all ${
                    errors.fullName ? "border-error" : ""
                  }`}
                />
              </div>
              {errors.fullName && (
                <span className="text-xs text-error mt-1.5 block">{errors.fullName.message}</span>
              )}
            </div>

            {/* Phone */}
            <div>
              <label className="block text-sm font-bold text-foreground mb-2" htmlFor="phone">
                رقم الهاتف
              </label>
              <div className="relative">
                <Phone className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <input
                  id="phone"
                  type="tel"
                  placeholder="0911234567"
                  {...register("phone")}
                  className={`w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all ${
                    errors.phone ? "border-error" : ""
                  }`}
                />
              </div>
              {errors.phone && (
                <span className="text-xs text-error mt-1.5 block">{errors.phone.message}</span>
              )}
            </div>

            {/* Parent Phone (minor athletes) */}
            <div>
              <label className="block text-sm font-bold text-foreground mb-2" htmlFor="parentPhone">
                رقم هاتف ولي الأمر (اختياري)
              </label>
              <div className="relative">
                <Phone className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <input
                  id="parentPhone"
                  type="tel"
                  placeholder="0921234567"
                  {...register("parentPhone")}
                  className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all"
                />
              </div>
            </div>

            {/* Birth Date */}
            <div>
              <label className="block text-sm font-bold text-foreground mb-2" htmlFor="birthDate">
                تاريخ الميلاد
              </label>
              <div className="relative">
                <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <input
                  id="birthDate"
                  type="date"
                  {...register("birthDate")}
                  className={`w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all ${
                    errors.birthDate ? "border-error" : ""
                  }`}
                />
              </div>
              {errors.birthDate && (
                <span className="text-xs text-error mt-1.5 block">{errors.birthDate.message}</span>
              )}
            </div>

            {/* Gender */}
            <div>
              <label className="block text-sm font-bold text-foreground mb-2" htmlFor="gender">
                الجنس
              </label>
              <div className="relative">
                <UserCheck className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <select
                  id="gender"
                  {...register("gender")}
                  className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none cursor-pointer appearance-none"
                >
                  <option value="male">ذكر</option>
                  <option value="female">أنثى</option>
                </select>
              </div>
            </div>

            {/* Department */}
            <div>
              <label className="block text-sm font-bold text-foreground mb-2" htmlFor="departmentId">
                الفرع / القسم الرياضي
              </label>
              <div className="relative">
                <Tag className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <select
                  id="departmentId"
                  {...register("departmentId")}
                  className={`w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none cursor-pointer appearance-none ${
                    errors.departmentId ? "border-error" : ""
                  }`}
                >
                  <option value="">اختر القسم...</option>
                  <option value="1">الأهلي للياقة البدنية (نادي رياضي)</option>
                  <option value="2">أكاديمية العوز لكرة القدم (أكاديمية ناشئين)</option>
                  <option value="3">الأهلي للسباحة</option>
                </select>
              </div>
              {errors.departmentId && (
                <span className="text-xs text-error mt-1.5 block">{errors.departmentId.message}</span>
              )}
            </div>
          </div>

          {/* Notes */}
          <div>
            <label className="block text-sm font-bold text-foreground mb-2" htmlFor="notes">
              ملاحظات إضافية
            </label>
            <div className="relative">
              <FileText className="absolute right-3 top-4 text-muted-foreground w-4 h-4" />
              <textarea
                id="notes"
                rows={4}
                placeholder="أدخل أي ملاحظات خاصة بالحالة الصحية أو تفاصيل إضافية للرياضي..."
                {...register("notes")}
                className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all"
              ></textarea>
            </div>
          </div>

          {/* Form Actions */}
          <div className="flex justify-end gap-3 pt-4 border-t border-border/20">
            <Link href="/dashboard/athletes">
              <button
                type="button"
                className="px-6 py-3 rounded-xl border border-border/60 text-sm font-semibold text-muted-foreground hover:bg-surface-container transition-all"
              >
                إلغاء
              </button>
            </Link>
            <button
              type="submit"
              disabled={isLoading}
              className="bg-primary text-primary-foreground font-semibold px-8 py-3 rounded-xl shadow-lg shadow-primary/20 hover:bg-primary/95 transition-all text-sm disabled:opacity-50"
            >
              {isLoading ? "جاري الحفظ..." : "حفظ البيانات"}
            </button>
          </div>

        </form>
      </div>

    </div>
  );
}
