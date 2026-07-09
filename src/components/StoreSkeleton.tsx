export const StoreSkeleton = () => {
  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Top bar */}
      <div className="h-9 bg-primary/80 animate-pulse" />
      {/* Header */}
      <div className="container py-3 flex items-center gap-3">
        <div className="h-12 w-12 rounded-full bg-muted animate-pulse" />
        <div className="flex-1 h-11 rounded-full bg-muted animate-pulse" />
        <div className="h-11 w-11 rounded-full bg-muted animate-pulse" />
      </div>
      {/* Hero */}
      <div className="container">
        <div className="h-56 md:h-72 rounded-3xl bg-muted animate-pulse" />
      </div>
      {/* Categories */}
      <div className="container py-8 grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-3">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="aspect-square rounded-2xl bg-muted animate-pulse" />
        ))}
      </div>
      {/* Products */}
      <div className="container py-4 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
        {Array.from({ length: 8 }).map((_, i) => (
          <div key={i} className="aspect-[3/4] rounded-2xl bg-muted animate-pulse" />
        ))}
      </div>
    </div>
  );
};
