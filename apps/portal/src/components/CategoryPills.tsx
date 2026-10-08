import React from 'react';
import type { Category } from '../types/video';
import { Zap } from 'lucide-react';

interface CategoryPillsProps {
  categories: Category[];
  selectedCategoryId: string;
  onSelectCategory: (id: string) => void;
}

export const CategoryPills: React.FC<CategoryPillsProps> = ({
  categories,
  selectedCategoryId,
  onSelectCategory,
}) => {
  const allCategoryItem: Category = { id: 'all', name: 'All' };
  const allList = [allCategoryItem, ...categories];

  return (
    <div className="sticky top-14 z-20 bg-[#0F0F0F]/95 backdrop-blur-md border-b border-[#1F1F1F]">
      <div className="flex items-center gap-2 px-4 sm:px-6 py-2.5 overflow-x-auto no-scrollbar scroll-smooth">
        {allList.map((cat) => {
          const isSelected = selectedCategoryId === cat.id;
          const isShorts = cat.id === 'shorts' || cat.name.includes('Shorts');
          const cleanName = cat.name.replace(/^[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\s]+/u, '').trim();

          return (
            <button
              key={cat.id}
              onClick={() => onSelectCategory(cat.id)}
              className={`flex items-center whitespace-nowrap px-3.5 py-1.5 rounded-lg text-[13px] font-medium transition-all select-none cursor-pointer shrink-0 ${
                isSelected
                  ? 'bg-[#F1F1F1] text-[#0F0F0F] font-semibold shadow-sm'
                  : 'bg-[#272727] text-[#F1F1F1] hover:bg-[#383838]'
              }`}
            >
              {isShorts && <Zap className="w-3.5 h-3.5 text-red-500 mr-1.5 shrink-0" />}
              <span>{cleanName}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
};
