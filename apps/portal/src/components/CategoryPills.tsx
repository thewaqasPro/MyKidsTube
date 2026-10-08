import React from 'react';
import type { Category } from '@/types/video';

interface CategoryPillsProps {
  categories: Category[];
  selectedCategoryId: string;
  onSelectCategory: (id: string) => void;
}

interface CategoryMeta {
  emoji: string;
  label: string;
  activeClass: string;
}

const CATEGORY_META: Record<string, CategoryMeta> = {
  all: {
    emoji: '🌟',
    label: 'All Fun',
    activeClass: 'bg-gradient-to-r from-[#38BDF8] to-[#0EA5E9] text-[#080C16] shadow-[0_3px_0_0_#0284C7]',
  },
  shorts: {
    emoji: '⚡',
    label: 'Fun Reels',
    activeClass: 'bg-gradient-to-r from-[#FF6B6B] to-[#FF5E62] text-white shadow-[0_3px_0_0_#D93B3E]',
  },
  cartoons: {
    emoji: '🎨',
    label: 'Cartoons',
    activeClass: 'bg-gradient-to-r from-[#F472B6] to-[#EC4899] text-white shadow-[0_3px_0_0_#BE185D]',
  },
  learning: {
    emoji: '🚀',
    label: 'Learning & Play',
    activeClass: 'bg-gradient-to-r from-[#34D399] to-[#10B981] text-white shadow-[0_3px_0_0_#047857]',
  },
  music: {
    emoji: '🎵',
    label: 'Songs & Dance',
    activeClass: 'bg-gradient-to-r from-[#FBBF24] to-[#FFB300] text-[#1E1B4B] shadow-[0_3px_0_0_#D97706]',
  },
  nature: {
    emoji: '🦁',
    label: 'Animals & Nature',
    activeClass: 'bg-gradient-to-r from-[#FB923C] to-[#F97316] text-white shadow-[0_3px_0_0_#C2410C]',
  },
};

export const CategoryPills: React.FC<CategoryPillsProps> = ({
  categories,
  selectedCategoryId,
  onSelectCategory,
}) => {
  const allCategoryItem: Category = { id: 'all', name: 'All Fun' };
  const allList = [allCategoryItem, ...categories];

  return (
    <div className="sticky top-16 z-20 bg-[#0B0F19]/95 backdrop-blur-md border-b border-[#1E294B] shadow-sm">
      <div className="flex items-center gap-2.5 px-4 sm:px-6 py-3 overflow-x-auto no-scrollbar scroll-smooth">
        {allList.map((cat) => {
          const isSelected = selectedCategoryId === cat.id;
          const meta = CATEGORY_META[cat.id] || {
            emoji: '🎈',
            label: cat.name.replace(/^[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\s]+/u, '').trim(),
            activeClass: 'bg-gradient-to-r from-[#A855F7] to-[#8B5CF6] text-white shadow-[0_3px_0_0_#7E22CE]',
          };

          return (
            <button
              key={cat.id}
              onClick={() => onSelectCategory(cat.id)}
              className={`flex items-center gap-2 whitespace-nowrap px-4 py-2 rounded-full font-display text-[13.5px] transition-all select-none cursor-pointer shrink-0 ${
                isSelected
                  ? `${meta.activeClass} font-bold scale-[1.03]`
                  : 'bg-[#151D33] text-[#94A3B8] border border-[#243052] hover:bg-[#1D2845] hover:text-white font-semibold'
              }`}
            >
              <span className="text-[15px]">{meta.emoji}</span>
              <span>{meta.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
};
