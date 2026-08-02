import { Component, type ErrorInfo, type ReactNode } from "react"
import { Button } from "@/components/ui/button"

type Props = {
  children: ReactNode
}

type State = {
  hasError: boolean
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false }

  static getDerivedStateFromError(): State {
    return { hasError: true }
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error("[ErrorBoundary]", error, errorInfo)
  }

  handleReset = () => {
    this.setState({ hasError: false })
  }

  handleReload = () => {
    this.setState({ hasError: false })
    window.location.reload()
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="flex flex-col items-center justify-center rounded-3xl border border-error/20 bg-error/5 p-8 text-center my-6 gap-3">
          <p className="text-base font-extrabold text-error">تعذر تحميل المحتوى (قد يكون بسبب ضعف اتصال الإنترنت)</p>
          <p className="text-xs text-muted-foreground max-w-sm">
            يرجى التأكد من الاتصال بالشبكة والمحاولة مرة أخرى.
          </p>
          <div className="flex items-center gap-3 mt-2">
            <Button onClick={this.handleReset} size="sm" className="font-bold">
              إعادة المحاولة
            </Button>
            <Button onClick={this.handleReload} size="sm" variant="outline">
              تحديث الصفحة
            </Button>
          </div>
        </div>
      )
    }

    return this.props.children
  }
}
