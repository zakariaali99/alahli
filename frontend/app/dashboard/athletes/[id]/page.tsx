"use client";

import React from "react";
import { useParams, useRouter } from "next/navigation";
import { ArrowRight, Edit, RefreshCw, Printer, Shield, Dumbbell, Calendar, Heart, ShieldAlert, Award, Receipt } from "lucide-react";
import Link from "next/link";
import Image from "next/image";

export default function AthleteProfilePage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;

  // Mock athlete detail retrieval
  const athlete = {
    id: id || "ATH-2026-001",
    name: "أحمد محمد عبدلله",
    role: "فريق كرة القدم - فئة الشباب (تحت 18)",
    phone: "+218 91 123 4567",
    parentPhone: "+218 92 987 6543",
    birthDate: "15 مارس 2008",
    joinDate: "01 سبتمبر 2024",
    email: "ahmed.m@example.com",
    nationalId: "1029384756",
    status: "active",
    statusText: "نشط",
    height: "182 سم",
    weight: "75 كجم",
    position: "مهاجم",
    gender: "ذكر",
    department: "أكاديمية كرة القدم",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuB2vUeQofTR5h4szVYR4-c8A3iFlbp71vRoiNbofNPAMjshypN-yU_T_YowBeTortG9c8wbXNs6MqAuoBgRtxy4q3kT4i2-wojx0Xmu_-9yhwWpGaAjqLsT-WM2WHCeDT9czHQgx1rnCbeyRLC-ECICF71za1AHfLDkqVrNI_hFcNpxQxmZHqTpgf6-SNzMpHPiZsBC6v1xFmmCjk0KwxyvYhuLxerETgwO7KnPeesrgt0IBJgYgdF_LbJIv0yfs5tEo18I2zQVMHU",
    subscription: {
      planName: "باقة المحترفين سنوي",
      startDate: "01 يناير 2026",
      endDate: "31 ديسمبر 2026",
      daysRemaining: 192,
      percent: 60,
      price: "1,200 د.ل",
    },
    history: [
      { plan: "باقة المحترفين سنوي", start: "01 يناير 2026", end: "31 ديسمبر 2026", amount: "1,200 د.ل", status: "نشط" },
      { plan: "باقة الأكاديمية أساسي", start: "01 يناير 2025", end: "31 ديسمبر 2025", amount: "900 د.ل", status: "منتهي" },
      { plan: "باقة الأكاديمية أساسي", start: "01 سبتمبر 2024", end: "31 ديسمبر 2024", amount: "300 د.ل", status: "منتهي" },
    ]
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="space-y-6 select-none print:bg-white print:text-black">
      {/* Background Decor */}
      <div className="fixed top-0 left-0 w-full h-full overflow-hidden -z-10 pointer-events-none print:hidden">
        <div className="absolute top-[-10%] right-[-5%] w-[40vw] h-[40vw] rounded-full bg-primary/5 blur-3xl"></div>
        <div className="absolute bottom-[-10%] left-[-5%] w-[30vw] h-[30vw] rounded-full bg-secondary/5 blur-3xl"></div>
      </div>

      {/* Breadcrumbs & Action Buttons */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6 print:hidden">
        <div className="flex items-center gap-2 text-muted-foreground text-sm font-semibold">
          <Link href="/dashboard/athletes" className="hover:text-primary transition-colors">
            اللاعبين
          </Link>
          <ChevronLeftIcon className="w-4 h-4" />
          <span className="text-primary font-bold">ملف اللاعب</span>
        </div>
        <div className="flex items-center gap-3 w-full md:w-auto">
          <button
            onClick={handlePrint}
            className="flex-1 md:flex-none flex items-center justify-center gap-2 px-5 py-2.5 bg-white border border-border/65 text-primary text-sm font-bold rounded-xl hover:bg-muted transition-colors shadow-sm"
          >
            <Printer className="w-4 h-4" />
            طباعة البطاقة
          </button>
          <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-5 py-2.5 bg-white border border-border/65 text-primary text-sm font-bold rounded-xl hover:bg-muted transition-colors shadow-sm">
            <Edit className="w-4 h-4" />
            تعديل البيانات
          </button>
          <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-5 py-2.5 bg-primary text-primary-foreground text-sm font-bold rounded-xl hover:bg-primary/95 transition-all shadow-lg shadow-primary/20">
            <RefreshCw className="w-4 h-4" />
            تجديد الاشتراك
          </button>
        </div>
      </div>

      {/* Bento Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Profile Card Banner (8 cols) */}
        <div className="lg:col-span-8 glass-card rounded-[2rem] p-6 md:p-8 relative overflow-hidden flex flex-col sm:flex-row items-center sm:items-start gap-6">
          <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-bl from-primary/10 to-transparent rounded-bl-full pointer-events-none"></div>
          
          {/* Avatar Container */}
          <div className="relative shrink-0">
            <div className="w-32 h-32 md:w-36 md:h-36 rounded-full overflow-hidden border-4 border-white shadow-xl relative z-10">
              <Image
                alt={athlete.name}
                src={athlete.image}
                fill
                priority
                className="object-cover"
              />
            </div>
            <div className="absolute bottom-2 left-2 z-20 bg-secondary-container text-on-secondary-container text-[11px] font-bold px-3 py-1 rounded-full border-2 border-white flex items-center gap-1 shadow-sm">
              <span className="w-2 h-2 rounded-full bg-secondary"></span>
              {athlete.statusText}
            </div>
          </div>

          {/* Profile Name & Tag Info */}
          <div className="flex-1 text-center sm:text-right pt-2 relative z-10">
            <h2 className="text-2xl md:text-3xl font-extrabold text-foreground mb-2">{athlete.name}</h2>
            <p className="text-sm text-muted-foreground mb-4">{athlete.role}</p>
            
            <div className="flex flex-wrap justify-center sm:justify-start gap-3 mt-4">
              <div className="bg-surface-container-low px-4 py-2 rounded-xl flex items-center gap-2 border border-border/20 text-xs font-semibold text-foreground">
                <Shield className="w-4 h-4 text-primary" />
                <span>{athlete.position}</span>
              </div>
              <div className="bg-surface-container-low px-4 py-2 rounded-xl flex items-center gap-2 border border-border/20 text-xs font-semibold text-foreground">
                <Dumbbell className="w-4 h-4 text-primary" />
                <span>{athlete.height}</span>
              </div>
              <div className="bg-surface-container-low px-4 py-2 rounded-xl flex items-center gap-2 border border-border/20 text-xs font-semibold text-foreground">
                <Heart className="w-4 h-4 text-primary" />
                <span>{athlete.weight}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Digital Membership Card (4 cols) */}
        <div className="lg:col-span-4 glass-card rounded-[2rem] p-6 flex flex-col items-center justify-center text-center relative overflow-hidden group">
          <div className="absolute inset-0 bg-gradient-to-br from-surface-container-highest/20 to-transparent pointer-events-none"></div>
          <div className="w-full flex justify-between items-center mb-6 relative z-10">
            <h3 className="text-lg font-bold text-foreground">بطاقة العضوية</h3>
            <button onClick={handlePrint} className="text-primary hover:bg-primary/10 p-2 rounded-full transition-colors">
              <Printer className="w-4 h-4" />
            </button>
          </div>
          
          {/* Card Frame with Dynamic Brand colors (e.g. Al Ahly Blue Gradient) */}
          <div className="w-full max-w-[260px] bg-gradient-to-tr from-[#00204f] to-[#1a3668] rounded-2xl p-4 text-white shadow-xl relative overflow-hidden flex flex-col items-center gap-3">
            <div className="absolute top-[-20px] left-[-20px] w-24 h-24 bg-white/5 rounded-full blur-xl"></div>
            <div className="flex justify-between items-center w-full pb-2 border-b border-white/10">
              <span className="text-[10px] uppercase font-bold tracking-wider opacity-85">بطاقة هوية رياضية</span>
              <Award className="w-4 h-4 text-amber-400" />
            </div>
            
            {/* QR Scanner server link */}
            <div className="bg-white p-3 rounded-xl border border-white/20 my-2 relative z-10 transition-all duration-300">
              <Image
                alt="QR Code"
                src={`https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=${athlete.id}`}
                width={120}
                height={120}
                className="opacity-90"
              />
            </div>
            <div className="w-full text-center">
              <div className="text-xs font-semibold">{athlete.name}</div>
              <div className="text-[10px] opacity-75 mt-1 font-mono tracking-widest">{athlete.id}</div>
            </div>
          </div>
        </div>

        {/* Basic Info (6 cols) */}
        <div className="lg:col-span-6 glass-card rounded-[1.5rem] p-6 flex flex-col">
          <div className="flex items-center gap-2 mb-6 pb-4 border-b border-border/20">
            <div className="w-8 h-8 rounded-lg bg-primary-container/20 text-primary flex items-center justify-center shrink-0">
              <User className="w-4 h-4" />
            </div>
            <h3 className="text-base font-bold text-foreground">المعلومات الأساسية</h3>
          </div>
          
          <div className="grid grid-cols-2 gap-y-6 gap-x-4 flex-1 text-sm">
            <div>
              <p className="text-xs text-muted-foreground mb-1">رقم الهوية / الإقامة</p>
              <p className="text-foreground font-semibold">{athlete.nationalId}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">رقم الهاتف</p>
              <p className="text-foreground font-semibold" dir="ltr">{athlete.phone}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">تاريخ الميلاد</p>
              <p className="text-foreground font-semibold">{athlete.birthDate}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">تاريخ الانضمام</p>
              <p className="text-foreground font-semibold">{athlete.joinDate}</p>
            </div>
            <div className="col-span-2">
              <p className="text-xs text-muted-foreground mb-1">البريد الإلكتروني</p>
              <p className="text-foreground font-semibold">{athlete.email}</p>
            </div>
          </div>
        </div>

        {/* Subscription details (6 cols) */}
        <div className="lg:col-span-6 glass-card rounded-[1.5rem] p-6 flex flex-col border-l-4 border-l-secondary">
          <div className="flex justify-between items-center mb-6 pb-4 border-b border-border/20">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-secondary-container/20 text-secondary flex items-center justify-center shrink-0">
                <Award className="w-4 h-4" />
              </div>
              <h3 className="text-base font-bold text-foreground">تفاصيل الاشتراك الحالي</h3>
            </div>
            <span className="bg-secondary/15 text-secondary text-xs font-bold px-3 py-1 rounded-full">{athlete.subscription.planName}</span>
          </div>

          <div className="flex-1 flex flex-col justify-between text-sm">
            <div className="grid grid-cols-2 gap-y-4 gap-x-4 mb-4">
              <div>
                <p className="text-xs text-muted-foreground mb-1">تاريخ البدء</p>
                <p className="text-foreground font-semibold flex items-center gap-1.5">
                  <Calendar className="w-4 h-4 text-muted-foreground" />
                  {athlete.subscription.startDate}
                </p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground mb-1">تاريخ الانتهاء</p>
                <p className="text-foreground font-semibold flex items-center gap-1.5">
                  <Calendar className="w-4 h-4 text-muted-foreground" />
                  {athlete.subscription.endDate}
                </p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground mb-1">قيمة الاشتراك</p>
                <p className="text-foreground font-bold">{athlete.subscription.price}</p>
              </div>
            </div>

            {/* Progress bar info */}
            <div className="mt-4">
              <div className="flex justify-between items-end mb-2 text-xs">
                <span className="text-muted-foreground">المدة الزمنية المتبقية</span>
                <span className="text-secondary font-bold">{athlete.subscription.daysRemaining} يوم متبقي</span>
              </div>
              <div className="w-full bg-muted rounded-full h-2 overflow-hidden">
                <div
                  className="bg-secondary h-full rounded-full transition-all duration-500"
                  style={{ width: `${athlete.subscription.percent}%` }}
                ></div>
              </div>
            </div>
          </div>
        </div>

        {/* Subscription ledger (12 cols) */}
        <div className="lg:col-span-12 glass-card rounded-[1.5rem] p-6 overflow-hidden">
          <div className="flex items-center gap-2 mb-6">
            <div className="w-8 h-8 rounded-lg bg-primary-container/20 text-primary flex items-center justify-center shrink-0">
              <Receipt className="w-4 h-4" />
            </div>
            <h3 className="text-base font-bold text-foreground">سجل الاشتراكات والتجديد</h3>
          </div>
          
          <div className="overflow-x-auto w-full">
            <table className="w-full text-right border-collapse min-w-[600px]">
              <thead>
                <tr className="border-b border-border/40 text-muted-foreground text-xs font-semibold bg-surface-container-lowest/50">
                  <th className="py-3 px-4 rounded-tr-xl">الباقة</th>
                  <th className="py-3 px-4">تاريخ البدء</th>
                  <th className="py-3 px-4">تاريخ الانتهاء</th>
                  <th className="py-3 px-4">القيمة</th>
                  <th className="py-3 px-4">الحالة</th>
                  <th className="py-3 px-4 rounded-tl-xl text-center">إيصال الاستلام</th>
                </tr>
              </thead>
              <tbody className="text-sm text-foreground">
                {athlete.history.map((record, index) => (
                  <tr key={index} className="border-b border-border/20 hover:bg-surface-container-low/50 transition-colors group">
                    <td className="py-4 px-4 font-semibold flex items-center gap-2">
                      <span className={`w-2 h-2 rounded-full ${record.status === "نشط" ? "bg-secondary" : "bg-muted-foreground"}`}></span>
                      {record.plan}
                    </td>
                    <td className="py-4 px-4 text-muted-foreground">{record.start}</td>
                    <td className="py-4 px-4 text-muted-foreground">{record.end}</td>
                    <td className="py-4 px-4 font-bold">{record.amount}</td>
                    <td className="py-4 px-4">
                      <span
                        className={`px-2 py-0.5 rounded text-xs font-semibold ${
                          record.status === "نشط"
                            ? "bg-secondary/15 text-secondary"
                            : "bg-muted text-muted-foreground"
                        }`}
                      >
                        {record.status}
                      </span>
                    </td>
                    <td className="py-4 px-4 text-center">
                      <button className="text-primary hover:bg-primary-container/20 p-2 rounded-full transition-colors opacity-0 group-hover:opacity-100 focus:opacity-100">
                        <Receipt className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </div>
  );
}

// Inline chevron Left helper
function ChevronLeftIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="m15 18-6-6 6-6" />
    </svg>
  );
}
