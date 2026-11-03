import { Box, Typography } from "@mui/material";
import { formatCell } from "../../lib/format";

export default function MetricView({
  records,
  fields,
}: {
  records: Record<string, unknown>[];
  fields: string[];
}) {
  const first = records[0];
  const key = fields[0];
  const value = first && key !== undefined ? formatCell(first[key]) : "—";
  return (
    <Box sx={{ height: "100%", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
      <Typography variant="h3" fontWeight={800} color="primary">
        {value}
      </Typography>
      <Typography variant="body2" color="text.secondary">
        {key ?? ""}
      </Typography>
    </Box>
  );
}
