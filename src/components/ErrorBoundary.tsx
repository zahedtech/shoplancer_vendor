import { Component, ErrorInfo, ReactNode } from "react";
import { AlertTriangle, RefreshCw } from "lucide-react";
import { reportError } from "@/lib/monitoring";

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
  /**
   * Logical area where this boundary lives (e.g. "home/offers"). Forwarded
   * to the monitoring service so issues are easy to triage per section.
   */
  section?: string;
  /** Active store slug, also forwarded to monitoring. */
  slug?: string;
  /** Extra primitive context (ids, counts, flags…) for the report. */
  context?: Record<string, unknown>;
  /**
   * Called when the user clicks "Retry". Use this to refetch the underlying
   * data (e.g. `queryClient.invalidateQueries(...)`) — the boundary will
   * also clear its own error state automatically.
   */
  onReset?: () => unknown | Promise<unknown>;
}

interface State {
  hasError: boolean;
  error: Error | null;
  isRetrying: boolean;
}

/**
 * Catches render errors in the subtree and shows a friendly message instead
 * of a blank white screen. On retry it both clears its internal error state
 * and triggers an optional `onReset` callback so callers can refetch data.
 */
export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null, isRetrying: false };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error, isRetrying: false };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    reportError(error, {
      section: this.props.section,
      slug: this.props.slug,
      extra: this.props.context,
      componentStack: info.componentStack ?? undefined,
    });
  }

  handleReset = async () => {
    const { onReset } = this.props;
    if (onReset) {
      try {
        this.setState({ isRetrying: true });
        await onReset();
      } catch (err) {
        reportError(err, {
          section: this.props.section,
          slug: this.props.slug,
          extra: { ...(this.props.context ?? {}), phase: "retry" },
        });
      }
    }
    this.setState({ hasError: false, error: null, isRetrying: false });
  };

  handleReload = () => {
    if (typeof window !== "undefined") window.location.reload();
  };

  render() {
    if (!this.state.hasError) return this.props.children;
    if (this.props.fallback) return this.props.fallback;

    const { isRetrying } = this.state;

    return (
      <div
        role="alert"
        className="mx-auto my-6 max-w-md text-center bg-card border border-border/60 rounded-2xl shadow-soft p-6"
      >
        <div className="mx-auto h-14 w-14 rounded-2xl bg-destructive/10 text-destructive inline-flex items-center justify-center mb-4">
          <AlertTriangle className="h-7 w-7" />
        </div>
        <h3 className="text-base font-extrabold text-foreground">
          حدث خطأ غير متوقع
        </h3>
        <p className="text-sm text-muted-foreground mt-1.5">
          تعذّر عرض هذا القسم. يمكنك المحاولة مرة أخرى أو إعادة تحميل الصفحة.
        </p>
        {this.state.error?.message && (
          <p className="mt-3 text-xs text-muted-foreground/80 break-words">
            {this.state.error.message}
          </p>
        )}
        <div className="mt-4 flex items-center justify-center gap-2">
          <button
            onClick={this.handleReset}
            disabled={isRetrying}
            className="inline-flex items-center gap-1.5 h-10 px-4 rounded-full bg-primary text-primary-foreground text-sm font-bold shadow-soft hover:bg-primary-glow transition-smooth disabled:opacity-60"
          >
            <RefreshCw className={`h-4 w-4 ${isRetrying ? "animate-spin" : ""}`} />
            {isRetrying ? "جارٍ المحاولة…" : "إعادة المحاولة"}
          </button>
          <button
            onClick={this.handleReload}
            className="inline-flex items-center h-10 px-4 rounded-full bg-muted text-foreground text-sm font-bold hover:bg-muted/80 transition-smooth"
          >
            تحديث الصفحة
          </button>
        </div>
      </div>
    );
  }
}
