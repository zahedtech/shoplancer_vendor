import { LogOut } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";

/** Header button that signs the current user out and redirects to /auth. */
export const SignOutButton = ({ className }: { className?: string }) => {
  const navigate = useNavigate();
  const { toast } = useToast();
  return (
    <Button
      type="button"
      variant="ghost"
      size="sm"
      className={className}
      onClick={async () => {
        const { error } = await supabase.auth.signOut();
        if (error) {
          toast({
            title: "تعذّر تسجيل الخروج",
            description: error.message,
            variant: "destructive",
          });
          return;
        }
        navigate("/auth", { replace: true });
      }}
    >
      <LogOut className="h-4 w-4 me-1" />
      <span>خروج</span>
    </Button>
  );
};
