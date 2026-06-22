"use client"

import React, { useEffect, useRef, useState } from "react"
import { QrCode, Camera, CameraOff, Loader2 } from "lucide-react"

type Props = {
  onScan: (code: string) => void
  onError?: (error: string) => void
}

export function QRScanner({ onScan, onError }: Props) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const [active, setActive] = useState(false)
  const [stream, setStream] = useState<MediaStream | null>(null)

  const startCamera = async () => {
    try {
      const s = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" } })
      setStream(s)
      if (videoRef.current) {
        videoRef.current.srcObject = s
      }
      setActive(true)
    } catch (err) {
      onError?.("تعذر الوصول إلى الكاميرا. تأكد من منح الصلاحية.")
    }
  }

  const stopCamera = () => {
    if (stream) {
      stream.getTracks().forEach((track) => track.stop())
      setStream(null)
    }
    setActive(false)
  }

  useEffect(() => {
    return () => {
      if (stream) {
        stream.getTracks().forEach((track) => track.stop())
      }
    }
  }, [stream])

  const handleVideoClick = () => {
    if (!active) {
      startCamera()
    } else {
      stopCamera()
    }
  }

  return (
    <div className="relative">
      {active ? (
        <div className="relative overflow-hidden rounded-xl bg-black">
          <video
            ref={videoRef}
            autoPlay
            playsInline
            muted
            className="w-full h-[300px] object-cover"
          />
          <div className="absolute inset-0 border-[3px] border-primary/60 rounded-xl pointer-events-none" />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-48 h-48 border-2 border-white/60 rounded-lg" />
          <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2">
            <button
              onClick={stopCamera}
              className="bg-error text-white px-4 py-2 rounded-lg text-xs font-semibold flex items-center gap-2 hover:bg-error/90 transition-all"
            >
              <CameraOff className="w-4 h-4" />
              إيقاف
            </button>
          </div>
        </div>
      ) : (
        <button
          onClick={startCamera}
          className="w-full min-h-[220px] bg-surface-container-low rounded-xl border-2 border-dashed border-border/40 flex flex-col items-center justify-center p-8 hover:border-primary transition-colors cursor-pointer group"
        >
          <Camera className="w-16 h-16 text-border group-hover:text-primary mb-4 transition-colors" />
          <p className="text-muted-foreground text-sm text-center max-w-[200px]">انقر لتفعيل الكاميرا ومسح رمز الاستجابة السريعة</p>
        </button>
      )}
    </div>
  )
}
