import { Link } from "react-router-dom";

export default function AdminGlobalSettings() {
  return (
    <div className="max-w-3xl space-y-6">
      <div>
        <h2 className="text-2xl font-extrabold">الإعدادات العامة</h2>
        <p className="text-sm text-muted-foreground mt-1">
          إعدادات على مستوى المنصة كاملة.
        </p>
      </div>
      <div className="bg-card rounded-2xl border border-border p-5 space-y-3">
        <h3 className="font-bold">معلومات المنصة</h3>
        <p className="text-sm text-muted-foreground">
          هذه نسخة تجريبية. الحماية بالكامل ستضاف لاحقاً عند توفّر Vendor API.
        </p>
        <Link to="/admin/stores" className="text-primary font-bold text-sm">
          إدارة المتاجر →
        </Link>
      </div>
    </div>
  );
}
