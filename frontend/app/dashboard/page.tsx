"use client";

import React from "react";
import { Download, Plus, Users, ShieldAlert, CheckCircle, Clock, TrendingUp, Sparkles, Building2, Flame } from "lucide-react";
import Image from "next/image";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";

const chartData = [
  { name: "يناير", value: 120 },
  { name: "فبراير", value: 180 },
  { name: "مارس", value: 135 },
  { name: "أبريل", value: 240 },
  { name: "مايو", value: 285 },
  { name: "يونيو", value: 210 },
];

const branches = [
  {
    name: "الأهلي للياقة البدنية",
    revenue: "850,000 د.ل",
    percent: 75,
    growth: "+8%",
    color: "bg-primary",
  },
  {
    name: "أكاديمية العوز",
    revenue: "420,000 د.ل",
    percent: 45,
    growth: "+12%",
    color: "bg-secondary",
  },
];

const recentAthletes = [
  {
    id: "#4592",
    name: "عمر عبدالله",
    date: "12 مايو 2026",
    sport: "كرة القدم - العوز",
    plan: "احترافي 6 شهور",
    status: "نشط",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuCUaAsN3xxdmNVLRCGJdUYqrHAAfhLnPM4eydm0WoNwSpOTFwwU_uTKAWLa1OuJF-ikQkoffGwIOpkk3002SZ2VpZyGPmlHNPAaMoAwAO0sV1OhW-h85fZYLbBYdBMsvnzwz0aWIhW8UXiELR4QIG3A8-evkkyx0QMB3b23lN5Kqjaux-iW0bICmuF9Tfn7ZVLrwHzUud41r5Qnet3XKl2ggQ1t0N1tgEHb6pA5F9upSSawh8hteOXEIQc8k3HVMQiXK8TJHRKLyAk",
  },
  {
    id: "#4591",
    name: "سارة محمد",
    date: "11 مايو 2026",
    sport: "لياقة بدنية - الأهلي",
    plan: "أساسي 3 شهور",
    status: "نشط",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuCWUZAhgCqZ9J_iTjCgiJhIp0W0V3a3NFvqc3UNRzrDwVwS6LTWFcIhoZgJJU8W-x6gIqkocNIk4JZUqZlGvG6FbzrG8vtTxYZB0PWxerqyC_QGM_kDor-BmAwyviJgkGSRHG65JsI4s81sc5NgwqFc_Lj-0K2oh8mZePtHOCMMmNspV6wcaUY_oCTtT4gKKcwwx2LOa7x-XBsL-YiBlP3B5piAraqvyFjHe7-4qAIlDDZB1ZzeSpc8_7Gcq7esO1D_rnrAkrV2uhk",
  },
  {
    id: "#4590",
    name: "خالد سعيد",
    date: "10 مايو 2026",
    sport: "سباحة - الأهلي",
    plan: "شهر واحد",
    status: "قيد المراجعة",
    image: null,
  },
];

