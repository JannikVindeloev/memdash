import { Box } from "@mui/material";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { formatCell } from "../../lib/format";

export default function TextView({
  records,
  fields,
}: {
  records: Record<string, unknown>[];
  fields: string[];
}) {
  const text = records
    .map((r) => fields.map((f) => formatCell(r[f])).join(" "))
    .join("\n\n");
  return (
    <Box
      sx={{
        height: "100%",
        overflow: "auto",
        typography: "body2",
        "& h1,& h2,& h3": { color: "text.primary" },
        "& a": { color: "primary.main" },
        "& code": { bgcolor: "rgba(255,255,255,0.08)", px: 0.5, borderRadius: 0.5 },
      }}
    >
      <ReactMarkdown remarkPlugins={[remarkGfm]}>{text || "No content"}</ReactMarkdown>
    </Box>
  );
}
