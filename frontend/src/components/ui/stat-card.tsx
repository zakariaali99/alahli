import React, { useRef, useState, useEffect } from "react"
import { LucideIcon, TrendingUp, TrendingDown } from "lucide-react"
import { Card } from "./card"
import { cn } from "@/lib/utils"

function CountUp({ end, duration = 1200 }: { end: number; duration?: number }) {
  const [count, setCount] = useState(0)
  const ref = useRef<HTMLSpanElement>(null)
  const started = useRef(false)

  useEffect(() => {
    if (started.current) return
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !started.current) {
          started.current = true
          const start = performance.now()
          const animate = (now: number) => {
            const elapsed = now - start
            const progress = Math.min(elapsed / duration, 1)
            const eased = 1 - Math.pow(1 - progress, 3)
            setCount(Math.floor(eased * end))
            if (progress < 1) requestAnimationFrame(animate)
          }
          requestAnimationFrame(animate)
        }
      },
      { threshold: 0.2 }
    )
    if (ref.current) observer.observe(ref.current)
    return () => observer.disconnect()
  }, [end, duration])

  return <span ref={ref}>{count.toLocaleString("ar-SA-u-nu-latn")}</span>
}

export interface StatCardProps {
  label: string
  value: number
  icon: LucideIcon
  iconBg: string
  glow?: string
  badge?: string | null
  trend?: "up" | "down" | null
  className?: string
}

export function StatCard({
  label,
  value,
  icon: Icon,
  iconBg,
  glow = "shadow-primary/5",
  badge,
  trend,
  className,
}: StatCardProps) {
  return (
    <Card
      variant="spotlight"
      className={cn(
        "flex flex-col gap-4 relative overflow-hidden transition-all duration-300 hover:shadow-xl",
        glow,
        className
      )}
    >
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold text-muted-foreground">{label}</span>
        <div className={cn("p-2 rounded-xl flex items-center justify-center shrink-0 shadow-inner", iconBg)}>
          <Icon className="w-5 h-5" />
        </div>
      </div>

      <div className="flex items-end justify-between mt-1">
        <div className="flex flex-col">
          <span className="text-3xl font-black text-foreground tracking-tight">
            <CountUp end={value} />
          </span>
          {badge && (
            <span className="text-[10px] text-muted-foreground mt-1.5 font-medium">
              {badge}
            </span>
          )}
        </div>

        {trend && (
          <div
            className={cn(
              "flex items-center gap-1 px-2 py-0.5 rounded-lg text-[10px] font-bold shrink-0",
              trend === "up"
                ? "bg-secondary/10 text-secondary border border-secondary/10"
                : "bg-destructive/10 text-destructive border border-destructive/10"
            )}
          >
            {trend === "up" ? (
              <TrendingUp className="w-3.5 h-3.5" />
            ) : (
              <TrendingDown className="w-3.5 h-3.5" />
            )}
            <span>{trend === "up" ? "نمو" : "تراجع"}</span>
          </div>
        )}
      </div>
    </Card>
  )
}
