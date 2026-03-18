import { AuthFormCard } from "@/features/auth/auth-form-card";

export default function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-6 py-10">
      <AuthFormCard mode="login" />
    </main>
  );
}
