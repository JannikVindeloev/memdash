import type { DashboardCard } from "../../lib/types";
import TableView from "./TableView";
import GraphView from "./GraphView";
import ChartView from "./ChartView";
import MetricView from "./MetricView";
import TextView from "./TextView";
import JsonView from "./JsonView";

export default function Visualization({
  card,
  records,
  fields,
}: {
  card: DashboardCard;
  records: Record<string, unknown>[];
  fields: string[];
}) {
  if (card.lastError) {
    return (
      <JsonView
        records={[{ error: card.lastError }]}
        fields={["error"]}
      />
    );
  }
  switch (card.visualization) {
    case "table":
      return <TableView records={records} fields={fields} />;
    case "graph":
      return <GraphView records={records} />;
    case "bar":
    case "line":
    case "pie":
      return <ChartView kind={card.visualization} records={records} fields={fields} />;
    case "metric":
      return <MetricView records={records} fields={fields} />;
    case "text":
      return <TextView records={records} fields={fields} />;
    case "json":
    default:
      return <JsonView records={records} fields={fields} />;
  }
}
