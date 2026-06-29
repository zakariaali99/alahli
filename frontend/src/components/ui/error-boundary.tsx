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

  componentDidCatch(_error: Error, _errorInfo: ErrorInfo) {
    // keep default behavior minimal; avoid crashing the whole shell
  }

  handleReload = () => {
    this.setState({ hasError: false })
    window.location.reload()
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="rounded-2xl border border-destructive/25 bg-destructive/5 p-5 text-center">
          <p className="text-sm font-semibold text-destructive">حدث خطأ أثناء تحميل الصفحة</p>
          <p className="mt-1 text-xs text-muted-foreground">حاول إعادة التحميل للمتابعة.</p>
          <Button className="mt-3" onClick={this.handleReload} size="sm" variant="outline">
            إعادة التحميل
          </Button>
        </div>
      )
    }

    return this.props.children
  }
}
