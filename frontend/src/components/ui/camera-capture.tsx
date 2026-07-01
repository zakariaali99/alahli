import { useRef, useState, useCallback, type ChangeEvent } from "react"
import { Button } from "./button"
import { Camera, RotateCcw, Check, ImagePlus } from "lucide-react"

interface CameraCaptureProps {
  onCapture: (base64: string) => void
  buttonText?: string
  preview?: string
}

export default function CameraCapture({ onCapture, buttonText = "خذ صورة شخصية", preview }: CameraCaptureProps) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const [open, setOpen] = useState(false)
  const [captured, setCaptured] = useState<string | null>(null)
  const [error, setError] = useState("")
  const [videoReady, setVideoReady] = useState(false)

  const startCamera = useCallback(async () => {
    if (!navigator.mediaDevices?.getUserMedia) {
      setError("الكاميرا غير مدعومة على هذا المتصفح. يمكنك اختيار صورة من الجهاز.")
      return
    }

    try {
      setError("")
      setVideoReady(false)
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "user", width: 512, height: 512 },
      })
      streamRef.current = stream
      if (videoRef.current) {
        videoRef.current.srcObject = stream
      }
      setOpen(true)
      setCaptured(null)
    } catch {
      setError("تعذر الوصول إلى الكاميرا. يمكنك اختيار صورة من الجهاز.")
    }
  }, [])

  const capture = useCallback(() => {
    const video = videoRef.current
    const canvas = canvasRef.current
    if (!video || !canvas) return
    if (video.readyState < 2) return
    canvas.width = 512
    canvas.height = 512
    const ctx = canvas.getContext("2d")
    if (!ctx) return
    ctx.drawImage(video, 0, 0, 512, 512)
    const data = canvas.toDataURL("image/jpeg", 0.8)
    setCaptured(data)
  }, [])

  const confirm = useCallback(() => {
    if (captured) {
      onCapture(captured)
      stopCamera()
    }
  }, [captured, onCapture])

  const stopCamera = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((t) => t.stop())
      streamRef.current = null
    }
    setOpen(false)
  }, [])

  const retake = useCallback(() => {
    setCaptured(null)
    startCamera()
  }, [startCamera])

  const onPickFromDevice = useCallback(() => {
    fileInputRef.current?.click()
  }, [])

  const onFileSelected = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = () => {
      const result = reader.result
      if (typeof result === "string") {
        setCaptured(result)
        onCapture(result)
        setError("")
      }
    }
    reader.onerror = () => {
      setError("تعذر قراءة الصورة. يرجى المحاولة بصورة أخرى.")
    }
    reader.readAsDataURL(file)
    event.target.value = ""
  }, [onCapture])

  return (
    <>
      <div className="flex flex-col items-center gap-2">
        {preview || captured ? (
          <div className="relative w-24 h-24 rounded-full overflow-hidden border-2 border-primary">
            <img src={captured || preview || ""} alt="Preview" className="w-full h-full object-cover" />
          </div>
        ) : (
          <div className="w-24 h-24 rounded-full bg-surface-container-high flex items-center justify-center border-2 border-dashed border-border">
            <Camera className="w-8 h-8 text-muted-foreground" />
          </div>
        )}
        <div className="flex gap-2">
          <Button type="button" variant="outline" size="sm" onClick={startCamera}>
            <Camera className="w-4 h-4 ml-1" />
            {buttonText}
          </Button>
          <Button type="button" variant="secondary" size="sm" onClick={onPickFromDevice}>
            <ImagePlus className="w-4 h-4 ml-1" />
            اختيار من الجهاز
          </Button>
        </div>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={onFileSelected}
        />
        {error && <p className="text-xs text-error text-center">{error}</p>}
      </div>

      {open && (
        <div className="fixed inset-0 z-50 bg-black/90 flex flex-col items-center justify-center p-4">
          <div className="relative w-full max-w-sm">
            <video ref={videoRef} autoPlay playsInline className="w-full rounded-2xl" onPlaying={() => setVideoReady(true)} />
            <canvas ref={canvasRef} className="hidden" />
          </div>

          <div className="flex gap-4 mt-6">
            {captured ? (
              <>
                <Button variant="outline" onClick={retake}>
                  <RotateCcw className="w-4 h-4 ml-1" />
                  إعادة
                </Button>
                <Button onClick={confirm}>
                  <Check className="w-4 h-4 ml-1" />
                  تأكيد
                </Button>
              </>
            ) : (
              <Button onClick={capture} size="lg" className="w-16 h-16 rounded-full" disabled={!videoReady}>
                <Camera className="w-6 h-6" />
              </Button>
            )}
          </div>

          <Button variant="ghost" className="mt-4 text-white" onClick={stopCamera}>
            إلغاء
          </Button>
        </div>
      )}
    </>
  )
}
