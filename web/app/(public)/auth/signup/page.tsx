import { AuthFormCard } from "@/features/auth/auth-form-card";

export default function SignupPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-6 py-10">
      <AuthFormCard mode="signup" />
    </main>
  );
}
