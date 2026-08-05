import Hero from "@/components/landing/Hero";
import HowItWorks from "@/components/landing/HowItWorks";
import TrustSection from "@/components/landing/TrustSection";
import Pricing from "@/components/landing/Pricing";
import FAQ from "@/components/landing/FAQ";
import CTASection from "@/components/landing/CTASection";

export default function HomePage() {
  return (
    <>
      <Hero />
      <HowItWorks />
      <TrustSection />
      <Pricing compact />
      <FAQ />
      <CTASection />
    </>
  );
}
