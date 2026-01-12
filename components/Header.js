import Image from 'next/image';
import Link from 'next/link';

export default function Header({ name, logoUrl }) {
  return (
    <header className="pt-20 pb-12">
      {logoUrl ? (
        <div className="flex justify-center mb-4">
          <Image
            src={logoUrl}
            alt={`${name} logo`}
            width={80}
            height={80}
            className="rounded-full shadow-lg ring-4 ring-primary/10 dark:ring-white/10"
            priority
          />
        </div>
      ) : (
        <div className="block w-12 h-12 mx-auto mb-4 rounded-full bg-conic-180 from-gradient-3 from-0% to-gradient-4 to-100%" />
      )}
      <p className="text-2xl text-center dark:text-white">
        <Link href="/">{name}</Link>
      </p>
    </header>
  );
}
