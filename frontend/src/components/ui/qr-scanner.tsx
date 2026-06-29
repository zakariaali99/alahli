"use client"

import React, { useCallback, useEffect, useRef, useState } from "react"
import { Camera, CameraOff, Loader2 } from "lucide-react"
import { Html5Qrcode, Html5QrcodeSupportedFormats } from "html5-qrcode"
import { cn } from "@/lib/utils"

type Props = {
  onScan: (code: string) => void
  onError?: (error: string) => void
}

export function QRScanner({ onScan, onError }: Props) {
  const scannerRef = useRef<Html5Qrcode | null>(null)
  const [active, setActive] = useState(false)
  const [starting, setStarting] = useState(false)

  const stopCamera = useCallback(async () => {
    const scanner = scannerRef.current
    if (!scanner) {
      setActive(false)
      return
    }

    try {
      if (scanner.isScanning) {
        await scanner.stop()
      }
      await scanner.clear()
    } catch {
      // ignore stop errors from already-stopped instances
    } finally {
      scannerRef.current = null
      setActive(false)
      setStarting(false)
    }
  }, [])

  const startCamera = async () => {
    if (active || starting) return

    setStarting(true)
    // Small delay to ensure any layout calculations or render sync has happened
    await new Promise((resolve) => setTimeout(resolve, 50))
    try {
      const scanner = new Html5Qrcode("qr-reader", {
        formatsToSupport: [Html5QrcodeSupportedFormats.QR_CODE],
        verbose: false,
      })

      scannerRef.current = scanner

      await scanner.start(
        { facingMode: "environment" },
        { fps: 10, qrbox: { width: 220, height: 220 } },
        (decodedText) => {
          onScan(decodedText)
          void stopCamera()
        },
        () => {
          // decode failure callback can stay silent while scanning
        },
      )

      setActive(true)
    } catch (e) {
      console.error(e)
      onError?.("تعذر الوصول إلى الكاميرا. تأكد من منح الصلاحية.")
      await stopCamera()
    } finally {
      setStarting(false)
    }
  }

  useEffect(() => {
    return () => {
      void stopCamera()
    }
  }, [stopCamera])

  return (
    <div className="relative">
      <div className={cn("relative overflow-hidden rounded-xl bg-black", !active && "hidden")}>
        <div className="h-[300px] w-full" id="qr-reader" />
        <div className="absolute inset-0 border-[3px] border-primary/60 rounded-xl pointer-events-none" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-48 h-48 border-2 border-white/60 rounded-lg" />
        <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2">
          <button
            onClick={() => void stopCamera()}
            className="bg-error text-white px-4 py-2 rounded-lg text-xs font-semibold flex items-center gap-2 hover:bg-error/90 transition-all cursor-pointer"
          >
            <CameraOff className="w-4 h-4" />
            إيقاف
          </button>
        </div>
      </div>
      
      {!active && (
        <button
          onClick={() => void startCamera()}
          className="w-full min-h-[220px] bg-surface-container-low rounded-xl border-2 border-dashed border-border/40 flex flex-col items-center justify-center p-8 hover:border-primary transition-colors cursor-pointer group"
        >
          {starting ? (
            <Loader2 className="mb-4 h-12 w-12 animate-spin text-primary" />
          ) : (
            <Camera className="mb-4 h-16 w-16 text-border transition-colors group-hover:text-primary" />
          )}
          <p className="max-w-[200px] text-center text-sm text-muted-foreground">
            {starting ? "جاري تفعيل الكاميرا..." : "انقر لتفعيل الكاميرا ومسح رمز الاستجابة السريعة"}
          </p>
        </button>
      )}
    </div>
  )
}