export default function DashboardPage() {
  return (
    <div className="space-y-8 select-none">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
        <div>
          <h2 className="text-3xl font-extrabold text-foreground flex items-center gap-2">
            مرحباً بك، الكابتن أحمد
            <Flame className="w-8 h-8 text-primary animate-pulse" />
          </h2>
          <p className="text-muted-foreground mt-2 text-sm">
            إليك نظرة عامة على أداء الأكاديمية ونشاط المشتركين اليوم.
          </p>
        </div>
        <div className="flex gap-3">
          <button className="glass-card px-5 py-2.5 rounded-xl text-sm font-semibold text-primary hover:bg-white transition-all flex items-center gap-2">
            <Download className="w-4 h-4" />
            تحميل التقرير
          </button>
          <button className="bg-primary text-primary-foreground px-5 py-2.5 rounded-xl text-sm font-semibold hover:bg-primary/95 transition-all shadow-lg shadow-primary/20 flex items-center gap-2">
            <Plus className="w-4 h-4" />
            إضافة لاعب جديد
          </button>
        </div>
      </div>

      {/* Stats Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Stat Card 1 */}
        <div className="glass-card p-6 rounded-2xl relative overflow-hidden group hover:shadow-lg transition-all">
          <div className="absolute -left-6 -top-6 w-24 h-24 bg-primary/5 rounded-full blur-xl group-hover:bg-primary/10 transition-colors"></div>
          <div className="flex justify-between items-start mb-4">
            <span className="text-sm font-medium text-muted-foreground">إجمالي اللاعبين</span>
            <div className="w-10 h-10 rounded-full bg-primary-container/20 flex items-center justify-center text-primary">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <div className="text-3xl font-bold text-foreground">1,248</div>
          <div className="flex items-center gap-1.5 mt-3 text-secondary text-xs font-semibold">
            <TrendingUp className="w-3.5 h-3.5" />
            <span>+12% هذا الشهر</span>
          </div>
        </div>

        {/* Stat Card 2 */}
        <div className="glass-card p-6 rounded-2xl relative overflow-hidden group hover:shadow-lg transition-all">
          <div className="absolute -left-6 -top-6 w-24 h-24 bg-secondary/5 rounded-full blur-xl group-hover:bg-secondary/10 transition-colors"></div>
          <div className="flex justify-between items-start mb-4">
            <span className="text-sm font-medium text-muted-foreground">اشتراكات نشطة</span>
            <div className="w-10 h-10 rounded-full bg-secondary-container/20 flex items-center justify-center text-secondary">
              <CheckCircle className="w-5 h-5" />
            </div>
          </div>
          <div className="text-3xl font-bold text-foreground">985</div>
          <div className="flex items-center gap-1.5 mt-3 text-secondary text-xs font-semibold">
            <TrendingUp className="w-3.5 h-3.5" />
            <span>+5% هذا الشهر</span>
          </div>
        </div>

        {/* Stat Card 3 */}
        <div className="glass-card p-6 rounded-2xl relative overflow-hidden group hover:shadow-lg transition-all">
          <div className="absolute -left-6 -top-6 w-24 h-24 bg-error/5 rounded-full blur-xl group-hover:bg-error/10 transition-colors"></div>
          <div className="flex justify-between items-start mb-4">
            <span className="text-sm font-medium text-muted-foreground">اشتراكات منتهية</span>
            <div className="w-10 h-10 rounded-full bg-error-container/20 flex items-center justify-center text-error">
              <ShieldAlert className="w-5 h-5" />
            </div>
          </div>
          <div className="text-3xl font-bold text-foreground">142</div>
          <div className="flex items-center gap-1.5 mt-3 text-error text-xs font-semibold">
            <TrendingUp className="w-3.5 h-3.5" className="rotate-180" />
            <span>-2% هذا الشهر</span>
          </div>
        </div>

        {/* Stat Card 4 */}
        <div className="glass-card p-6 rounded-2xl relative overflow-hidden group hover:shadow-lg transition-all">
          <div className="absolute -left-6 -top-6 w-24 h-24 bg-amber-500/5 rounded-full blur-xl group-hover:bg-amber-500/10 transition-colors"></div>
          <div className="flex justify-between items-start mb-4">
            <span className="text-sm font-medium text-muted-foreground">تنتهي قريباً (7 أيام)</span>
            <div className="w-10 h-10 rounded-full bg-amber-500/10 flex items-center justify-center text-amber-600">
              <Clock className="w-5 h-5" />
            </div>
          </div>
          <div className="text-3xl font-bold text-foreground">121</div>
          <div className="flex items-center gap-1.5 mt-3 text-amber-600 text-xs font-semibold">
            <Sparkles className="w-3.5 h-3.5" />
            <span>تتطلب المتابعة والتجديد</span>
          </div>
        </div>
      </div>

      {/* Bento Layout Content */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Chart Section */}
        <div className="glass-card p-6 rounded-3xl lg:col-span-2 flex flex-col min-h-[400px]">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-lg font-bold text-foreground">نمو الاشتراكات الشهري</h3>
            <div className="flex gap-2">
              <button className="px-3 py-1 rounded-full bg-surface-container-low text-xs font-medium text-muted-foreground hover:bg-white transition-colors">أسبوع</button>
              <button className="px-3 py-1 rounded-full bg-primary text-primary-foreground text-xs font-medium shadow-sm">شهر</button>
              <button className="px-3 py-1 rounded-full bg-surface-container-low text-xs font-medium text-muted-foreground hover:bg-white transition-colors">سنة</button>
            </div>
          </div>
          <div className="flex-1 w-full min-h-[280px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" />
                <XAxis dataKey="name" stroke="var(--outline)" fontSize={12} tickLine={false} />
                <YAxis stroke="var(--outline)" fontSize={12} tickLine={false} />
                <Tooltip
                  contentStyle={{ backgroundColor: "var(--card)", borderColor: "var(--border)", borderRadius: "8px" }}
                  labelStyle={{ fontWeight: "bold" }}
                />
                <Bar dataKey="value" fill="var(--primary)" radius={[6, 6, 0, 0]} maxBarSize={48} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Branch / Academy Performance */}
        <div className="glass-card p-6 rounded-3xl flex flex-col justify-between gap-6">
          <div className="space-y-6">
            <h3 className="text-lg font-bold text-foreground">أداء الفروع والأكاديميات</h3>
            <div className="space-y-5">
              {branches.map((branch, index) => (
                <div key={index} className="p-4 rounded-2xl bg-white dark:bg-card border border-border/40 hover:border-primary/50 transition-all">
                  <div className="flex justify-between items-center mb-3">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-muted/60 flex items-center justify-center text-primary">
                        <Building2 className="w-4 h-4" />
                      </div>
                      <span className="text-sm font-bold text-foreground">{branch.name}</span>
                    </div>
                    <span className="bg-secondary/15 text-secondary px-2.5 py-0.5 rounded text-xs font-bold">{branch.growth}</span>
                  </div>
                  <div className="space-y-2">
                    <div className="flex justify-between text-xs text-muted-foreground">
                      <span>إجمالي المبيعات</span>
                      <span className="text-foreground font-semibold">{branch.revenue}</span>
                    </div>
                    <div className="w-full bg-muted rounded-full h-2 overflow-hidden">
                      <div
                        className={`${branch.color} h-full rounded-full transition-all duration-500`}
                        style={{ width: `${branch.percent}%` }}
                      ></div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
          <button className="w-full py-3 rounded-xl border border-border/60 text-sm font-semibold text-muted-foreground hover:bg-surface-container hover:text-primary transition-all">
            عرض التقارير التفصيلية
          </button>
        </div>
      </div>

      {/* Recent Athlete Registrations Table */}
      <div className="glass-card p-6 rounded-3xl">
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-lg font-bold text-foreground">التسجيلات الحديثة للاعبين</h3>
          <button className="text-primary text-sm font-semibold hover:underline">عرض الكل</button>
        </div>
        <div className="overflow-x-auto w-full">
          <table className="w-full text-right border-collapse">
            <thead>
              <tr className="border-b border-border/40 text-muted-foreground text-xs font-semibold">
                <th className="pb-4 pr-4">اللاعب</th>
                <th className="pb-4">تاريخ التسجيل</th>
                <th className="pb-4">الفرع / الرياضة</th>
                <th className="pb-4">الباقة</th>
                <th className="pb-4 pl-4 text-left">الحالة</th>
              </tr>
            </thead>
            <tbody className="text-sm text-foreground">
              {recentAthletes.map((athlete, idx) => (
                <tr key={idx} className="border-b border-border/20 hover:bg-surface-container-low/50 transition-colors">
                  <td className="py-4 pr-4 flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-muted overflow-hidden relative border border-border/50 shrink-0">
                      {athlete.image ? (
                        <Image
                          alt={athlete.name}
                          src={athlete.image}
                          fill
                          sizes="40px"
                          className="object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-muted-foreground bg-primary-container/25 font-bold">
                          {athlete.name[0]}
                        </div>
                      )}
                    </div>
                    <div>
                      <div className="font-semibold text-foreground">{athlete.name}</div>
                      <div className="text-xs text-muted-foreground">ID: {athlete.id}</div>
                    </div>
                  </td>
                  <td className="py-4">{athlete.date}</td>
                  <td className="py-4">{athlete.sport}</td>
                  <td className="py-4">{athlete.plan}</td>
                  <td className="py-4 pl-4 text-left">
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-bold ${
                        athlete.status === "نشط"
                          ? "bg-secondary/15 text-secondary"
                          : "bg-amber-500/15 text-amber-600"
                      }`}
                    >
                      {athlete.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
