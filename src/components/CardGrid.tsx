import { useMemo } from "react";
import { Responsive, WidthProvider, type Layout } from "react-grid-layout";
import { useDashboard } from "../store";
import DashboardCardView from "./DashboardCardView";

const ResponsiveGrid = WidthProvider(Responsive);

export default function CardGrid() {
  const cards = useDashboard((s) => s.cards);
  const setLayout = useDashboard((s) => s.setLayout);

  const layout: Layout[] = useMemo(
    () =>
      cards.map((c) => ({
        i: c.id,
        x: c.position.x,
        y: c.position.y,
        w: c.position.w,
        h: c.position.h,
        minW: 3,
        minH: 2,
      })),
    [cards]
  );

  return (
    <ResponsiveGrid
      className="layout"
      layouts={{ lg: layout }}
      breakpoints={{ lg: 1200, md: 996, sm: 768, xs: 480, xxs: 0 }}
      cols={{ lg: 12, md: 10, sm: 6, xs: 4, xxs: 2 }}
      rowHeight={80}
      margin={[12, 12]}
      onLayoutChange={(l) => {
        for (const item of l) {
          const card = cards.find((c) => c.id === item.i);
          if (
            card &&
            (card.position.x !== item.x ||
              card.position.y !== item.y ||
              card.position.w !== item.w ||
              card.position.h !== item.h)
          ) {
            setLayout(item.i, { x: item.x, y: item.y, w: item.w, h: item.h });
          }
        }
      }}
      draggableHandle=".card-drag-handle"
    >
      {cards.map((card) => (
        <div key={card.id}>
          <DashboardCardView card={card} />
        </div>
      ))}
    </ResponsiveGrid>
  );
}
